// Inline Asm --- An example of inlining raw assembly code in functions

#include "libraries/Sonic.h"

void inline_asm() = "halt ; Denied!";

int main() {
    LEDs[0] = 1;
    inline_asm();
    LEDs[0] = 0;
}
