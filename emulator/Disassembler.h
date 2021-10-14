#ifndef EMULATOR_DISASSEMBLER_H
#define EMULATOR_DISASSEMBLER_H

#include <cstdint>
#include <string>
#include <vector>
#include <list>

enum AddressingMode {
    Implied,
};

const uint8_t ADDRESSING_MODE_SIZES[10]{2};

struct InstructionType {
    const char *text;
    AddressingMode mode;
};

struct InstructionData {
    uint32_t address;
    std::string assembly;
    uint8_t size;
    uint8_t data[6];
};

struct Instruction {
    uint32_t address;
    uint8_t size;
    std::string text;
};

const InstructionType INSTRUCTIONS[128]{
        {"NOP", Implied},
};

class Disassembler {
public:
    explicit Disassembler(uint8_t *memory);
    const std::vector<Instruction> &getDisassembled() const;

private:
    uint8_t *memory;
    std::list<InstructionData> instructions{};
    std::vector<Instruction> disassembled{};

    void disassemble(uint32_t address = 0, int depth = 0);
    InstructionData disassembleInstruction(uint32_t address) const;
    void build();
};

#endif //EMULATOR_DISASSEMBLER_H
