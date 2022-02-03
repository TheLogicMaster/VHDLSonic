#ifndef EMULATOR_EMULATOR_H
#define EMULATOR_EMULATOR_H

#include "GPU.h"
#include "APU.h"
#include "Computer.h"

class Emulator : public Computer {
public:
    int run(int delta) override;
    void reset() override;

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
    GPU gpu{};
    APU apu{};

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
