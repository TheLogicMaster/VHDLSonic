#!/bin/python

# Converts images into OLED data binary formats

import glob
import os
import shutil
import subprocess

from PIL import Image
import argparse

parser = argparse.ArgumentParser(description='Convert an image to a tile data binary')
parser.add_argument('images', nargs='+', help='The images to convert')
parser.add_argument('-t', '--type', choices=['gif', 'images'], default='gif', help='The type of images to convert')
parser.add_argument('-c', '--compress', action='store_true', help='Whether to compress the output or not')
parser.add_argument('-o', '--output', help='The output filename')
parser.add_argument('-b', '--black', type=int, default=0, help='The black color threshold')
parser.add_argument('--coalesce', action='store_true', help='Enable the ImageMagik coalesce option')
args = parser.parse_args()

output = bytearray()

if args.type == 'gif':
    os.makedirs("./temp", exist_ok=True)
    convert_args = ['convert', args.images[0], '-resize', '128x64', '-background', 'black', '-gravity', 'center', '-extent', '128x64']
    if args.coalesce:
        convert_args.append('-coalesce')
    convert_args.append('./temp/out.png')
    subprocess.run(convert_args, check=True)
    images = glob.iglob('./temp/*.png')
else:
    images = args.images

for image_path in images:
    img = Image.open(image_path)

    if img.size[0] != 128 or img.size[1] != 64:
        print("Image must be 128x64 pixels")
        exit(-1)

    pixels = img.convert('L').load()
    if args.compress:
        count = 0
        current = False
        for page in range(8):
            for x in range(128):
                for i in range(8):
                    new = pixels[x, page * 8 + i] > args.black
                    if new != current or count >= 127:
                        if count > 0:
                            output.append(int(current) << 7 | count)
                        count = 1
                        current = new
                    else:
                        count += 1
        output.append(int(current) << 7 | count)
    else:
        for page in range(8):
            for x in range(128):
                column = 0
                for i in range(8):
                    if pixels[x, page * 8 + i] > 0:
                        column |= 1 << i
                output.append(column)
    output.append(0)  # Frame end NULL byte
output.append(0)  # Animation end NULL byte

if args.type == 'gif':
    shutil.rmtree('./temp', True)

out_name = args.output if args.output else os.path.splitext(args.images[0])[0] + ".bin"
with open(out_name, "wb") as f:
    f.write(output)
