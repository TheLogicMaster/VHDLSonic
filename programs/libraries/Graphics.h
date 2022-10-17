// C Graphics Utilities

#include "Sonic.h"

#pragma include "libraries/Graphics.asm"

void set_sprite(int index, int first_tile, int x, int y, int h_flip, int v_flip) =
    "\tldr r0,sp,-4\n"
    "\tldr r1,sp,-8\n"
    "\tldr r2,sp,-12\n"
    "\tldr r3,sp,-16\n"
    "\tldr r4,sp,-20\n"
    "\tldr r5,sp,-24\n"
    "\tjsr set_sprite";

void copy_tiles(const int* source, int first_tile, int count) =
    "\tldr r0,sp,-4\n"
    "\tldr r1,sp,-8\n"
    "\tldr r2,sp,-12\n"
    "\tjsr copy_tiles";

void draw_text(const char* string, int font_first_tile, int x, int y) =
    "\tldr r0,sp,-4\n"
    "\tldr r3,sp,-8\n"
    "\tldr r1,sp,-12\n"
    "\tldr r2,sp,-16\n"
    "\tjsr draw_text";

#define clear_bg clear_bg_data
void clear_bg_data() = "\tjsr clear_bg_data";

void clear_win_data() = "\tjsr clear_win_data";

void clear_tile_data() = "\tjsr clear_tile_data";

void clear_sprites() = "\tjsr clear_sprites";
