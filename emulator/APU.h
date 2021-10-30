#ifndef EMULATOR_APU_H
#define EMULATOR_APU_H

#define AUDIO_BUFFER 4096

#include <cstdint>
#include <queue>

const uint8_t WAVE_DUTY[4]{2, 4, 8, 12};

class APU {
public:
    APU();

    int update();
    void reset();
    std::queue<uint8_t> &getSamples();
    uint32_t read(uint32_t address);
    void write(uint32_t address, uint32_t value);

private:
    std::queue<uint8_t> samples{};
    uint8_t ticks{};

    uint32_t square1State{};
    uint32_t square1Freq{};
    uint8_t square1Duty{};
    uint16_t square1Length{};
    bool square1Repeat{};
//    uint8_t square1SweepTime{};
//    bool square1SweepInc{};
//    uint8_t square1SweepDelta{};
//    uint8_t square1VolumeInit{};
//    bool square1VolumeInc{};
//    uint8_t square1VolumeSpeed{};
};

#endif //EMULATOR_APU_H
