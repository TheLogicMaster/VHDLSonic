#include <iostream>
#include "FPGA.h"
#include "json.hpp"
#include "Utilities.h"
#include <future>
#include <thread>
#include <chrono>

FPGA::FPGA() : Computer() {
    updateRegisters();
    updateMemory();
}

void FPGA::sendCommand(const std::string &name) {
    std::cerr << '{' << name << '}' << std::endl;
}

void FPGA::updateMemory(bool force) {
    if (updatingMemory and not force)
        return;
    sendCommand("UpdateMemory");
    updatingMemory = true;
}

void FPGA::updateRegisters(bool force) {
    if (updatingRegisters and not force)
        return;
    sendCommand("UpdateRegisters");
    updatingRegisters = true;
}

void FPGA::writeMemory(uint32_t address) {
    sendCommand(stringFormat("WriteMemory:%u,%u", address / 4, reverseWordBytes(((uint32_t*)ram)[address / 4])));
}

void FPGA::setBreakpoint(int index, uint32_t address) {
    sendCommand(stringFormat("SetBreakpoint:%i,%u", index, address));
}

void FPGA::addBreakpoint(uint32_t address) {
    for (auto breakpoint : breakpoints)
        if (breakpoint == address)
            return;
    for (int i = 0; i < FPGA_BREAKPOINTS; i++)
        if (breakpoints[i] == 0) {
            setBreakpoint(i, address);
            breakpoints[i] = address;
            break;
        }
}

void FPGA::clearBreakpoint(uint32_t address) {
    for (int i = 0; i < FPGA_BREAKPOINTS; i++)
        if (breakpoints[i] == address) {
            setBreakpoint(i, 0);
            breakpoints[i] = 0;
            break;
        }
}

void FPGA::pause() {
    if (paused)
        sendCommand("Continue");
    else
        sendCommand("Pause");
    if (not autoUpdate) {
        updateRegisters(true);
        updateMemory(true);
    }
}

void FPGA::step() {
    if (stepping)
        return;
    sendCommand("Step");
    stepping = true;
    if (not autoUpdate) {
        updateRegisters(true);
        updateMemory(true);
    }
}

bool FPGA::isHalted() const {
    return halted;
}

bool FPGA::isPaused() const {
    return paused;
}

bool &FPGA::getAutoUpdate() {
    return autoUpdate;
}

std::string FPGA::getCommandResponse() {
    std::string response;
    std::cin >> response;
    return response;
}

template<class t>
void FPGA::parseRegister(t &reg, const std::string &name, const nlohmann::json &registerData) {
    if (registerData.contains(name))
        reg = registerData[name].get<int>();
    else
        std::cout << "Failed to parse register: " << name << std::endl;
}

int FPGA::run(int delta) {
    if (!responseFuture.valid())
        responseFuture = std::async(getCommandResponse);

    if (responseFuture.wait_for(std::chrono::seconds(0)) == std::future_status::ready) {
        std::string response = responseFuture.get();
        try {
            auto json = nlohmann::json::parse(response);

            if (json["command"] == "{Step}")
                stepping = false;

            if (json.contains("memory")) {
                int offset = 0;
                for (auto value: json["memory"].get<std::vector<int>>()) {
                    if (offset >= 0x8000 / 4) {
                        std::cout << "Memory too large" << std::endl;
                        break;
                    }
                    ((uint32_t *) ram)[offset++] = reverseWordBytes(value);
                }
                updatingMemory = false;
                if (autoUpdate)
                    updateMemory();
            }

            if (json.contains("registers")) {
                const auto &registerData = json["registers"];
                parseRegister(pc, "pc", registerData);
                parseRegister(interruptEnable, "interrupt_enable", registerData);
                parseRegister(interruptFlags, "interrupt_flags", registerData);
                parseRegister(status, "status", registerData);
                parseRegister(halted, "s_halted", registerData);
                parseRegister(paused, "paused", registerData);
                if (registerData.contains("reg_file")) {
                    const auto &arr = registerData["reg_file"];
                    for (int i = 0; i < 16; i++) {
                        if (arr.size() <= i) {
                            std::cout << "Warning: Missing registers" << std::endl;
                            break;
                        }
                        registers[i] = arr[i];
                    }
                }
                updatingRegisters = false;
                if (autoUpdate)
                    updateRegisters();
            }
        } catch (nlohmann::json::parse_error &e) {
            std::cout << "Failed to parse response: " << e.what() << ", Response: " << response << std::endl;
        }
        responseFuture = std::async(getCommandResponse);
    }
    return 0;
}

void FPGA::reset() {
    Computer::reset();
    for (auto &breakpoint : breakpoints)
        breakpoint = 0;
    sendCommand("Reset");
    stepping = false;
    updatingMemory = false;
    updatingRegisters = false;
}

uint8_t *FPGA::getDisplayBuffer() {
    return nullptr;
}

bool FPGA::isRendering() const {
    return false;
}

int16_t FPGA::getHorizontalScroll() const {
    return 0;
}

int16_t FPGA::getVerticalScroll() const {
    return 0;
}

uint16_t FPGA::getWindowX() const {
    return 0;
}

uint16_t FPGA::getWindowY() const {
    return 0;
}

Color FPGA::getPaletteColor(int index) const {
    return {};
}

uint32_t FPGA::getTileData(int index, int tileRow) const {
    return 0;
}

uint8_t FPGA::getBackgroundData(int index) const {
    return 0;
}

uint8_t FPGA::getWindowData(int index) const {
    return 0;
}

const Sprite &FPGA::getSprite(int index) const {
    return dummySprite;
}

void FPGA::sampleAudio(float *buffer, int samples) {

}

const SquareChannel &FPGA::getSquareChannel(int channel) {
    return dummySquareChannel;
}
