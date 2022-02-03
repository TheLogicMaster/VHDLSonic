#include <iostream>
#include <cstring>
#include <bitset>
#include <ctime>
#include <cmath>

#include "Emulator.h"

Computer::Computer() {
    srand(time(nullptr));
    rom = memory;
    ram = memory + 0x18000;
}

void Computer::load(uint8_t *romData, long size) {
    memset(rom, 0, 0x18000);
    memcpy(rom, romData, std::min(size, 0x18000l));
}

void Computer::reset() {
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

    for (auto &timer : timers)
        timer = {};
    timerInterruptEnable = 0;
    timerInterruptFlags = 0;

    memset(pwmEnabled, 0, 8);
    memset(pwmDuty, 0, 8);
}

std::string &Computer::getPrintBuffer() {
    return printBuffer;
}

void Computer::uartReceive(char* bytes, uint8_t length) {
    for (int i = 0; i < length; i++) {
        if (uartInBuffer.size() >= 255)
            break;
        uartInBuffer.push(bytes[i]);
    }
}

bool &Computer::getSwitch(int id) {
    return switches[id];
}

bool &Computer::getButton(int id) {
    return buttons[id];
}

bool Computer::getLight(int id) {
    return lights[id];
}

uint8_t Computer::getSevenSegmentDisplay(int id) {
    return sevenSegmentDisplays[id];
}

bool &Computer::getGPIO(int id) {
    return gpio[id];
}

bool &Computer::getArduinoIO(int id) {
    return arduinoIO[id];
}

uint8_t &Computer::getADC(int id) {
    return analogDigitalConverters[id];
}

bool Computer::getGpioOutput(int id) {
    return gpioOutput[id];
}

bool Computer::getArduinoOutput(int id) {
    return arduinoOutput[id];
}

uint8_t Computer::getTimerIE() const {
    return timerInterruptEnable;
}

uint8_t Computer::getTimerIF() const {
    return timerInterruptFlags;
}

uint8_t Computer::getPWMDuty(int id) {
    return pwmDuty[id];
}

bool Computer::getPWMEnabled(int id) {
    return pwmEnabled[id];
}

Timer &Computer::getTimer(int id) {
    return timers[id];
}

uint8_t *Computer::getMemory() {
    return memory;
}

uint8_t *Computer::getRAM() {
    return ram;
}

uint8_t *Computer::getROM() {
    return rom;
}

uint32_t Computer::getReg(uint8_t reg) const {
    return registers[reg];
}

uint32_t Computer::getPC() const {
    return pc;
}

uint8_t Computer::getIE() const {
    return interruptEnable;
}

uint8_t Computer::getIF() const {
    return interruptFlags;
}

uint32_t Computer::getFP() const {
    return registers[14];
}

uint32_t Computer::getSP() const {
    return registers[15];
}

uint8_t Computer::getStatus() const {
    return status;
}
