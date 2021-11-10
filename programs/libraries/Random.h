// Random --- RNG Utilities

#include "Sonic.h"

void seed_rng() {
    for (int i = 0; i < 30; i++); // A bit of delay for the ADC

    Random = ADC[0] | ADC[1] << 8 | ADC[2] << 16 | ADC[3] << 24;
}
