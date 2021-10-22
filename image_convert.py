#!/bin/python

# Converts images into lm-8 compatible binary formats

import sys
import os
from PIL import Image
import argparse

parser = argparse.ArgumentParser(description='Convert an image to a binary')
parser.add_argument('image', help='The image to convert')
parser.add_argument('-t', '--type', default='bg', choices=['sprite', 'bg'], type=str.lower, help="The type of image to convert")
args = parser.parse_args()

img = Image.open(args.image)

output = bytearray()

palette_img = Image.new('P', (16, 16))
palette_data = [  # https://lospec.com/palette-list/4-bit-rgb
    0, 0, 0,
    0, 85, 0,
    0, 170, 0,
    0, 255, 0,
    0, 0, 255,
    0, 85, 255,
    0, 170, 255,
    0, 255, 255,
    255, 0, 0,
    255, 85, 0,
    255, 170, 0,
    255, 255, 0,
    255, 0, 255,
    255, 85, 255,
    255, 170, 255,
    255, 255, 255,
]
palette_img.putpalette(palette_data * 16)
colorized = img.quantize(palette=palette_img)


# Convert a palette format image into tile bytes
def output_tile(image):
    pixels = image.load()
    buffer = []
    for y in range(image.size[1]):
        for x in range(image.size[0]):
            buffer.append(pixels[x, y])
    for i in range(int(len(buffer) / 2)):
        output.append(buffer[i * 2] << 4 | buffer[i * 2 + 1])


# Convert to binary format
if args.type == 'sprite':
    if img.size[0] != 16 or img.size[1] != 16:
        print("Image must be 16x16 pixels")
        exit(-1)

    output_tile(colorized.crop((0, 0, 8, 8)))  # Top left
    output_tile(colorized.crop((8, 0, 16, 8)))  # Top right
    output_tile(colorized.crop((0, 8, 8, 16)))  # Bottom left
    output_tile(colorized.crop((8, 8, 16, 16)))  # Bottom right
elif args.type == 'bg':
    if img.size[0] != 8 or img.size[1] != 8:
        print("Image must be 8x8 pixels")
        exit(-1)

    output_tile(colorized)

# Write binary file
with open(os.path.splitext(sys.argv[1])[0] + ".bin", "wb") as f:
    f.write(output)

# Write header file
with open(os.path.splitext(sys.argv[1])[0] + ".h", "w") as f:
    file_name = os.path.basename(sys.argv[1])
    f.write(f"// {file_name}\n\n")
    f.write(f"const char {os.path.splitext(file_name)[0]}[{len(output)}] = {{\n")
    for tile in range(int(len(output) / 32)):
        f.write("\t")
        for offset in range(32):
            f.write(f"{output[tile * 32 + offset]:#0{4}x},")
            if offset % 4 == 3 and offset < 31:
                f.write("\n\t")
        f.write("\n")
        if tile < int(len(output) / 32) - 1:
            f.write("\n")
    f.write("};\n")
