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

    return GameCart(name=name,
                    code=sections.get(LUA_HEADER, b''),
                    gfx=b''.join(sections.get(b'__gfx__', [])),
                    gff=b''.join(sections.get(b'__gff__', [])),
                    label=to_char_value(b''.join(sections.get(LABEL_HEADER, []))),
                    map=b''.join(sections.get(b'__map__', [])),
                    sfx=b''.join(sections.get(b'__sfx__', [])),
                    music=b'\n'.join(sections.get(b'__music__', []))
                    )

def to_char_value(data: bytes) -> bytes:
    """
    0-f -> 0-15
    """
    ret = []
    for b in data:
        n = 0xAA
        if b >= 97: # a-f
            n = b - 87 # -> 10-15
        elif b >= 48 and b <= 57: # 0-9
            n = b - 48
        ret.append(n)
    return bytes(ret)

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

    if process_as is ProcessType.RAW:
        # add a null byte, length is unknown
        data += b'\0'
    else:
        data = compile_lua_to_bytecode(data)

    initial_len = len(data)
    processed_data = data
    new_len = len(processed_data)

    output = []
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
