#ifndef EMULATOR_DISASSEMBLER_H
#define EMULATOR_DISASSEMBLER_H

#include <cstdint>
#include <string>
#include <vector>
#include <list>

enum AddressingMode {
    Implied,
    Immediate,
    Register,
    RelativeJump,
    RegisterImmediate,
    RegisterAddress,
    RegisterRegister,
    Relative,
    Indexed
};

const uint8_t ADDRESSING_MODE_SIZES[9]{4, 8, 4, 8, 8, 8, 4, 8, 4};

struct InstructionType {
    const char *text;
    AddressingMode mode;
};

struct Instruction {
    uint32_t address;
    std::string assembly;
    uint8_t size;
    uint8_t opcode;
    uint32_t immediate;
};

const InstructionType INSTRUCTIONS[128]{
        {"NOP", Implied},
        {"BEQ", RelativeJump},
        {"BNE", RelativeJump},
        {"BHS", RelativeJump},
        {"BLO", RelativeJump},
        {"BMI", RelativeJump},
        {"BPL", RelativeJump},
        {"BVS", RelativeJump},
        {"BVC", RelativeJump},
        {"BHI", RelativeJump},
        {"BLS", RelativeJump},
        {"BGE", RelativeJump},
        {"BLT", RelativeJump},
        {"BGT", RelativeJump},
        {"BLE", RelativeJump},
        {"BRA", RelativeJump},
        {},
        {},
        {"LDR", RegisterImmediate},
        {"LDB", RegisterAddress},
        {"LDW", RegisterAddress},
        {"LDR", RegisterAddress},
        {"LDB", Indexed},
        {"LDW", Indexed},
        {"LDR", Indexed},
        {"LDB", Relative},
        {"LDW", Relative},
        {"LDR", Relative},
        {"STB", RegisterAddress},
        {"STW", RegisterAddress},
        {"STR", RegisterAddress},
        {"STB", Indexed},
        {"STW", Indexed},
        {"STR", Indexed},
        {"STB", Relative},
        {"STW", Relative},
        {"STR", Relative},
        {"TFR", RegisterRegister},
        {"MUL", RegisterImmediate},
        {"MUL", RegisterRegister},
        {"ADD", RegisterImmediate},
        {"ADD", RegisterRegister},
        {"ADC", RegisterImmediate},
        {"ADC", RegisterRegister},
        {"SUB", RegisterImmediate},
        {"SUB", RegisterRegister},
        {"SBC", RegisterImmediate},
        {"SBC", RegisterRegister},
        {"AND", RegisterImmediate},
        {"AND", RegisterRegister},
        {"OR", RegisterImmediate},
        {"OR", RegisterRegister},
        {"XOR", RegisterImmediate},
        {"XOR", RegisterRegister},
        {"CMP", RegisterImmediate},
        {"CMP", RegisterRegister},
        {"LSL", RegisterImmediate},
        {"LSL", RegisterRegister},
        {"LSR", RegisterImmediate},
        {"LSR", RegisterRegister},
        {"ASR", RegisterImmediate},
        {"ASR", RegisterRegister},
        {"INC", Register},
        {"DEC", Register},
        {"SEI", Implied},
        {"CLI", Implied},
        {"SEC", Implied},
        {"CLC", Implied},
        {"PUSH", Register},
        {"POP", Register},
        {"JMP", Immediate},
        {"JMP", Register},
        {"JSR", Immediate},
        {"RET", Implied},
        {"INT", Immediate},
        {"RTI", Implied},
        {"HALT", Implied},
};

class Disassembler {
public:
    explicit Disassembler(uint8_t *memory);
    const std::list<Instruction> &getDisassembled() const;

private:
    uint8_t *memory;
    std::list<Instruction> disassembled{};

    void disassemble(uint32_t address = 0, int depth = 0, bool jumpTable = false);
    Instruction disassembleInstruction(uint32_t address) const;
};

#endif //EMULATOR_DISASSEMBLER_H
