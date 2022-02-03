#ifndef EMULATOR_FPGA_H
#define EMULATOR_FPGA_H

#include <future>
#include "Computer.h"
#include "GPU.h"
#include "APU.h"
#include "json.hpp"

#define FPGA_BREAKPOINTS 5

class FPGA : public Computer {
public:
    FPGA();
    int run(int delta) override;
    void reset() override;

    void updateMemory(bool force = false);
    void updateRegisters(bool force = false);
    void writeMemory(uint32_t address);
    void addBreakpoint(uint32_t address);
    void clearBreakpoint(uint32_t address);
    void pause();
    void step();
    bool isHalted() const;
    bool isPaused() const;
    bool &getAutoUpdate();

    uint8_t *getDisplayBuffer() override;
    bool isRendering() const override;
    int16_t getHorizontalScroll() const override;
    int16_t getVerticalScroll() const override;
    uint16_t getWindowX() const override;
    uint16_t getWindowY() const override;
    Color getPaletteColor(int index) const override;
    uint32_t getTileData(int index, int tileRow) const override;
    uint8_t getBackgroundData(int index) const override;
    uint8_t getWindowData(int index) const override;
    const Sprite &getSprite(int index) const override;

    void sampleAudio(float *buffer, int samples) override;
    const SquareChannel &getSquareChannel(int channel) override;

private:
    template <class t>
    static void parseRegister(t &reg, const std::string &name, const nlohmann::json &registerData);

    static std::string getCommandResponse();
    static void sendCommand(const std::string &name);

    void setBreakpoint(int index, uint32_t address);

    Sprite dummySprite{};
    SquareChannel dummySquareChannel{};

    bool halted = false;
    bool paused = false;
    bool autoUpdate = true;
    uint32_t breakpoints[FPGA_BREAKPOINTS]{};

    bool stepping = false;
    bool updatingMemory = false;
    bool updatingRegisters = false;
    std::future<std::string> responseFuture{};
};

#endif //EMULATOR_FPGA_H
