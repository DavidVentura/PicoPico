import argparse
from PIL import Image, ImageFile
P8Palette = [
    (0, 0, 0),         ##	black
    (29, 43, 83),      ##	dark-blue
    (126, 37, 83),     ##	dark-purple
    (0, 135, 81),      ##	dark-green
    (171, 82, 54),     ##	brown
    (95, 87, 79),      ##	dark-grey
    (194, 195, 199),   ##	light-grey
    (255, 241, 232),   ##	white
    (255, 0, 77),      ##	red
    (255, 163, 0),     ##	orange
    (255, 236, 39),    ##	yellow
    (0, 228, 54),      ##	green
    (41, 173, 255),    ##	blue
    (131, 118, 156),   ##	lavender
    (255, 119, 168),   ##	pink
    (255, 204, 170),   ##	light-peach 
]

class P8PaletteDec(ImageFile.PyDecoder):
    def decode(self, buffer):
        _buf = []
        for b in buffer:
            _buf.extend(P8Palette[(b & 0x0f) >> 0])
            _buf.extend(P8Palette[(b & 0xf0) >> 4])
        self.set_as_raw(bytes(_buf))
        return -1, 0


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
    parser.add_argument('--palette', action='store_true')
    return parser.parse_args()

def main():
    args = parse_args()
    Image.register_decoder("P8FBuffer", Dec)
    Image.register_decoder("P8PaletteDec", P8PaletteDec)
    data = args.in_file.read()
    if args.palette:
        f = "P8PaletteDec"
    else:
        f = "P8FBuffer"
    im = Image.frombytes("RGB", (args.width, args.height), data, decoder_name=f)
    im = im.resize((args.width*4, args.height*4), resample=0)
    im.save(args.out_file)

if __name__ == "__main__":
    main()
