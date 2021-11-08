#include "APU.h"

APU::APU() {
    reset();
}

int APU::update() {
    if (ticks++ < 20)
        return 0;

    ticks = 0;

    uint8_t wave1Sample = 0;

    if (square1Freq and (square1Repeat or square1State < square1Length * 50001 / 1000)) {
        uint32_t period = (50001 / square1Freq);
        uint32_t constrained = square1State % period;
//        int volumeOffset = square1VolumeSpeed ? square1State * square1VolumeSpeed * 255 / (50001) : 0;
//        uint8_t volume = std::max(0, std::min(0xFF, square1VolumeInc
//            ? square1VolumeInit + volumeOffset : square1VolumeInit - volumeOffset));
        uint8_t volume = 0xFF;
        wave1Sample = constrained > period * WAVE_DUTY[square1Duty] / 16 ? 0 : volume;
        square1State++;
    }

    samples.push(wave1Sample);

    return 0;
}

void APU::reset() {
    std::queue<uint8_t>().swap(samples);
    ticks = 0;

//    square1State = 0;
//    square1Freq = 100;
//    square1Duty = 3;
//    square1Length = 1000;
//    square1Repeat = true;
//    square1VolumeInit = 255;
//    square1VolumeInc = false;
//    square1VolumeSpeed = 1;
}

std::queue<uint8_t> &APU::getSamples() {
    return samples;
}

uint32_t APU::read(uint32_t address) {
    return 0;
}

void APU::write(uint32_t address, uint32_t value) {

}
