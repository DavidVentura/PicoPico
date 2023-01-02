import sexpdata

from pathlib import Path
from kconfiglib import Kconfig, Symbol

SCHEM_TO_KCONFIG = {
    "UNDEF":    "UNDEF",
    "SW_T":     "TOP",
    "SW_L":     "LEFT",
    "SW_R":     "RIGHT",
    "SW_U":     "UP",
    "SW_BOT":   "DOWN",
    "SW_A":     "A",
    "SW_B":     "B",
    "SW_START": "START",
    "SW_SEL":   "SEL",
    "LED/BL":   "BL",
    "DIN":      "AUDIO_DATA_OUT",
    "CS":       "CS",
    "DC/RS":    "DC",
    "RESET":    "RESET",
    "SDA":      "SDA",
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
    18: "3.3v",
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


def main():
    from_schem = parse_netlist(Path("./picopico.orcad.net"))
    from_kconfig = parse_kconfig(Path("../../esp/Kconfig.projbuild"))
    bad = print_comparison_table(from_kconfig, from_schem)
    if bad:
        exit(1)

def parse_netlist(p: Path):
    from_schem = {}

    with p.open() as f:
        data = sexpdata.loads(f.read())

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
                        pin_name = PIN_MAPPING[pin]
                        from_schem[pin_name] = sym.value()
    return from_schem


def parse_kconfig(p: Path):
    kconf = Kconfig(str(p))
    result = {}
    parse_kconf(kconf.top_node, result)
    return result


def parse_kconf(node, kconfig):
    while node:
        if isinstance(node.item, Symbol):
            if 'GPIO' in node.item.name:
                name = node.item.name.replace('_GPIO', '').replace('GPIO_', '')
                kconfig[node.item.str_value] = name

        if node.list:
            parse_kconf(node.list, kconfig)

        node = node.next



def print_comparison_table(from_kconfig, from_schem):
    bad = False
    print(f'GPIO\t{"kconfig":15}\t{"schem":10}\tmatching')

    for k in PIN_MAPPING.keys():
        kc = from_kconfig.get(str(k), "UNDEF")
        schem = from_schem.get(str(k), "UNDEF").replace('/', '').replace('{slash}', '/')
        matching = kc == SCHEM_TO_KCONFIG[schem]
        if not matching:
            bad = True
        print(f'{k:02d}\t{kc:15}\t{schem:10}\t{matching}')

    return bad

main()
