// Switches and LEDs

#include "libraries/Sonic.h"

int main() {
    Arduino_Modes[0] = Arduino_Modes[1] = 1;

    while (1){
        Arduino[0] = Switches[0];
        Arduino[1] = Switches[1];
    }
}
