import enum
import os
import subprocess
import sys
import tempfile
import textwrap

from dataclasses import dataclass

from pathlib import Path

@dataclass
class GameCart:
    name: str
    code: bytes
    gfx: bytes
    gff: bytes
    label: bytes
    map: bytes
    sfx: bytes
    music: bytes

    def size(self) -> int:
        return len(self.code) + len(self.gfx) + len(self.gff) + len(self.label) + len(self.map) + len(self.sfx) + len(self.music)

class ProcessType(enum.Enum):
    COMPILE = enum.auto()
    RAW = enum.auto()

def chunked(lst, chunk_size: int):
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]

def compile_lua_to_bytecode(code: bytes) -> bytes:
    with tempfile.NamedTemporaryFile() as named:
        with subprocess.Popen(['./lua/luac', '-o', named.name, '-s', '-'], stdin=subprocess.PIPE) as p:
            p.communicate(code)
        if p.returncode != 0:
            raise ValueError("dead")
        named.flush()
        named.seek(0)
        return named.read()

def process_cart(name: str, data: bytes) -> GameCart:
    LUA_HEADER = b'__lua__'
    LABEL_HEADER = b"__label__"
    headers = [LUA_HEADER, b'__gfx__', b"__gff__", LABEL_HEADER, b"__map__", b"__sfx__", b"__music__"]

    sections = {}
    section = None
    for line in data.splitlines():
        if line in headers:
            section = line
            sections.setdefault(section, [])
            continue
        elif section is None:
            section = 'marker'
            sections.setdefault(section, [])
            continue
        sections[section].append(bytes(line))

    sections[LUA_HEADER] = compile_lua_to_bytecode(b'\n'.join(sections[LUA_HEADER]))

    gc = GameCart(name=name,
                  code=sections.get(LUA_HEADER, b''),
                  gfx=to_char_value(b''.join(sections.get(b'__gfx__', []))),
                  gff=hex_digits_to_bytes(b''.join(sections.get(b'__gff__', []))),
                  label=to_char_value(b''.join(sections.get(LABEL_HEADER, []))),
                  map=hex_digits_to_bytes(b''.join(sections.get(b'__map__', []))),
                  sfx=b''.join(sections.get(b'__sfx__', [])),
                  music=b'\n'.join(sections.get(b'__music__', []))
                  )
    return gc

def hex_digits_to_bytes(data: bytes) -> bytes:
    """
    0xa 0xf -> 0xaf ...
    """
    ret = []
    for i in range(0, len(data), 2):
        ret.append(_to_char(data[i]) << 4 | _to_char(data[i+1]))
    return bytes(ret)

def _to_char(c: int) -> int:
    if c >= 97:
        return c - 87 # 'a'-'f' -> 10-15
    elif c >= 48 and c <= 57:
        return c - 48 # '0'-9' -> 0-9
    raise ValueError(f"Can't convert {c}")

def to_char_value(data: bytes) -> bytes:
    """
    0-f -> 0-15
    """
    return bytes(map(_to_char, data))

def path_to_identifier(p: Path) -> str:
    pname = os.path.dirname(p).replace('.', '_').replace('-', '_')
    bname = os.path.basename(p).replace('.', '_').replace('-', '_')
    return f'{pname}_{bname}'

def _chunk(data: bytes, join: str='\n', brace_enclosed=True) -> str:
    assert data
    output = []

    if brace_enclosed:
        output.append('{')

    for chunk in chunked(data, 32):
        output.append('  ' + ', '.join([f'0x{b:02x}' for b in chunk]) + ',')

    if brace_enclosed:
        output.append('}')
    return join.join(output)

def _type(varname: str, uniq: str, data: bytes) -> str:
    if not data:
        return f'const uint8_t* {varname}_{uniq} = NULL'
    return f'const uint8_t {varname}_{uniq}[] = {_chunk(data)}'

def parse_cart(fname: Path, debug: bool=False):
    if not os.path.isfile(fname):
        print(f"'{fname}' does not exist or is not a file")
        sys.exit(1)

    bname = path_to_identifier(fname).replace('examples_', '')

    with open(fname, 'rb') as fd:
        data = fd.read()
    cart = process_cart(bname, data)
    output = textwrap.dedent(f'''
    {_type('code', bname, cart.code)};
    {_type('gfx', bname, cart.gfx)};
    {_type('gff', bname, cart.gff)};
    {_type('sfx', bname, cart.sfx)};
    {_type('map', bname, cart.map)};
    {_type('label', bname, cart.label)};
    const GameCart cart_{bname} = {{
        // name_len
        {len(cart.name)},
        "{cart.name}",
        // code_len
        {len(cart.code)},
        code_{bname},
        // gff_len
        {len(cart.gff)},
        gff_{bname},
        // gfx_len
        {len(cart.gfx)},
        gfx_{bname},
        // sfx_len
        {len(cart.sfx)},
        sfx_{bname},
        // map_len
        {len(cart.map)},
        map_{bname},
        // label_len
        {len(cart.label)},
        label_{bname},
    }};
    ''')
    return output

def parse(fname: Path, process_as: ProcessType, debug: bool=False):
    if not os.path.isfile(fname):
        print(f"'{fname}' does not exist or is not a file")
        sys.exit(1)

    bname = path_to_identifier(fname)

    with open(fname, 'rb') as fd:
        data = fd.read()

    output = []
    if process_as is ProcessType.RAW:
        # add a null byte, length is unknown
        data = to_char_value(b''.join(data.splitlines()))
        output.append(f'const uint16_t {bname}_len = {len(data)};')
    else:
        data = compile_lua_to_bytecode(data)

    initial_len = len(data)
    processed_data = data
    new_len = len(processed_data)

    output.append(f'const uint8_t {bname}[] = ')
    output.append(_chunk(processed_data, join='\n'))
    output.append(';')

    if process_as is ProcessType.COMPILE:
        output.append(f'const uint16_t {bname}_len = {len(data)};')
    if debug:
        print(f'[{bname}] {initial_len=} {new_len=}', file=sys.stderr)
    return '\n'.join(output)

def main():
    debug = True
    print(parse(Path('stdlib/stdlib.lua'), ProcessType.COMPILE, debug))
    print(parse(Path('artifacts/font.lua'), ProcessType.RAW, debug))
    print(parse(Path('artifacts/hud.p8'), ProcessType.RAW, debug))

    games = []
    for f in Path('examples/').glob('*'):
        games.append(path_to_identifier(f))
        print(parse_cart(f, debug))

    print('GameCart carts[] = {')
    for game in games:
        game_name = game.replace('examples_', '')
        print(f'cart_{game_name},')
    print('};')

if __name__ == '__main__':
    main()
