#!/bin/python

# Converts images into tile data binary formats

import sys
import os
from PIL import Image
import argparse

parser = argparse.ArgumentParser(description='Convert an image to a tile data binary')
parser.add_argument('image', help='The image to convert')
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
colorized = img.convert('RGB').quantize(palette=palette_img, dither=0)


# Convert a palette format image into tile bytes
def output_tile(image):
    pixels = image.load()
    buffer = []
    for y in range(image.size[1]):
        for x in range(image.size[0]):
            buffer.append(pixels[x, y])
    for k in range(int(len(buffer) / 2)):
        output.append(buffer[k * 2] << 4 | buffer[k * 2 + 1])


if not img.size[0] or not img.size[1] or img.size[0] % 8 or img.size[1] % 8:
    print("Image must be a multiple of 8x8 pixels")
    exit(-1)

for i in range(int(img.size[1] / 8)):
    for j in range(int(img.size[0] / 8)):
        output_tile(colorized.crop((j * 8, i * 8, j * 8 + 8, i * 8 + 8)))

# Write binary file
with open(os.path.splitext(sys.argv[1])[0] + ".bin", "wb") as f:
    f.write(output)

# Write header file
with open(os.path.splitext(sys.argv[1])[0] + ".h", "w") as f:
    file_name = os.path.basename(sys.argv[1])
    f.write(f"// {file_name}\n\n")
    f.write(f"const int {os.path.splitext(file_name)[0].upper()}[{int(len(output) / 4)}] = {{\n")
    for tile in range(int(len(output) / 32)):
        f.write("\t")
        for row in range(8):
            f.write("0x")
            for byte in range(4):
                f.write(f"{format(output[tile * 32 + row * 4 + byte], '02x')}")
            f.write(", ")
        f.write("\n")
    f.write("};\n")
