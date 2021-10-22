// C Graphics Utilities

extern int Render;
extern int H_Scroll, V_Scroll;
extern int Window_X, Window_Y;
extern int Palette[16];
extern int Tile_Data[256 * 32];
extern int BG_Data[64 * 64];
extern int Win_Data[40 * 30];
extern int Sprites[32];

void set_sprite(int index, int first_tile, int x, int y, int h_flip, int v_flip) {
    Sprites[index] = first_tile << 20 | x << 11 | y << 2 | h_flip << 1 | v_flip;
}

void copy_tiles(const char* source, int first_tile, int count) {
    int offset  = first_tile * 32;
    for (int i = 0; i < count * 32; i++)
        Tile_Data[i + offset] = source[i];
}
