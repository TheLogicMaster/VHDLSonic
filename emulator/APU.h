#ifndef EMULATOR_APU_H
#define EMULATOR_APU_H

#define SQUARE_CHANNELS 3

#include <cstdint>
#include <queue>

struct SquareChannel {
    uint16_t period;
    uint8_t volume;
    uint16_t duration;
    bool finite;
    uint16_t ticks;
    bool state;
};

class APU {
public:
    APU();

    void reset();
    void sample(float *buffer, int samples);
    void update(int delta);
    uint32_t read(uint32_t index);
    void write(uint32_t index, uint32_t value);

private:
    SquareChannel squareChannels[SQUARE_CHANNELS]{};
    int ticks{};
};

#endif //EMULATOR_APU_H
