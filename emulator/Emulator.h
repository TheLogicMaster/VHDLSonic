#ifndef EMULATOR_EMULATOR_H
#define EMULATOR_EMULATOR_H

#include <cstdint>
#include <queue>
#include "GPU.h"
#include "APU.h"

#define PRINT_BUFFER 10000

#define FLAG_I 1 << 4
#define FLAG_Z 1 << 3
#define FLAG_C 1 << 2
#define FLAG_N 1 << 1
#define FLAG_V 1 << 0

struct Timer {
    bool enabled;
    bool repeat;
    uint16_t divider = 1;
    uint64_t count;
    uint32_t compare;
    uint32_t ticks;
};

class Emulator {
public:
    Emulator();
    void load(uint8_t *romData, long size);
    int run();
    void reset();
    void updateTimers(int delta);

    uint8_t *getDisplayBuffer();
    std::queue<uint8_t> &getAudioSamples();

    std::string &getPrintBuffer();
    void uartReceive(char* bytes, uint8_t length);
    bool& getSwitch(int id);
    bool& getButton(int id);
    bool getLight(int id);
    uint8_t getSevenSegmentDisplay(int id);
    bool& getGPIO(int id);
    bool& getArduinoIO(int id);
    bool getGpioOutput(int id);
    bool getArduinoOutput(int id);
    uint8_t& getADC(int id);
    Timer& getTimer(int index);

    uint8_t* getMemory();
    uint8_t* getRAM();
    uint8_t* getROM();
    uint32_t getReg(uint8_t reg) const;
    uint32_t getPC() const;
    uint8_t getIE() const;
    uint8_t getIF() const;
    uint32_t getFP() const;
    uint32_t getSP() const;
    uint8_t getStatus() const;

private:
    GPU gpu{};
    APU apu{};

    bool switches[10]{};
    bool lights[10]{};
    bool buttons[2]{};
    uint8_t sevenSegmentDisplays[6]{};
    bool gpio[36]{};
    bool gpioOutput[36]{};
    bool arduinoIO[16]{};
    bool arduinoOutput[16]{};
    uint8_t analogDigitalConverters[6]{};
    std::queue<uint8_t> uartInBuffer{};
    std::string printBuffer{};
    Timer timers[8]{};
    uint8_t timerInterruptEnable = 0;
    uint8_t timerInterruptFlags = 0;

    uint8_t memory[0x20000]{};
    uint8_t *rom;
    uint8_t *ram;

    uint32_t registers[16]{};
    uint8_t status = 0;
    uint32_t pc = 0;
    uint8_t interruptEnable = 0;
    uint8_t interruptFlags = 0;

    uint32_t readMicrocontroller(uint32_t address);
    void writeMicrocontroller(uint32_t address, uint32_t value);

    uint8_t readUint8(uint32_t address);
    void writeUint8(uint32_t address, uint8_t value);
    uint16_t readUint16(uint32_t address);
    void writeUint16(uint32_t address, uint16_t value);
    uint32_t readUint32(uint32_t address);
    void writeUint32(uint32_t address, uint32_t value);

    uint32_t ingestUint32();
    int32_t ingestInt32();

    uint32_t &getOpReg1(uint32_t instruction);
    uint32_t &getOpReg2(uint32_t instruction);

    uint32_t getIndexedAddress(uint32_t instruction, int size);

    void setFlag(uint8_t flag, bool set);

    uint32_t performADD(uint32_t reg, uint32_t value);
    uint32_t performSUB(uint32_t reg, uint32_t value);
    uint32_t performLSL(uint32_t reg, uint32_t value);
    uint32_t performLSR(uint32_t reg, uint32_t value);
    uint32_t performASR(uint32_t reg, uint32_t value);
};

#endif //EMULATOR_EMULATOR_H
