// Flappy Bird

#include "libraries/Sonic.h"

unsigned int velocity;
unsigned int height;

int poll_controls() {
    if (GPIO[3]) // D
        return 1;
    if (GPIO[1]) // S
        return 2;
    if (GPIO[2]) // A
        return 3;
    if (GPIO[0]) // W
        return 4;
    return 0;
}

void clear_bg() {
    for (int i = 0; i < 64 * 64; i++)
        BG_Data[i] = 0;
}

void game() {
    clear_bg();
    H_Scroll = 0;

    while(1) {

    }
}

int main() {
    copy_tiles(snake_head, 1, 4);

    // Enable rendering
    Render = 1;

    sei();
    IE |= 0x4; // Enable VBlank interrupt

    game();
}

void vblank() {

}
