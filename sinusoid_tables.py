#!/bin/python

# Generates sinusoidal tables

from header_generator import generate_header

import math


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

    generate_header(sin_output, open('./programs/data/sin.h', 'w'), 'SIN_TABLE')
    generate_header(cos_output, open('./programs/data/cos.h', 'w'), 'COS_TABLE')


if __name__ == '__main__':
    main()
