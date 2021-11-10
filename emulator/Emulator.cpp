#include <iostream>
#include <cstring>
#include <bitset>
#include <ctime>
#include <cmath>

#include "Emulator.h"
#include "Utilities.h"

Emulator::Emulator() {
    srand(time(nullptr));
    rom = memory;
    ram = memory + 0x18000;
}

void Emulator::load(uint8_t *romData, long size) {
    memset(rom, 0, 0x18000);
    memcpy(rom, romData, std::min(size, 0x18000l));
}

int Emulator::run() {
    if (interruptFlags & 1) {
        reset();
        return 0;
    }

    interruptFlags |= gpu.update() | apu.update();

    if ((status & FLAG_I && interruptFlags & interruptEnable) || interruptFlags & 2) {
        uint8_t interrupt;
        for (interrupt = 1; interrupt < 8; interrupt++)
            if (interruptFlags & (interruptEnable | 2) & (1 << interrupt))
                break;
        interruptFlags &= ~(1 << interrupt);
        writeUint8(registers[15], status);
        registers[15] += 4;
        writeUint32(registers[15], pc);
        registers[15] += 4;
        pc = interrupt * 8;
        setFlag(FLAG_I, false);
        return 0;
    }

    uint32_t instruction = ingestUint32();
    uint8_t opcode = (instruction & 0xFF000000) >> 24;

    switch (opcode) {
        default:
        case 0x00: // NOP
            break;
        case 0x01 ... 0x0F: // Branch instructions
            {
                int32_t jump = ingestInt32();
                switch (opcode) {
                    case 0x01: // BEQ
                        if (status & FLAG_Z)
                            pc += jump;
                        break;
                    case 0x02: // BNE
                        if (!(status & FLAG_Z))
                            pc += jump;
                        break;
                    case 0x03: // BHS
                        if (status & FLAG_C)
                            pc += jump;
                        break;
                    case 0x04: // BLO
                        if (!(status & FLAG_C))
                            pc += jump;
                        break;
                    case 0x05: // BMI
                        if (status & FLAG_N)
                            pc += jump;
                        break;
                    case 0x06: // BPL
                        if (!(status & FLAG_N))
                            pc += jump;
                        break;
                    case 0x07: // BVS
                        if (status & FLAG_V)
                            pc += jump;
                        break;
                    case 0x08: // BVC
                        if (!(status & FLAG_V))
                            pc += jump;
                        break;
                    case 0x09: // BHI
                        if (status & FLAG_C && !(status & FLAG_Z))
                            pc += jump;
                        break;
                    case 0x0A: // BLS
                        if (!(status & FLAG_C) && status & FLAG_Z)
                            pc += jump;
                        break;
                    case 0x0B: // BGE
                        if ((bool)(status & FLAG_N) == (bool)(status & FLAG_V))
                            pc += jump;
                        break;
                    case 0x0C: // BLT
                        if ((bool)(status & FLAG_N) != (bool)(status & FLAG_V))
                            pc += jump;
                        break;
                    case 0x0D: // BGT
                        if (!(status & FLAG_Z) && (bool)(status & FLAG_N) == (bool)(status & FLAG_V))
                            pc += jump;
                        break;
                    case 0x0E: // BLE
                        if (status & FLAG_Z || (bool)(status & FLAG_N) != (bool)(status & FLAG_V))
                            pc += jump;
                        break;
                    case 0x0F: // BRA
                        pc += jump;
                        break;
                }
            }
            break;
        case 0x12: // LDR r,imm
            getOpReg1(instruction) = ingestUint32();
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x13: // LDB r,addr
            getOpReg1(instruction) = readUint8(ingestUint32());
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x14: // LDW r,addr
            getOpReg1(instruction) = readUint16(ingestUint32());
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x15: // LDR r,addr
            getOpReg1(instruction) = readUint32(ingestUint32());
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x16: // LDB r,index
            getOpReg1(instruction) = readUint8(getIndexedAddress(instruction, 1));
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x17: // LDW r,index
            getOpReg1(instruction) = readUint16(getIndexedAddress(instruction, 2));
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x18: // LDR r,index
            getOpReg1(instruction) = readUint32(getIndexedAddress(instruction, 4));
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x19: // LDB r,r,rel
            getOpReg1(instruction) = readUint8(getOpReg2(instruction) + ingestUint32());
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x1A: // LDW r,r,rel
            getOpReg1(instruction) = readUint16(getOpReg2(instruction) + ingestUint32());
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x1B: // LDR r,r,rel
            getOpReg1(instruction) = readUint32(getOpReg2(instruction) + ingestUint32());
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x1C: // STB r,addr
            writeUint8(ingestUint32(), getOpReg1(instruction));
            break;
        case 0x1D: // STW r,addr
            writeUint16(ingestUint32(), getOpReg1(instruction));
            break;
        case 0x1E: // STR r,addr
            writeUint32(ingestUint32(), getOpReg1(instruction));
            break;
        case 0x1F: // STB r,index
            writeUint8(getIndexedAddress(instruction, 1), getOpReg1(instruction));
            break;
        case 0x20: // STW r,index
            writeUint16(getIndexedAddress(instruction, 2), getOpReg1(instruction));
            break;
        case 0x21: // STR r,index
            writeUint32(getIndexedAddress(instruction, 4), getOpReg1(instruction));
            break;
        case 0x22: // STB r,r,rel
            writeUint8(getOpReg2(instruction) + ingestUint32(), getOpReg1(instruction));
            break;
        case 0x23: // STW r,r,rel
            writeUint16(getOpReg2(instruction) + ingestUint32(), getOpReg1(instruction));
            break;
        case 0x24: // STR r,r,rel
            writeUint32(getOpReg2(instruction) + ingestUint32(), getOpReg1(instruction));
            break;
        case 0x25: // TFR r,r
            getOpReg1(instruction) = getOpReg2(instruction);
            break;
        case 0x26: // MUL r,imm
            getOpReg1(instruction) = getOpReg1(instruction) * ingestUint32();
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x27: // MUL r,r
            getOpReg1(instruction) = getOpReg1(instruction) * getOpReg2(instruction);
            setFlag(FLAG_Z, !(instruction));
            break;
        case 0x28: // ADD r,imm
            getOpReg1(instruction) = performADD(getOpReg1(instruction), ingestUint32());
            break;
        case 0x29: // ADD r,r
            getOpReg1(instruction) = performADD(getOpReg1(instruction), getOpReg2(instruction));
            break;
        case 0x2A: // ADC r,imm
            getOpReg1(instruction) = performADD(getOpReg1(instruction), ingestUint32() + (bool)(status & FLAG_C));
            break;
        case 0x2B: // ADC r,r
            getOpReg1(instruction) = performADD(getOpReg1(instruction), getOpReg2(instruction) + (bool)(status & FLAG_C));
            break;
        case 0x2C: // SUB r,imm
            getOpReg1(instruction) = performSUB(getOpReg1(instruction), ingestUint32());
            break;
        case 0x2D: // SUB r,r
            getOpReg1(instruction) = performSUB(getOpReg1(instruction), getOpReg2(instruction));
            break;
        case 0x2E: // SBC r,imm
            getOpReg1(instruction) = performSUB(getOpReg1(instruction), ingestUint32() + !(status & FLAG_C));
            break;
        case 0x2F: // SBC r,r
            getOpReg1(instruction) = performSUB(getOpReg1(instruction), getOpReg2(instruction) + !(status & FLAG_C));
            break;
        case 0x30: // AND r,imm
            getOpReg1(instruction) = getOpReg1(instruction) & ingestUint32();
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x31: // AND r,r
            getOpReg1(instruction) = getOpReg1(instruction) & getOpReg2(instruction);
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x32: // OR r,imm
            getOpReg1(instruction) = getOpReg1(instruction) | ingestUint32();
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x33: // OR r,r
            getOpReg1(instruction) = getOpReg1(instruction) | getOpReg2(instruction);
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x34: // XOR r,imm
            getOpReg1(instruction) = getOpReg1(instruction) ^ ingestUint32();
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x35: // XOR r,r
            getOpReg1(instruction) = getOpReg1(instruction) ^ getOpReg2(instruction);
            setFlag(FLAG_Z, !getOpReg1(instruction));
            break;
        case 0x36: // LSL r,imm
            getOpReg1(instruction) = performLSL(getOpReg1(instruction), ingestUint32());
            break;
        case 0x37: // LSL r,r
            getOpReg1(instruction) = performLSL(getOpReg1(instruction), getOpReg2(instruction));
            break;
        case 0x38: // LSR r,imm
            getOpReg1(instruction) = performLSR(getOpReg1(instruction), ingestUint32());
            break;
        case 0x39: // LSR r,r
            getOpReg1(instruction) = performLSR(getOpReg1(instruction), getOpReg2(instruction));
            break;
        case 0x3A: // ASR r,imm
            getOpReg1(instruction) = performASR(getOpReg1(instruction), ingestUint32());
            break;
        case 0x3B: // ASR r,r
            getOpReg1(instruction) = performASR(getOpReg1(instruction), getOpReg2(instruction));
            break;
        case 0x3C: // CMP r,imm
            performSUB(getOpReg1(instruction), ingestUint32());
            break;
        case 0x3D: // CMP r,r
            performSUB(getOpReg1(instruction), getOpReg2(instruction));
            break;
        case 0x3E: // INC r
            getOpReg1(instruction) = performADD(getOpReg1(instruction), 1);
            break;
        case 0x3F: // DEC r
            getOpReg1(instruction) = performSUB(getOpReg1(instruction), 1);
            break;
        case 0x40: // SEI
            setFlag(FLAG_I, true);
            break;
        case 0x41: // CLI
            setFlag(FLAG_I, false);
            break;
        case 0x42: // SEC
            setFlag(FLAG_C, true);
            break;
        case 0x43: // CLC
            setFlag(FLAG_C, false);
            break;
        case 0x44: // PUSH r
            writeUint32(registers[15], getOpReg1(instruction));
            registers[15] += 4;
            break;
        case 0x45: // POP r
            registers[15] -= 4;
            getOpReg1(instruction) = readUint32(registers[15]);
            break;
        case 0x46: // JMP addr
            pc = ingestUint32();
            break;
        case 0x47: // JMP r
            pc = getOpReg1(instruction);
            break;
        case 0x48: // JSR addr
            writeUint32(registers[15], pc + 4);
            registers[15] += 4;
            pc = ingestUint32();
            break;
        case 0x49: // RET
            registers[15] -= 4;
            pc = readUint32(registers[15]);
            break;
        case 0x4A: // INT imm
            interruptFlags |= 1 << ingestUint32();
            break;
        case 0x4B: // RTI
            registers[15] -= 4;
            pc = readUint32(registers[15]);
            registers[15] -= 4;
            status = readUint8(registers[15]);
            break;
        case 0x4C: // Halt
            return 1;
    }

    return 0;
}

void Emulator::reset() {
    pc = 0;
    status = 0;
    interruptEnable = 0;
    interruptFlags = 0;
    memset(ram, 0, 0x8000);
    memset(lights, 0, 10);
    memset(sevenSegmentDisplays, 0, 6);
    memset(registers, 0, 16 * 4);
    for (int i = 0; i < 36; i++)
        if (gpioOutput[i])
            gpio[i] = false;
    memset(gpioOutput, 0, 36);
    for (int i = 0; i < 16; i++)
        if (arduinoOutput[i])
            arduinoIO[i] = false;
    memset(arduinoOutput, 0, 16);
    std::queue<uint8_t>().swap(uartInBuffer);

    gpu.reset();
    apu.reset();
}

uint8_t *Emulator::getDisplayBuffer() {
    return gpu.getDisplayBuffer();
}

std::queue<uint8_t> &Emulator::getAudioSamples() {
    return apu.getSamples();
}

std::string &Emulator::getPrintBuffer() {
    return printBuffer;
}

void Emulator::uartReceive(char* bytes, uint8_t length) {
    for (int i = 0; i < length; i++) {
        if (uartInBuffer.size() >= 255)
            break;
        uartInBuffer.push(bytes[i]);
    }
}

bool &Emulator::getSwitch(int id) {
    return switches[id];
}

bool &Emulator::getButton(int id) {
    return buttons[id];
}

bool Emulator::getLight(int id) {
    return lights[id];
}

uint8_t Emulator::getSevenSegmentDisplay(int id) {
    return sevenSegmentDisplays[id];
}

bool &Emulator::getGPIO(int id) {
    return gpio[id];
}

bool &Emulator::getArduinoIO(int id) {
    return arduinoIO[id];
}

uint8_t &Emulator::getADC(int id) {
    return analogDigitalConverters[id];
}

bool Emulator::getGpioOutput(int id) {
    return gpioOutput[id];
}

bool Emulator::getArduinoOutput(int id) {
    return arduinoOutput[id];
}

uint8_t *Emulator::getMemory() {
    return memory;
}

uint8_t *Emulator::getRAM() {
    return ram;
}

uint8_t *Emulator::getROM() {
    return rom;
}

uint32_t Emulator::getReg(uint8_t reg) const {
    return registers[reg];
}

uint32_t Emulator::getPC() const {
    return pc;
}

uint8_t Emulator::getIE() const {
    return interruptEnable;
}

uint8_t Emulator::getIF() const {
    return interruptFlags;
}

uint32_t Emulator::getFP() const {
    return registers[14];
}

uint32_t Emulator::getSP() const {
    return registers[15];
}

uint8_t Emulator::getStatus() const {
    return status;
}

uint32_t Emulator::readMicrocontroller(uint32_t address) {
    switch (address) {
        case 10 ... 15: // Seven segment displays
            return sevenSegmentDisplays[address - 10];
        case 16 ... 51: // GPIO
            return gpio[address - 16];
        case 120 ... 129: // Switches
            return switches[address - 120];
        case 130 ... 131: // Buttons
            return buttons[address - 130];
        case 132: // Serial
            return uartInBuffer.front();
        case 133: // Serial available
            return (uint8_t)uartInBuffer.size();
        case 136 ... 141:
            return analogDigitalConverters[address - 136];
        default:
            return 0;
    }
}

void Emulator::writeMicrocontroller(uint32_t address, uint32_t value) {
    switch (address) {
        case 0 ... 9: // LEDs
            lights[address] = value;
            break;
        case 10 ... 15: // Seven segment displays
            sevenSegmentDisplays[address - 10] = value;
            break;
        case 132: // Serial
            if (value == 0)
                break;
            std::cout << (char)value << std::flush;
            printBuffer.push_back(*(char*)&value);
            if (printBuffer.length() > PRINT_BUFFER)
                printBuffer.erase(0, 1);
            break;
        case 133: // Serial available
            if (!uartInBuffer.empty())
                uartInBuffer.pop();
            break;
        default:
            break;
    }
}

uint32_t Emulator::readUint32(uint32_t address) {
    switch (address) {
        case 0x00000 ... 0x17FFF - 3:
            return reverseWordBytes(*(uint32_t*)&rom[address & ~0x3]);
        case 0x18000 ... 0x1FFFF - 3:
            return reverseWordBytes(*(uint32_t*)&ram[address & ~0x3 - 0x18000]);
        case 0x20000:
            return interruptEnable;
        case 0x20004:
            return interruptFlags;
        case 0x20008:
            return rand();
        case 0x30000 ... 0x3FFFF:
            return gpu.read((address - 0x30000) / 4);
        case 0x40000 ... 0x4FFFF:
            return readMicrocontroller((address - 0x40000) / 4);
        default:
            return 0;
    }
}

void Emulator::writeUint32(uint32_t address, uint32_t value) {
    switch (address) {
        case 0x18000 ... 0x1FFFF - 3:
            *(uint32_t*)&ram[address & ~0x3 - 0x18000] = reverseWordBytes(value);
            break;
        case 0x20000:
            interruptEnable = value;
            break;
        case 0x20004:
            interruptFlags = value;
            break;
        case 0x20008:
            srand(value);
            break;
        case 0x30000 ... 0x3FFFF:
            gpu.write((address - 0x30000) / 4, value);
            break;
        case 0x40000 ... 0x4FFFF:
            writeMicrocontroller((address - 0x40000) / 4, value);
            break;
        default:
            break;
    }
}

uint16_t Emulator::readUint16(uint32_t address) {
    return readUint32(address & ~0x3) >> (2 - (address & 0x2)) * 8;
}

void Emulator::writeUint16(uint32_t address, uint16_t value) {
    writeUint32(address & ~0x3,
                readUint32(address & ~0x3) & 0xFFFF << (address & 0x2) * 8 | value << (2 - (address & 0x2)) * 8);
}

uint8_t Emulator::readUint8(uint32_t address) {
    return readUint32(address & ~0x3) >> (3 - (address & 0x3)) * 8;
}

void Emulator::writeUint8(uint32_t address, uint8_t value) {
    writeUint32(address & ~0x3,
                readUint32(address & ~0x3) & ~(0xFF << (3 - (address & 0x3)) * 8) | value << (3 - (address & 0x3)) * 8);
}

uint32_t Emulator::ingestUint32() {
    pc += 4;
    return readUint32(pc - 4);
}

int32_t Emulator::ingestInt32() {
    uint32_t value = ingestUint32();
    return *(int32_t*)&value;
}

uint32_t &Emulator::getOpReg1(uint32_t instruction) {
    return registers[(instruction & 0xF00000) >> 20];
}

uint32_t &Emulator::getOpReg2(uint32_t instruction) {
    return registers[(instruction & 0xF0000) >> 16];
}

uint32_t Emulator::getIndexedAddress(uint32_t instruction, int size) {
    uint32_t &reg = getOpReg2(instruction);
    if (!(instruction & 0x8000)) {
        if (instruction & 0x4000)
            reg += size;
        else if (instruction & 0x2000)
            reg -= size;
    }
    uint32_t address = reg;
    if (instruction & 0x8000) {
        if (instruction & 0x4000)
            reg += size;
        else if (instruction & 0x2000)
            reg -= size;
    }
    return address;
}

void Emulator::setFlag(uint8_t flag, bool set) {
    if (set)
        status |= flag;
    else
        status &= ~flag;
}

uint32_t Emulator::performADD(uint32_t reg, uint32_t value) {
    uint32_t result = reg + value;
    setFlag(FLAG_Z, !result);
    setFlag(FLAG_C, value + reg > 0xFF);
    setFlag(FLAG_N, result & 0x80000000);
    setFlag(FLAG_V, (reg & 0x80000000) == (value & 0x80000000) and (reg & 0x80000000) != (result & 0x80000000));
    return result;
}

uint32_t Emulator::performSUB(uint32_t reg, uint32_t value) {
    uint32_t result = reg - value;
    setFlag(FLAG_Z, !result);
    setFlag(FLAG_C, value <= reg);
    setFlag(FLAG_N, result & 0x80000000);
    setFlag(FLAG_V, (reg ^ result) & (~value ^ result) & 0x80000000);
    return result;
}

uint32_t Emulator::performLSL(uint32_t reg, uint32_t value) {
    setFlag(FLAG_C, value and (reg << (value - 1)) & 0x80000000);
    uint32_t result = reg << value;
    setFlag(FLAG_Z, !result);
    return result;
}

uint32_t Emulator::performLSR(uint32_t reg, uint32_t value) {
    setFlag(FLAG_C, (reg >> (value - 1)) & 0x1);
    uint32_t result = reg >> value;
    setFlag(FLAG_Z, !result);
    return result;
}

uint32_t Emulator::performASR(uint32_t reg, uint32_t value) {
    setFlag(FLAG_C, (reg >> (value - 1)) & 0x1);
    int32_t signedResult = (*(int32_t*)&reg) >> value;
    uint32_t result = *(uint32_t*)&signedResult;
    setFlag(FLAG_Z, !result);
    return result;
}
