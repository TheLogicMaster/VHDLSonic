#!/bin/python3

# This script will assemble a program into the build folder

import argparse
import os
import re
import shutil
import subprocess
import shlex

constants = {}
line_number = 0
file = ""
output = bytearray()
address = 0
data_address = 0x10000
includes = []
labels = {}
last_label = None
last_data_label = None
label_addresses = {}
label_jumps = {}
data_section = False


# Print error and current line number before exiting
def error(cause, line=None):
    print("Error: " + cause)
    if line is None or line >= 0:
        print(f"{file}: Line {line_number if line is None else line}")
    exit(-1)


# Error if the wrong number of parameters was provided
def ensure_params(params, num):
    if len(params) != num:
        error("Wrong number of parameters")


# Increase the size of the output array if less than the requested size
def ensure_output_size(size):
    while len(output) < size:
        output.append(0)


# Ensures the current address is aligned correctly
def ensure_alignment(align):
    global address
    label = last_data_label if data_section else last_label
    while address % align:
        if label is not None and labels[label] == address:
            labels[label] = address + 1
        address = address + 1


# Writes a word into the output at the specified location
def write_word_in_output(location, value):
    ensure_output_size(location + 4)
    output[location] = value >> 24
    output[location + 1] = (value >> 16) & 0xFF
    output[location + 2] = (value >> 8) & 0xFF
    output[location + 3] = value & 0xFF


# Append a single byte to the output from an integer value
def output_byte(value):
    global address
    if value > 0xFF:
        error("Byte too large")
    ensure_output_size(address + 1)
    output[address] = value
    address += 1


# Append a half-word to the output from an integer value
def output_half_word(value):
    global address
    if value > 0xFFFF:
        error("Half-word too large")
    ensure_output_size(address + 2)
    value = value & 0xFFFF
    output[address] = value >> 8
    address += 1
    output[address] = value & 0xFF
    address += 1


# Append a word to the output from an integer value
def output_word(value):
    global address
    if value > 0xFFFFFFFF:
        error("Word too large")
    value = value & 0xFFFFFFFF
    write_word_in_output(address, value)
    address += 4


# Parse a parameter as an unsigned constant or None if not valid
def parse_constant(param):
    match = re.search(r"^'(.+)'$", param)
    if match:
        char = match[1].encode().decode("unicode-escape").encode()
        if len(char) != 1:
            error("Invalid char")
        return char[0]
    try:
        if param.startswith("%"):
            value = int(param[1:], 2)
        elif param.startswith("$"):
            value = int(param[1:], 16)
        else:
            value = int(param[1:] if param.startswith("#") else param)
        if value > 0xFFFFFFFF or value < -2147483648:
            error("Constant out of valid range")
        return value & 0xFFFFFFFF
    except ValueError:
        return None


# Parses a register from a parameter or None if not valid
def parse_register(param):
    match = re.search(r"^r[0-9]+$", param)
    if match:
        value = int(match[0][1:])
        return None if value > 15 else value
    elif param == "x":
        return 12
    elif param == "y":
        return 13
    elif param == "fp":
        return 14
    elif param == "sp":
        return 15
    else:
        return None


# Parses an indexed register from a parameter or None if not valid
def parse_indexed_register(param):
    reg = parse_register(re.sub("[-+]", "", param))
    if reg is None:
        return None
    return reg, param.endswith("+") or param.endswith("-"), "+" in param, "-" in param


# Parse a label from a parameter or None if not valid
def parse_label(param):
    match = re.search(r"^(\w+)$", param)
    if not match:
        return None
    return match[1]


# Parse either a label or an immediate address and append it to the output, error on failure
def output_location(param):
    global address
    param = re.sub("[\\[\\]]", "", param)
    const = parse_constant(param)
    if const is not None:
        output_word(const)
        return
    match = re.search(r"^(\w+)$", param)
    if match:
        label_addresses[address] = match[1]
        address += 4
        return
    error("Invalid location")


# Output an the register byte of an instruction
def output_registers(source=0, operand=0, pre_post=False, inc=False, dec=False):
    output_byte(source << 4 | operand)
    output_half_word(pre_post << 15 | inc << 14 | dec << 13)


# Output an implicit instruction
def output_implicit_instr(params, opcode):
    ensure_params(params, 0)
    ensure_alignment(4)
    output_byte(opcode)
    output_registers()


# Output a load or store instruction
# Size is 0 for 8-bits, 1 for 16-bits, and 2 for 32-bits
# Store for if it's a store instruction
def output_load_store_instr(params, size, store=False):
    global address
    if len(params) < 2:
        error("Not enough parameters")
    ensure_alignment(4)
    reg = parse_register(params[0])
    if reg is None:
        error("Invalid register")
    if len(params) == 2:
        const = parse_constant(params[1])
        if const is not None and not store:
            output_byte(0x10 + size)
            output_registers(reg)
            output_word(const)
            return
        label = parse_label(params[1])
        if label is not None and not store:
            if size != 2:
                error("Must use LDR for addresses")
            output_byte(0x12)
            output_registers(reg)
            label_addresses[address] = label
            address += 4
            return
        index = parse_indexed_register(params[1])
        if index is not None:
            output_byte((0x1F if store else 0x16) + size)
            output_registers(reg, index[0], index[1], index[2], index[3])
            return
        output_byte((0x1C if store else 0x13) + size)
        output_registers(reg)
        output_location(params[1])
    elif len(params) == 3:
        rel = parse_register(params[1])
        offset = parse_constant(params[2])
        if rel is None or offset is None:
            error("Invalid relative load parameters")
        output_byte((0x22 if store else 0x19) + size)
        output_registers(reg, rel)
        output_word(offset)
    else:
        error("Wrong number of parameters")


# Output an arithmetic instruction
# base_opcode is for the immediate variant
def output_arithmetic_instr(params, base_opcode):
    ensure_params(params, 2)
    ensure_alignment(4)
    source = parse_register(params[0])
    if source is None:
        error("Invalid source register")
    const = parse_constant(params[1])
    if const is not None:
        output_byte(base_opcode)
        output_registers(source)
        output_word(const)
        return
    operand = parse_register(params[1])
    if operand is None:
        error("Invalid operand")
    output_byte(base_opcode + 1)
    output_registers(source, operand)


# Output a single register operand instruction
def output_register_instr(params, opcode):
    ensure_params(params, 1)
    ensure_alignment(4)
    reg = parse_register(params[0])
    if reg is None:
        error("Invalid register")
    output_byte(opcode)
    output_registers(reg)


# Output a branch instruction
def output_branch_instr(params, opcode):
    global address
    ensure_params(params, 1)
    ensure_alignment(4)
    const = parse_constant(params[0])
    output_byte(opcode)
    output_registers()
    if const is not None:
        output_word(const)
        return
    label = parse_label(params[0])
    if label is None:
        error("Invalid branch operand")
    label_jumps[address] = label
    address += 4


def parse_file():
    global line_number
    global address
    global data_address
    global file
    global constants
    global last_label
    global last_data_label
    global data_section

    data_section = False

    f = open(file)
    lines = f.readlines()
    f.close()

    for line in lines:
        line_number += 1

        # Todo: Fix splitting to avoid marking semicolons in strings as comments

        # Remove comments
        line = line.split(";")[0]

        # Get label
        match = re.search(r"^\s*(\w+):", line.lower())
        if match:
            if match[1] in labels:
                error("Duplicate label: " + match[1])
            labels[match[1]] = data_address if data_section else address
            if data_section:
                last_data_label = match[1]
            else:
                last_label = match[1]
            line = line[len(match[0]):]

        # Get instruction
        match = re.search(r"^\s*(\w+)", line.lower())
        if not match:
            continue
        instr = match[1]
        line = line[len(match[0]):]

        # Get parameters
        # Magic splitting regex: https://stackoverflow.com/a/64333329
        params = re.split(r",(?=(?:[^\"']*[\"'][^\"']*[\"'])*[^\"']*$)", line)
        if re.sub(r"\s+", "", params[0]) == "":
            params = []

        # Make everything except strings lowercase, remove surrounding whitespace, and substitute constants
        for i in range(len(params)):
            if "\"" not in params[i] and "'" not in params[i]:
                params[i] = params[i].lower()
                for constant in constants:
                    params[i] = params[i].replace("{" + constant + "}", ("" if type(constants[constant]) is str else "#") + str(constants[constant]))
            params[i] = re.sub(r"^\s+|\s+$", "", params[i])

        if data_section and instr != "var" and instr != "org" and instr != "rodata" and instr != "align":
            error("Only VAR, ORG, ALIGN, and RODATA are permitted in the data section")

        if instr == "org":
            ensure_params(params, 1)
            parsed = parse_constant(params[0])
            if parsed is None:
                error("Failed to parse origin address")
            if data_section:
                if parsed < 0x10000:
                    error("Only addresses at or above 0x10000 are allowed in the data section")
                data_address = parsed
            else:
                address = parsed

        elif instr == "align":
            ensure_params(params, 1)
            parsed = parse_constant(params[0])
            if parsed is None:
                error("Failed to parse alignment")
            ensure_alignment(parsed)

        elif instr == "def":
            ensure_params(params, 1)
            match = re.search(r"^(\w+)=(.+)$", params[0])
            if not match:
                error("Invalid definition")
            constants[match[1]] = match[2]

        elif instr == "include":
            current_line = line_number
            current_file = file
            current_section = data_section
            ensure_params(params, 1)
            match = re.search(r"^\"(.+)\"$", params[0])
            if not match:
                error("Invalid include file")
            file_path = os.path.join(os.path.dirname(file), match[1])
            if file_path in includes:
                continue
            includes.append(file_path)
            file = file_path
            try:
                parse_file()
            except RecursionError:
                error("Recursive dependencies")
            data_section = current_section
            file = current_file
            line_number = current_line

        elif instr == "data":
            ensure_params(params, 0)
            data_section = True

        elif instr == "rodata":
            ensure_params(params, 0)
            data_section = False

        elif instr == "var":
            if not data_section:
                error("The VAR instruction can only be used in the data section")
            if len(params) == 0:
                data_address += 1
            elif len(params) == 1:
                match = re.search(r"^\[([0-9]+)]$", params[0])
                if not match:
                    error("Invalid var array")
                data_address += int(match[1])
            else:
                error("Invalid parameters")

        elif instr == "db" or instr == "dw" or instr == "dd":
            if len(params) == 0:
                error("Parameters are required")
            for param in params:
                const = parse_constant(param)
                if const is not None:
                    if instr == "db":
                        output_byte(const)
                    elif instr == "dw":
                        output_half_word(const)
                    else:
                        output_word(const)
                elif param.startswith("\"") and instr == "db":
                    for byte in param[1:-1].encode().decode("unicode-escape").encode():
                        output_byte(byte)
                else:
                    error("Invalid byte data")

        elif instr == "bin":
            ensure_params(params, 1)
            match = re.search(r"^\"(.+)\"$", params[0])
            if not match:
                error("Invalid binary file")
            with open(os.path.join(os.path.dirname(file), match[1]), "rb") as f:
                while byte := f.read(1):
                    output_byte(ord(byte))

        elif instr == "nop":
            output_implicit_instr(params, 0x00)

        elif instr == "beq":
            output_branch_instr(params, 0x01)

        elif instr == "bne":
            output_branch_instr(params, 0x02)

        elif instr == "bhs":
            output_branch_instr(params, 0x03)

        elif instr == "blo":
            output_branch_instr(params, 0x04)

        elif instr == "bmi":
            output_branch_instr(params, 0x05)

        elif instr == "bpl":
            output_branch_instr(params, 0x06)

        elif instr == "bvs":
            output_branch_instr(params, 0x07)

        elif instr == "bvc":
            output_branch_instr(params, 0x08)

        elif instr == "bhi":
            output_branch_instr(params, 0x09)

        elif instr == "bls":
            output_branch_instr(params, 0x0A)

        elif instr == "bge":
            output_branch_instr(params, 0x0B)

        elif instr == "blt":
            output_branch_instr(params, 0x0C)

        elif instr == "bgt":
            output_branch_instr(params, 0x0D)

        elif instr == "ble":
            output_branch_instr(params, 0x0E)

        elif instr == "bra":
            output_branch_instr(params, 0x0F)

        elif instr == "ldb":
            output_load_store_instr(params, 0, False)

        elif instr == "ldw":
            output_load_store_instr(params, 1, False)

        elif instr == "ldr":
            output_load_store_instr(params, 2, False)

        elif instr == "stb":
            output_load_store_instr(params, 0, True)

        elif instr == "stw":
            output_load_store_instr(params, 1, True)

        elif instr == "str":
            output_load_store_instr(params, 2, True)

        elif instr == "tfr":
            ensure_params(params, 2)
            ensure_alignment(4)
            reg1 = parse_register(params[0])
            reg2 = parse_register(params[1])
            if reg1 is None or reg2 is None:
                error("Invalid operands")
            output_byte(0x25)
            output_registers(reg1, reg2)

        elif instr == "mul":
            output_arithmetic_instr(params, 0x26)

        elif instr == "add":
            output_arithmetic_instr(params, 0x28)

        elif instr == "adc":
            output_arithmetic_instr(params, 0x2A)

        elif instr == "sub":
            output_arithmetic_instr(params, 0x2C)

        elif instr == "sbc":
            output_arithmetic_instr(params, 0x2E)

        elif instr == "and":
            output_arithmetic_instr(params, 0x30)

        elif instr == "or":
            output_arithmetic_instr(params, 0x32)

        elif instr == "xor":
            output_arithmetic_instr(params, 0x34)

        elif instr == "lsl":
            output_arithmetic_instr(params, 0x36)

        elif instr == "lsr":
            output_arithmetic_instr(params, 0x38)

        elif instr == "asr":
            output_arithmetic_instr(params, 0x3A)

        elif instr == "cmp":
            output_arithmetic_instr(params, 0x3C)

        elif instr == "inc":
            output_register_instr(params, 0x3E)

        elif instr == "dec":
            output_register_instr(params, 0x3F)

        elif instr == "sei":
            output_implicit_instr(params, 0x40)

        elif instr == "cli":
            output_implicit_instr(params, 0x41)

        elif instr == "sec":
            output_implicit_instr(params, 0x42)

        elif instr == "clc":
            output_implicit_instr(params, 0x43)

        elif instr == "push":
            output_register_instr(params, 0x44)

        elif instr == "pop":
            output_register_instr(params, 0x45)

        elif instr == "jmp":
            ensure_params(params, 1)
            ensure_alignment(4)
            const = parse_constant(params[0])
            if const is not None:
                output_byte(0x46)
                output_registers()
                output_word(const)
                continue
            reg = parse_register(params[0])
            if reg is not None:
                output_byte(0x47)
                output_registers(reg)
                continue
            label = parse_label(params[0])
            if label is None:
                error("Invalid jump operand")
            output_byte(0x46)
            output_registers()
            label_addresses[address] = label
            address += 4

        elif instr == "jsr":
            ensure_params(params, 1)
            ensure_alignment(4)
            const = parse_constant(params[0])
            output_byte(0x48)
            output_registers()
            if const is not None:
                output_word(const)
                continue
            label = parse_label(params[0])
            if label is None:
                error("Invalid operand")
            label_addresses[address] = label
            address += 4

        elif instr == "ret":
            output_implicit_instr(params, 0x49)

        elif instr == "int":
            ensure_params(params, 1)
            ensure_alignment(4)
            const = parse_constant(params[0])
            if const is None:
                error("Invalid constant")
            output_byte(0x4A)
            output_registers()
            output_word(const)

        elif instr == "rti":
            output_implicit_instr(params, 0x4B)

        elif instr == "halt":
            output_implicit_instr(params, 0x4C)

        else:
            error("Unknown instruction: " + instr)


def main():
    global file

    parser = argparse.ArgumentParser(description='Assemble a program. Assumed to be in the <project>/programs directory by default')
    parser.add_argument('program', help='The program file to assemble')
    parser.add_argument('-t', '--type', default='assembly', choices=['assembly', 'c'])
    parser.add_argument('-r', '--run', action='store_true', help="Whether to run the emulator after assembly")
    parser.add_argument('-f', '--fpga', default='none', choices=['none', 'patch', 'flash'], type=str.lower, help="Whether to patch or run for FPGA (Linux only)")
    parser.add_argument('-e', '--emulator', help='The path to the emulator if not "../emulator/build/Emulator"')
    parser.add_argument('-c', '--compiler', help='The path to the compiler if not "../vbcc/bin/vbccsonic"')
    parser.add_argument('-m', '--memory', action='store_true', help='Assemble for being run by bootloader')
    args = parser.parse_args()

    memory = args.memory
    file = args.program

    os.makedirs("./build", exist_ok=True)

    # Compile C program if needed
    if args.type == 'c':
        copied = os.path.join("./build", os.path.basename(file))
        shutil.copyfile(file, copied)
        shutil.rmtree('./build/libraries', True)
        shutil.copytree('./libraries', './build/libraries')
        shutil.rmtree('./build/data', True)
        shutil.copytree('./data', './build/data')
        file = f'{copied[:-2]}.asm'
        cmd = f"\"{args.compiler if args.compiler else os.path.join(os.pardir, 'vbcc/bin/vbccsonic')}\" \"{copied}\""
        subprocess.run(shlex.split(cmd), check=True)

    parse_file()

    # Substitute labels for addresses
    for addr in label_addresses:
        label = label_addresses[addr]
        if label not in labels:
            error("No such label: " + label, -1)
        offset = 0
        if memory:
            if labels[label] < 0x10000:
                offset = 0x10000
            else:
                offset = 0x18000
        write_word_in_output(addr, labels[label] + offset)

    # Substitute labels for relative jumps
    for addr in label_jumps:
        label = label_jumps[addr]
        if label not in labels:
            error("No such label: " + label, -1)
        offset = labels[label] - (addr + 4)  # Relative to address of next instruction
        write_word_in_output(addr, offset & 0xFFFFFFFF)

    # Ensure ROM size
    if memory:
        ensure_output_size(0x8000)
        if address > 0x8000:
            error("In-memory program size exceeded", -1)
    else:
        if address > 0x10000:
            error("Program size exceeded", -1)

    # Save machine code results
    rom_name = os.path.splitext(os.path.basename(args.program))[0] + (".img" if memory else ".bin")
    rom_path = os.path.join("./build", rom_name)
    f = open(rom_path, "wb")
    f.write(output)
    f.close()

    # Patch rom and flash dev board if needed
    fpga_dir = os.path.join(os.pardir, 'fpga')
    if args.fpga == "patch":
        os.system(f'/bin/bash "{os.path.join(fpga_dir, "patch_rom.sh")}" "{os.path.abspath(rom_path)}"')
    elif args.fpga == "flash":
        os.system(f'/bin/bash "{os.path.join(fpga_dir, "incremental_flash.sh")}" "{os.path.abspath(rom_path)}"')

    # Run emulator if needed
    if args.run:
        os.chdir('./build')
        cmd = f"\"{args.emulator if args.emulator else os.path.join(os.pardir, os.pardir, 'emulator/build/Emulator')}\" \"{rom_name}\""
        subprocess.run(shlex.split(cmd))


if __name__ == "__main__":
    main()
