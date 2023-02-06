import sexpdata
import re

from pathlib import Path
from kconfiglib import Kconfig, Symbol

THIS_DIR = Path(__file__).parent.resolve()

SCHEM_TO_KCONFIG = {
    "UNDEF":    "UNDEF",
    "SW_T":     "UP",
    "SW_L":     "LEFT",
    "SW_R":     "RIGHT",
    "SW_U":     "UP",
    "SW_BOT":   "DOWN",
    "SW_A":     "A",
    "SW_B":     "B",
    "SW_START": "START",
    "SW_SEL":   "SELECT",
    "LED/BL":   "BL",
    "DIN":      "AUDIO_DATA_OUT",
    "CS":       "CS",
    "DC/RS":    "DC",
    "RESET":    "RESET",
    "SDA":      "MOSI",
    "SCK":      "SCLK",
    "LRC":      "AUDIO_WS",
    "BCLK":     "AUDIO_BCLK",
}

PIN_MAPPING = {
    1:  "3v3",
    2:  "RST",
    3:  "VP",
    4:  "VN",
    5:  "34",
    6:  "35",
    7:  "32",
    8:  "33",
    9:  "25",
    10: "26",
    11: "27",
    12: "14",
    13: "12",
    14: "13",
    15: "GND",
    16: "VBAT",
    17: "GND",
    18: "3v3",
    19: "VIN",
    20: "5V",
    21: "GND",
    22: "15",
    23: "2",
    24: "0",
    25: "4",
    26: "5",
    27: "18",
    28: "19",
    29: "21",
    30: "RX",
    31: "TX",
    32: "22",
    33: "23",
    34: "GND",
}

PIN_NAME_TO_NUMBER = {v: k for k, v in PIN_MAPPING.items()}


def main():
    from_schem = parse_netlist(THIS_DIR / "./picopico.orcad.net")
    from_kconfig = parse_kconfig(THIS_DIR / "../../esp/Kconfig.projbuild")
    bad = print_comparison_table(from_kconfig, from_schem)
    if bad:
        exit(1)

def remove_orcad_netlist_crap(data: str) -> str:
    ret = []
    for line in data.splitlines():
        line = line.strip()
        if 'EESchema' in line:
            # ( { EESchema Netlist Version 1.1 created  ma 06 feb 2023 12:04:30 CET }
            # ->
            # (
            line = re.sub('{ EESchema Netlist.*?}', '', line)
        if line == '*':
            # last line is '*'
            continue
        ret.append(line)
    return '\n'.join(ret)

def parse_netlist(p: Path):
    from_schem = {}

    with p.open() as f:
        raw_data = f.read()

    processed_data = remove_orcad_netlist_crap(raw_data)
    data = sexpdata.loads(processed_data)

    for item in data:
        is_next = False
        if isinstance(item, list):
            for i in item:
                if isinstance(i, sexpdata.Symbol) and i.value() == "DollaTekESP32":
                    is_next = True
                    continue
                if is_next:
                    assert isinstance(i, list)
                    if len(i) == 2:
                        pin, sym = i
                        from_schem[pin] = sym.value()

    return from_schem


def parse_kconfig(p: Path):
    kconf = Kconfig(str(p))
    result = {}
    parse_kconf(kconf.top_node, result)
    return result


def parse_kconf(node, kconfig):
    """
    returns Pin NAME -> Kconfig symbol
    """
    while node:
        if isinstance(node.item, Symbol):
            if 'GPIO' in node.item.name:
                name = node.item.name.replace('_GPIO', '').replace('GPIO_', '')
                pin_num = PIN_NAME_TO_NUMBER[node.item.str_value] # name here may be "0" which maps to the pin#24
                kconfig[pin_num] = name

        if node.list:
            parse_kconf(node.list, kconfig)

        node = node.next



def print_comparison_table(from_kconfig, from_schem):
    bad = False
    print(f'{"GPIO":10}\t{"kconfig":15}\t{"schem":10}\tmatching')

    for k, gpio_name in PIN_MAPPING.items():
        kc = from_kconfig.get(k, "UNDEF")
        schem = from_schem.get(k, "UNDEF").replace('/', '').replace('{slash}', '/')
        matching = kc == SCHEM_TO_KCONFIG.get(schem, schem)
        name_col = f'{k:02d} ({gpio_name})'

        if gpio_name == "3v3" and schem in ("+3V3", "+3.3V") and kc == "UNDEF":
            continue
        if gpio_name == "GND" and schem == "GND" and kc == "UNDEF":
            continue

        if not matching:
            bad = True
            print(f'{name_col:10}\t{kc:15}\t{schem:10}\t{matching}')

    return bad

main()
