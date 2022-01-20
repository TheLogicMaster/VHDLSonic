// Inline Asm --- An example of inlining raw assembly code in functions

#include "libraries/Sonic.h"

int main() {
    LEDs[0] = 1;
    __asm("halt ; Denied!");
    LEDs[0] = 0;
}
