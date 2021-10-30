#!/bin/python

# Generates sinusoidal tables

import sys
import os
import math

sin_output = bytearray()

for i in range(256):
    sin_output.append(int((math.sin(2 * math.pi / 255 * i) / 2 + 0.5) * 255))

# Write binary file
with open("./programs/data/sin.bin", "wb") as f:
    f.write(sin_output)

# Write header file
with open("./programs/data/sin.h", "w") as f:
    f.write(f"const unsigned char sin_table[{len(sin_output)}] = {{\n\t")
    for i in range(len(sin_output)):
        f.write(f"{sin_output[i]:#0{4}x},")
        if i % 16 == 15 and i < 255:
            f.write("\n\t")
    f.write("\n};\n")
