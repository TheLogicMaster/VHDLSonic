// HBlank based animation using Snake title screen

#include "libraries/Sonic.h"
#include "libraries/Graphics.h"

#include "data/sin.h"

#include "data/tiles/snake_body.h"
#include "data/tiles/snake_head.h"
#include "data/tiles/apple.h"

const unsigned char snake_title[100] = {
    0, 6, 1, 7, 2, 7, 3, 6, 3, 5, 2, 4, 1, 4, 0, 3, 0, 2, 1, 1, 2, 1, // S
    5, 7, 5, 6, 5, 5, 5, 4, 5, 3, 6, 4, 7, 5, 7, 6, 7, 7, // N
    9, 7, 9, 6, 9, 5, 9, 4, 10, 5, 10, 3, 11, 7, 11, 6, 11, 5, 11, 4, // A
    13, 2, 13, 3, 13, 4, 13, 5, 13, 6, 13, 7, 14, 6, 15, 7, 15, 5, 15, 4, // K
    17, 3, 17, 4, 17, 5, 17, 6, 17, 7, 18, 3, 19, 3, 18, 5, 18, 7, 19, 7, // E
};

int rowIndex;
int buffer0[241];
int buffer1[241];
int *fill;
int *empty;
int filled = 1;

int main() {
    fill = buffer0;
    empty = buffer1;

    IE |= 0x4 | 0x8;
    sei();

    // Set Background Data
    for (int i = 0; i < 32; i++)
        Tile_Data[i] = 0x55;
    copy_tiles(apple, 1, 1);
    copy_tiles(snake_body, 5, 1);
    copy_tiles(snake_head, 9, 1);
    for (int i = 0; i < 100 - 1; i += 2)
        BG_Data[snake_title[i] + 10 + 64 * (snake_title[i + 1] + 1)] = 5;
    BG_Data[13 + 64 * 3] = 9;
    for (int i = 0; i < 100 - 1; i += 2)
        BG_Data[snake_title[i] + 10 + 64 * (snake_title[i + 1] + 9)] = 5;
    BG_Data[13 + 64 * 11] = 9;
    for (int i = 0; i < 100 - 1; i += 2)
        BG_Data[snake_title[i] + 10 + 64 * (snake_title[i + 1] + 17)] = 5;
    BG_Data[13 + 64 * 19] = 9;

    Render = 1;

    unsigned char time = 0;

    while(1) {
        if (filled)
            continue;

        for (int i = 0; i < 241; i++)
            fill[i] = (SIN_TABLE[(i + time) % 256] - 127) >> 2;
        time += 2;

        filled = 1;
    }
}

void vblank() {
    int *temp = fill;
    fill = empty;
    empty = temp;
    filled = 0;
    rowIndex = 0;
    H_Scroll = empty[rowIndex++];
}

void hblank() {
    H_Scroll = empty[rowIndex++];
}
