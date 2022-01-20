#!/bin/python

# Generates C header files from binary data

import argparse
import os


def generate_header(data, file, name):
    """
    Generate C header file for data and write to file
    :param data: Data to insert
    :param file: File to write header to
    :param name: Name of C data field
    """
    file.write(f"const unsigned char {name}[{len(data)}] = {{\n\t")
    for j in range(len(data)):
        file.write(f"{data[j]:#0{4}x},")
        if j % 16 == 15 and j < len(data) - 1:
            file.write("\n\t")
    file.write("\n};\n")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert an image to a tile data binary')
    parser.add_argument('input', help='The input binary file')
    parser.add_argument('-o', '--output', required=False, help='The output header file')
    parser.add_argument('-n', '--name', required=False, help='The C header field name')
    args = parser.parse_args()

    with open(args.input, 'rb') as input_file:
        binary_name = os.path.basename(args.input)
        c_name = args.name if args.name else os.path.splitext(binary_name)[0].upper().replace(' ', '_')
        output_file = open(args.output if args.output else args.input + '.h', 'w')
        generate_header(input_file.read(), output_file, c_name)
