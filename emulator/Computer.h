#ifndef EMULATOR_COMPUTER_H
#define EMULATOR_COMPUTER_H

#include "APU.h"
#include "GPU.h"
#include <cstdint>
#include <queue>
#include <string>

#define PRINT_BUFFER 10000

#define FLAG_I 1 << 4
#define FLAG_Z 1 << 3
#define FLAG_C 1 << 2
#define FLAG_N 1 << 1
#define FLAG_V 1 << 0

struct Timer {
    bool enabled = false;
    bool repeat = false;
    uint16_t divider = 1;
    uint64_t count = 0;
    uint32_t compare = 0;
    uint32_t ticks = 0;
};

class Computer {
public:
    Computer();
    virtual void load(uint8_t *romData, long size);
    virtual int run(int delta) = 0;
    virtual void reset();

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
    uint8_t getTimerIE() const;
    uint8_t getTimerIF() const;
    Timer& getTimer(int id);
    uint8_t getPWMDuty(int id);
    bool getPWMEnabled(int id);

    virtual uint8_t *getDisplayBuffer() = 0;
    virtual bool isRendering() const = 0;
    virtual int16_t getHorizontalScroll() const = 0;
    virtual int16_t getVerticalScroll() const = 0;
    virtual uint16_t getWindowX() const = 0;
    virtual uint16_t getWindowY() const = 0;
    virtual Color getPaletteColor(int index) const = 0;
    virtual uint32_t getTileData(int index, int tileRow) const = 0;
    virtual uint8_t getBackgroundData(int index) const = 0;
    virtual uint8_t getWindowData(int index) const = 0;
    virtual const Sprite &getSprite(int index) const = 0;

    virtual void sampleAudio(float *buffer, int samples) = 0;
    virtual const SquareChannel &getSquareChannel(int channel) = 0;

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
    uint8_t pwmDuty[8]{};
    bool pwmEnabled[8]{};

    uint8_t memory[0x20000]{};
    uint8_t *rom;
    uint8_t *ram;

    uint32_t registers[16]{};
    uint8_t status = 0;
    uint32_t pc = 0;
    uint8_t interruptEnable = 0;
    uint8_t interruptFlags = 0;
};


#endif //EMULATOR_COMPUTER_H
