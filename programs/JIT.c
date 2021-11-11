// JIT --- A just-in-time hack that runs arbitrary instructions

#include "libraries/Sonic.h"

const int jit[5] = {
    0x3E000000, // INC r0
    0x1E000000, // STR r0,[{seven_segment_0}]
    0x00040028,
    0x00000000, // BRA -16
    0xFFFFFFF0,
};

int main() {
    ((void (*)(void))&jit)(); // Basically magic
}
