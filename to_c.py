import os
import sys
import enum
import glob

from pathlib import Path

class ProcessType(enum.Enum):
    SKIP = enum.auto()
    CART = enum.auto()
    RAW = enum.auto()

def chunked(lst, chunk_size: int):
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]

def rle_decompression(data: bytes):
    out = []
    idx = 0
    while idx < len(data):
        c = data[idx] & 0x7F
        mult = (data[idx] & 0x80) == 0x80
        if mult:
            count = data[idx+1] + 1
            idx += 1
        else:
            count = 1
        idx += 1
        out.extend([c] * count)
    return out

def rle_compression(data: bytes):
    assert len(data)
    acc = []
    cur = []
    last = data[0]
    for b in data:
        assert b < 128  # using highest bit to indicate repetitions
        # can do only up to 255 repetitions per group (1 byte for count)
        if b == last and len(cur) < 256:
            cur.append(b)
        else:
            acc.append(cur)
            last = b
            cur = [b]

    if cur:
        acc.append(cur)
    ret = b''
    for r in acc:
        count = len(r)
        char = r[0]
        if count > 1:  # highest bit set = repeated
            char = char | 0x80
            ret += bytes([char, count-1])
        else:
            ret += bytes([char])

    data = list(data)
    dec = rle_decompression(ret)
    assert data == dec
    return ret

def process_cart(data: bytes, strip_label: bool=False):
    LUA_HEADER = b'__lua__'
    LABEL_HEADER = b"__label__"
    processing_code = False
    processing_label = False
    found_header_yet = False
    headers = [LUA_HEADER, b'__gfx__', b"__gff__", LABEL_HEADER, b"__map__", b"__sfx__", b"__music__"]

    compressed = b''
    for line in data.splitlines():
        if line in headers:
            found_header_yet = True
            processing_code = line == LUA_HEADER
            processing_label = line == LABEL_HEADER
            if processing_label and strip_label:
                continue
            compressed += line + b'\n'
            continue

        if processing_code:
            compressed += line + b'\n'
            continue

        if processing_label and strip_label:
            continue

        if not found_header_yet:
            compressed += line + b'\n'
            continue

        if not line:
            continue

        encoded = rle_compression(line)
        assert list(line) == rle_decompression(encoded)
        compressed += encoded + b'\n'

    return compressed

def parse(fname: Path, process_as: ProcessType, strip_label: bool, debug: bool=False):
    if not os.path.isfile(fname):
        print(f"'{fname}' does not exist or is not a file")
        sys.exit(1)
    pname = os.path.dirname(fname).replace('.', '_').replace('-', '_')
    bname = os.path.basename(fname).replace('.', '_').replace('-', '_')
    bname = f'{pname}_{bname}'

    with open(fname, 'rb') as fd:
        data = fd.read()

    # add a null byte
    data += b'\0'

    initial_len = len(data)

    if process_as is ProcessType.RAW:
        processed_data = rle_compression(data)
    elif process_as is ProcessType.CART:
        processed_data = process_cart(data, strip_label)
    else:
        processed_data = data

    new_len = len(processed_data)

    output = []
    output.append(f'uint8_t {bname}[] = {{')
    for chunk in chunked(processed_data, 16):
        output.append('  ' + ', '.join([f'0x{b:02x}' for b in chunk]) + ',')
    output.append('};')

    if debug:
        print(f'[{bname}] {initial_len=} {new_len=}', file=sys.stderr)

    return '\n'.join(output)

def main():
    debug = True
    print(parse('stdlib/stdlib.lua', ProcessType.SKIP, False, debug))
    print(parse('artifacts/font.lua', ProcessType.RAW, False, debug))
    for f in glob.glob('examples/*'):
        print(parse(f, ProcessType.CART, True, debug))

if __name__ == '__main__':
    main()
