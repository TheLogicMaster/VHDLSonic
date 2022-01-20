#include "APU.h"

APU::APU() {
    reset();
}

void APU::sample(float *buffer, int samples) {
    for (int i = 0; i < samples; i++) {
        float mixed = 0;

        for (auto &squareChannel : squareChannels) {
            if (squareChannel.period == 0 or (squareChannel.finite and squareChannel.duration == 0))
                continue;

            squareChannel.ticks++;
            if (squareChannel.ticks >= squareChannel.period) {
                squareChannel.ticks = 0;
                squareChannel.state = !squareChannel.state;
            }

            mixed += (float)squareChannel.volume / 7 * (squareChannel.state ? -1.f : 1.f);
        }

        buffer[i] = mixed / SQUARE_CHANNELS;
    }
}

void APU::update(int delta) {
    ticks += delta;
    if (ticks >= 1000) {
        ticks = 0;

        for (auto &squareChannel : squareChannels)
            if (squareChannel.duration > 0)
                squareChannel.duration--;
    }
}

void APU::reset() {
    ticks = 0;

    for (auto &squareChannel : squareChannels)
        squareChannel = {};
}

uint32_t APU::read(uint32_t index) {
    switch (index) {
        case 0 ... SQUARE_CHANNELS: {
            auto const &channel = squareChannels[index];
            return channel.finite << 31 | channel.duration << 19 | channel.volume << 16 | channel.period;
        }
        default:
            return 0;
    }
}

void APU::write(uint32_t index, uint32_t value) {
    switch (index) {
        case 0 ... SQUARE_CHANNELS:
            squareChannels[index] = {
                 (uint16_t)(value & 0x0000FFFF),
                 (uint8_t)((value & 0x00070000) >> 16),
                 (uint16_t)((value & 0x7FF80000) >> 19),
                 (bool)(value & 0x80000000)
            };
            break;
        default:
            break;
    }
}
