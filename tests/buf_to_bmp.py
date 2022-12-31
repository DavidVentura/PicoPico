import argparse
from PIL import Image, ImageDraw, ImageFile

class Dec(ImageFile.PyDecoder):
    def decode(self, buffer):
        _buf = []
        for i in range(0, len(buffer), 2):
            # 16bpp -> 24bpp
            in_byte1 = buffer[i]
            in_byte2 = buffer[i+1]
            byte1 = (in_byte1 & 0b11111000)
            byte2 = (((in_byte1 & 0b00000111) << 5) | ((in_byte2 & 0b11100000) >> 5))
            byte3 = ((in_byte2 & 0b00011111) << 3)
            _buf.extend([byte1, byte2, byte3])
        self.set_as_raw(bytes(_buf))
        return -1, 0
        

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--in-file', type=argparse.FileType('rb'), required=True)
    parser.add_argument('--out-file', type=argparse.FileType('wb'), required=True)
    parser.add_argument('--width', required=True, type=int)
    parser.add_argument('--height', required=True, type=int)
    return parser.parse_args()

def main():
    args = parse_args()
    Image.register_decoder("P8FBuffer", Dec)
    data = args.in_file.read()
    im = Image.frombytes("RGB", (args.width, args.height), data, decoder_name="P8FBuffer")
    im.save(args.out_file)

if __name__ == "__main__":
    main()
