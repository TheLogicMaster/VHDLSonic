// Dice --- Roll some dice on the seven segment displays on Button 1

#include "libraries/Sonic.h"
#include "libraries/Random.h"

int main() {
    seed_rng();

    while (1) {
        for (int i = 0; i < 6; i++)
            Seven_Segment[i] = 1 + (Random & 0xF) % 6;

        while(Buttons[1]);
        while(!Buttons[1]);
    }
}
