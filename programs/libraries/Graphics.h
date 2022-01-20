// C Graphics Utilities

#include "Sonic.h"

void set_sprite(int index, int first_tile, int x, int y, int h_flip, int v_flip) {
    Sprites[index] = first_tile << 20 | x << 11 | y << 2 | h_flip << 1 | v_flip;
}

void copy_tiles(const int* source, int first_tile, int count) {
    int offset = first_tile * 8;
        for (int i = 0; i < count * 8; i++)
            Tile_Data[i + offset] = source[i];
}

void draw_text(const char* string, int font_first_tile, int x, int y) {
    int index = x + 64 * y;
    while(*string) {
        char c = *(string++);
        int offset;
        if (c >= 'A' && c <= 'Z')
            offset = c - 'A';
        else if (c >= 'a' && c <= 'z')
            offset = c - 'a' + 26;
        else if (c >= '0' && c <= '9')
            offset = c - '0' + 52;
        else if (c >= '!' && c <= '&')
            offset = c - '!' + 62;
        else if (c == '.')
            offset = 68;
        else if (c == ',')
            offset = 69;
        else if (c == '?')
            offset = 70;
        else if (c == ':')
            offset = 71;
        else
            offset = -font_first_tile;
        BG_Data[index++] = font_first_tile + offset;
    }
}

void clear_bg() {
    for (int i = 0; i < 64 * 64; i++)
        BG_Data[i] = 0;
}
