import os
import sys

def chunked(lst, chunk_size):
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]

for fname in sys.argv[1:]:
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

    print(f'char {bname}[] = {{')
    for chunk in chunked(data, 16):
        print('  ' + ', '.join([f'0x{b:02x}' for b in chunk]), end=',\n')
    print('};')
