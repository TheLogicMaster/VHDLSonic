#!/bin/python3

# This script takes a ROM binary and outputs an Intel Memory Initialization Format file

import sys


def main():
    if len(sys.argv) != 3:
        print('Usage: python3 rom_to_vhdl_switch.py <binary_file> <output_file>')
        exit(-1)

    f = open(sys.argv[1], 'rb')
    binary = f.read()
    f.close()

    f = open(sys.argv[2], 'w')
    f.writelines([
        f"DEPTH = {int(0x18000 / 4)};\n",
        "WIDTH = 32;\n",
        "ADDRESS_RADIX = DEC;\n",
        "DATA_RADIX = HEX;\n"
        "CONTENT\n",
        "BEGIN\n"
    ])
    for i in range(int(len(binary) / 4)):
        f.write(f'{i} : {format(binary[i * 4], "02x")}{format(binary[i * 4 + 1], "02x")}{format(binary[i * 4 + 2], "02x")}{format(binary[i * 4 + 3], "02x")};\n')
    f.write("END\n")
    f.close()


if __name__ == '__main__':
    main()
