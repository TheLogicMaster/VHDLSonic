#include "Disassembler.h"

#include "Utilities.h"

Disassembler::Disassembler(uint8_t *memory) : memory(memory) {
    for (int i = 0; i < 8; i++)
        disassemble(i * 8, 0, true);
}

const std::list<Instruction> &Disassembler::getDisassembled() const {
    return disassembled;
}

void Disassembler::disassemble(uint32_t address, int depth, bool jumpTable) {
    if (depth > 100)
        return;

    while (address <= 0xFFFF and address % 4 == 0) {
        auto instruction = disassembleInstruction(address);
        uint32_t end = address + instruction.size - 1;
        if (instruction.size == 0 or address + instruction.size - 1 > 0xFFFF)
            return;

        auto it = disassembled.end();
        if (!disassembled.empty()) {
            do {
                it--;
                if ((*it).address <= end)
                    break;
            } while (it != disassembled.begin());
            if ((*it).address + (*it).size > address)
                return;
            it++;
        }
        disassembled.insert(it, instruction);

        if (instruction.opcode == 0x46) { // JMP addr
            disassemble(instruction.immediate, depth + 1);
            return;
        } else if (instruction.opcode == 0x0f) { // BRA
            disassemble(end + 1 + *(int32_t*)&instruction.immediate, depth + 1);
            return;
        }

        if (jumpTable)
            return;

        if (instruction.opcode == 0x47) { // JMP r
            // Todo: Support disassembling after variable jumps
            //variableJumps.emplace_back(address);
            return;
        } else if (instruction.opcode >= 0x01 && instruction.opcode <= 0x0E) // Conditional branching
            disassemble(end + 1 + *(int32_t*)&instruction.immediate, depth + 1);
        else if (instruction.opcode == 0x48) // JSR
            disassemble(instruction.immediate, depth + 1);
        else if (instruction.opcode == 0x49 || instruction.opcode == 0x4B || instruction.opcode == 0x00) // RET, RTI, HALT
            return;
        address = end + 1;
    }
}

Instruction Disassembler::disassembleInstruction(uint32_t address) const {
    uint8_t opcode = memory[address];
    uint8_t reg1 = memory[address + 1] >> 4;
    uint8_t reg2 = memory[address + 1] & 0xF;
    bool indexPost = memory[address + 2] & 0x80;
    bool indexInc = memory[address + 2] & 0x40;
    bool indexDec = memory[address + 2] & 0x20;
    uint32_t immediate = reverseWordBytes(*(uint32_t*)&(memory + 4)[address]);
    int32_t immediateRelative = *(int32_t*)&immediate;
    auto type = INSTRUCTIONS[opcode];

    if (type.text == nullptr)
        return Instruction{address, "Invalid"};

    Instruction instruction{address, "", ADDRESSING_MODE_SIZES[type.mode], opcode};

    instruction.immediate = immediate;
    instruction.opcode = opcode;

    instruction.assembly += stringFormat("$%05x: ", instruction.address);

    instruction.assembly += stringFormat("$%02x ", opcode);
    instruction.assembly += stringFormat("$%02x ", memory[address + 1]);
    if (instruction.size == 2)
        instruction.assembly += "           ";
    else if (instruction.size == 6)
        instruction.assembly += stringFormat("$%08x  ", immediate);

    instruction.assembly += type.text;

    switch (type.mode) {
        case Implied:
            break;
        case Immediate:
            instruction.assembly += stringFormat(" $%08x", immediate);
            break;
        case Register:
            instruction.assembly += stringFormat(" R%d", reg1);
            break;
        case RelativeJump:
            instruction.assembly += stringFormat(" %d", immediateRelative);
            break;
        case RegisterImmediate:
            instruction.assembly += stringFormat(" R%d,$%08x", reg1, immediate);
            break;
        case RegisterAddress:
            instruction.assembly += stringFormat(" R%d,[$%08x]", reg1, immediate);
            break;
        case RegisterRegister:
            instruction.assembly += stringFormat(" R%d,R%d", reg1, reg2);
            break;
        case Relative:
            instruction.assembly += stringFormat(" R%d,R%d,%d", reg1, reg2, immediateRelative);
            break;
        case Indexed:
            instruction.assembly += stringFormat(" R%d,", reg1);
            if (!indexPost) {
                if (indexInc)
                    instruction.assembly += "++";
                else if (indexDec)
                    instruction.assembly += "--";
            }
            instruction.assembly += stringFormat("R%d", reg2);
            if (indexPost) {
                if (indexInc)
                    instruction.assembly += "++";
                else if (indexDec)
                    instruction.assembly += "--";
            }
            break;
    }
    return instruction;
}
