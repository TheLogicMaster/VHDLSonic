#include <iostream>
#include <bitset>
#include <cmath>

#include "Emulator.h"
#include "Utilities.h"

int Emulator::run(int delta) {
    apu.update(delta);

    for (int i = 0; i < 8; i++) {
        auto &timer = timers[i];

        if (timer.divider == 0 or !timer.enabled)
            continue;

        timer.ticks += 50 * delta;
        timer.count += timer.ticks / timer.divider;
        timer.ticks %= timer.divider;
        if (timer.count >= timer.compare) {
            timer.count = 0;
            timerInterruptFlags |= 1 << i;
            if (!timer.repeat)
                timer.enabled = false;
        }
    }

    if (timerInterruptEnable & timerInterruptFlags)
        interruptFlags |= 1 << 4;

    if (interruptFlags & 1) {
        reset();
        return 0;
    }

    interruptFlags |= gpu.update();

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
            pc -= 4;
            return 1;
    }

    return 0;
}

void Emulator::reset() {
    Computer::reset();

    gpu.reset();
    apu.reset();
}

uint8_t *Emulator::getDisplayBuffer() {
    return gpu.getDisplayBuffer();
}

void Emulator::sampleAudio(float *buffer, int samples) {
    apu.sample(buffer, samples);
}

bool Emulator::isRendering() const {
    return gpu.isRendering();
}

int16_t Emulator::getHorizontalScroll() const {
    return gpu.getHorizontalScroll();
}

int16_t Emulator::getVerticalScroll() const {
    return gpu.getVerticalScroll();
}

uint16_t Emulator::getWindowX() const {
    return gpu.getWindowX();
}

uint16_t Emulator::getWindowY() const {
    return gpu.getWindowY();
}

Color Emulator::getPaletteColor(int index) const {
    return gpu.getPaletteColor(index);
}

uint32_t Emulator::getTileData(int index, int tileRow) const {
    return gpu.getTileData(index, tileRow);
}

uint8_t Emulator::getBackgroundData(int index) const {
    return gpu.getBackgroundData(index);
}

uint8_t Emulator::getWindowData(int index) const {
    return gpu.getWindowData(index);
}

const Sprite &Emulator::getSprite(int index) const {
    return gpu.getSprite(index);
}

const SquareChannel &Emulator::getSquareChannel(int channel) {
    return apu.getSquareChannel(channel);
}

uint32_t Emulator::readMicrocontroller(uint32_t address) {
    switch (address) {
        case 0 ... 9: // LEDs
            return lights[address];
        case 10 ... 15: // Seven segment displays
            return sevenSegmentDisplays[address - 10];
        case 16 ... 51: // GPIO
            return gpio[address - 16];
        case 52 ... 87: // GPIO modes
            return gpioOutput[address - 52];
        case 88 ... 103: // Arduino
            return arduinoIO[address - 88];
        case 104 ... 119: // Arduino modes
            return arduinoOutput[address - 104];
        case 120 ... 129: // Switches
            return switches[address - 120];
        case 130 ... 131: // Buttons
            return buttons[address - 130];
        case 132: // Serial
            if (uartInBuffer.empty())
                return 0;
            return uartInBuffer.front();
        case 133: // Serial available
            return (uint8_t)uartInBuffer.size();
        case 136 ... 141: // ADCs
            return analogDigitalConverters[address - 136];
        case 142 ... 149: // PWM Enable
            return pwmEnabled[address - 142];
        case 150 ... 157: // PWM Duty
            return pwmDuty[address - 150];
        case 158: // Timer IE
            return timerInterruptEnable;
        case 159: // Timer IF
            return timerInterruptFlags;
        case 160 ... 167: // Timer repeat
            return timers[address - 160].repeat;
        case 168 ... 175: // Timer count
            return timers[address - 168].count;
        case 176 ... 183: // Timer divider
            return timers[address - 176].divider;
        case 184 ... 191: // Timer enabled
            return timers[address - 184].enabled;
        case 192 ... 199: // Timer compare
            return timers[address - 192].compare;
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
        case 16 ... 51: // GPIO
            gpio[address - 16] = value;
            break;
        case 52 ... 87: // GPIO modes
            gpioOutput[address - 52] = value;
            break;
        case 88 ... 103: // Arduino
            arduinoIO[address - 88] = value;
            break;
        case 104 ... 119: // Arduino modes
            arduinoOutput[address - 104] = value;
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
        case 142 ... 149: // PWM Enable
            pwmEnabled[address - 142] = value;
            break;
        case 150 ... 157: // PWM Duty
            pwmDuty[address - 150] = value;
            break;
        case 158: // Timer IE
            timerInterruptEnable = value;
            break;
        case 159: // Timer IF
            timerInterruptFlags = value;
            break;
        case 160 ... 167: // Timer repeat
            timers[address - 160].repeat = value;
            break;
        case 168 ... 175: // Timer count
            timers[address - 168].count = value;
            break;
        case 176 ... 183: // Timer prescaler
            timers[address - 176].divider = value;
            break;
        case 184 ... 191: // Timer enabled
            timers[address - 184].enabled = value;
            break;
        case 192 ... 199: // Timer compare
            timers[address - 192].compare = value;
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
        case 0x50000 ... 0x5FFFF:
            return apu.read((address - 0x50000) / 4);
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
        case 0x50000 ... 0x5FFFF:
            apu.write((address - 0x50000) / 4, value);
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
