#!/bin/python

# Generates sinusoidal tables

import math


def generate_header(output, file):
    with open(file, 'w') as f:
        f.write(f"const unsigned char sin_table[{len(output)}] = {{\n\t")
        for j in range(len(output)):
            f.write(f"{output[j]:#0{4}x},")
            if j % 16 == 15 and j < 255:
                f.write("\n\t")
        f.write("\n};\n")


def main():
    sin_output = bytearray()
    cos_output = bytearray()

    for i in range(256):
        sin_output.append(int((math.sin(2 * math.pi / 255 * i) / 2 + 0.5) * 255))
        cos_output.append(int((math.cos(2 * math.pi / 255 * i) / 2 + 0.5) * 255))

    # Write binary file
    with open("./programs/data/sin.bin", "wb") as f:
        f.write(sin_output)
    with open("./programs/data/cos.bin", "wb") as f:
        f.write(cos_output)

    generate_header(sin_output, './programs/data/sin.h')
    generate_header(cos_output, './programs/data/cos.h')


if __name__ == '__main__':
    main()
