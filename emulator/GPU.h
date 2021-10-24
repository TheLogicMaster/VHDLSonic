#ifndef EMULATOR_GPU_H
#define EMULATOR_GPU_H

#define DISPLAY_WIDTH 320
#define DISPLAY_HEIGHT 240

#define HBLANK (96 + 48 + 16)
#define VBLANK (10 + 2 + 33)

#define DISPLAY_UPDATE_CYCLES 4

#define PALETTE_SIZE 16

#define WORLD_WIDTH 512
#define WORLD_HEIGHT 512

#define TILE_COUNT 256
#define TILE_SIZE 32
#define TILE_WIDTH 8

#define SPRITE_COUNT 64
#define SPRITE_WIDTH 16
#define SPRITE_OFFSET 16

#define TILE_DATA_SIZE (TILE_COUNT * TILE_SIZE)
#define BG_DATA_SIZE ((WORLD_WIDTH / TILE_WIDTH) * (WORLD_HEIGHT / TILE_WIDTH))
#define WINDOW_DATA_SIZE ((DISPLAY_WIDTH / TILE_WIDTH) * (DISPLAY_HEIGHT / TILE_WIDTH))

#define RENDER_ADDRESS 0
#define H_SCROLL_ADDRESS (RENDER_ADDRESS + 1)
#define V_SCROLL_ADDRESS (H_SCROLL_ADDRESS + 1)
#define WINDOW_X_ADDRESS (V_SCROLL_ADDRESS + 1)
#define WINDOW_Y_ADDRESS (WINDOW_X_ADDRESS + 1)
#define PALETTE_ADDRESS (WINDOW_Y_ADDRESS + 1)
#define TILE_ADDRESS (PALETTE_ADDRESS + PALETTE_SIZE)
#define BG_ADDRESS (TILE_ADDRESS + TILE_DATA_SIZE)
#define WINDOW_ADDRESS (BG_ADDRESS + BG_DATA_SIZE)
#define SPRITE_ADDRESS (WINDOW_ADDRESS + WINDOW_DATA_SIZE)

#include <cstdint>

struct Color {
    uint8_t r, g, b;
};

struct Sprite {
    uint8_t firstTile;
    uint16_t x : 9;
    uint16_t y : 9;
    bool horizontalFlip;
    bool verticalFlip;
};

static const Color PALETTE[] { // https://lospec.com/palette-list/4-bit-rgb
        {0,   0,   0},
        {50,  85,  50},
        {0,  170,  0},
        {0, 255, 0},
        {0, 0, 255},
        {0, 85, 255},
        {0, 170, 255},
        {0, 255, 255},
        {255, 0, 0},
        {255, 85, 0},
        {255, 170, 0},
        {255, 255, 0},
        {255, 0, 255},
        {255, 85, 255},
        {255, 170, 255},
        {255, 255, 255}
};

class GPU {
public:
    GPU();

    int update();
    void reset();
    uint8_t *getDisplayBuffer();
    uint32_t read(uint32_t address);
    void write(uint32_t address, uint32_t value);

private:
    void drawTile(int tile, int tileX, int tileY, bool sprite);
    int process();

    // Graphics registers
    bool render{};
    int16_t horizontalScroll{};
    int8_t verticalScroll{};
    uint16_t windowX{};
    uint8_t windowY{};
    Color palette[PALETTE_SIZE]{};
    uint8_t tileData[TILE_COUNT][TILE_SIZE]{};
    uint8_t backgroundData[BG_DATA_SIZE]{};
    uint8_t windowData[WINDOW_DATA_SIZE]{};
    Sprite sprites[SPRITE_COUNT]{};

    // Internal data
    Color displayBuffer[DISPLAY_HEIGHT][DISPLAY_WIDTH]{};
    int row{};
    int column{};
};

#endif //EMULATOR_GPU_H
