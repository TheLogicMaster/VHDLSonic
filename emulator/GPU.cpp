#include <cstring>
#include "GPU.h"

GPU::GPU() {
    reset();
}

int GPU::update() {
    int interrupts = 0;
    for (int i = 0; i < DISPLAY_UPDATE_CYCLES; i++)
        interrupts |= process();
    return interrupts;
}

void GPU::reset() {
    memset(displayBuffer, 0, DISPLAY_WIDTH * DISPLAY_HEIGHT * sizeof(Color));
    row = 0;
    column = 0;

    render = false;
    horizontalScroll = 0;
    verticalScroll = 0;
    windowX = 0;
    windowY = DISPLAY_HEIGHT;
    memcpy(palette, PALETTE, PALETTE_SIZE * sizeof(Color));
    memset(tileData, 0, TILE_DATA_SIZE);
    memset(backgroundData, 0, BG_DATA_SIZE);
    memset(windowData, 0, WINDOW_DATA_SIZE);
    memset(sprites, 0,  SPRITE_COUNT * sizeof(Sprite));
}

uint8_t *GPU::getDisplayBuffer() {
    return reinterpret_cast<uint8_t *>(displayBuffer);
}

uint32_t GPU::read(uint32_t address) {
    switch (address) {
        case RENDER_ADDRESS: // Enable rendering
            return render;
        case H_SCROLL_ADDRESS: // Horizontal scroll
            return *(uint16_t *) &horizontalScroll;
        case V_SCROLL_ADDRESS: // Vertical scroll
            return *(uint8_t *) &verticalScroll;
        case WINDOW_X_ADDRESS: // Window X coord
            return windowX;
        case WINDOW_Y_ADDRESS: // Window Y coord
            return windowY;
        case PALETTE_ADDRESS ... PALETTE_ADDRESS + PALETTE_SIZE - 1: // 16 palette colors
            return palette[address - PALETTE_ADDRESS].r << 16
                | palette[address - PALETTE_ADDRESS].g << 8
                | palette[address - PALETTE_ADDRESS].b;
        case TILE_ADDRESS ... TILE_ADDRESS + TILE_DATA_SIZE - 1: // Tile data
            return tileData[(address - TILE_ADDRESS) / TILE_SIZE][(address - TILE_ADDRESS) % TILE_SIZE];
        case BG_ADDRESS ... BG_ADDRESS + BG_DATA_SIZE - 1: // Background data
            return backgroundData[address - BG_ADDRESS];
        case SPRITE_ADDRESS ... SPRITE_ADDRESS + SPRITE_COUNT - 1: // Sprite data
        {
            Sprite sprite = sprites[address - SPRITE_ADDRESS];
            return sprite.firstTile << 20
                | sprite.x << 11
                | sprite.y << 2
                | sprite.horizontalFlip << 1
                | sprite.verticalFlip;
        }
        default:
            return 0;
    }
}

void GPU::write(uint32_t address, uint32_t value) {
    switch (address) {
        case RENDER_ADDRESS: // Enable rendering
            render = value;
            break;
        case H_SCROLL_ADDRESS: // Horizontal scroll
            horizontalScroll = (int16_t) *(int32_t *) &value;
            break;
        case V_SCROLL_ADDRESS: // Vertical scroll
            verticalScroll = (int8_t) *(int32_t *) &value;
            break;
        case WINDOW_X_ADDRESS: // Window X coord
            windowX = value;
            break;
        case WINDOW_Y_ADDRESS: // Window Y coord
            windowY = value;
            break;
        case PALETTE_ADDRESS ... PALETTE_ADDRESS + PALETTE_SIZE - 1: // 16 palette colors
            palette[address - PALETTE_ADDRESS] = {
                    (uint8_t) (value >> 16),
                    (uint8_t) ((value >> 8) & 0xFF),
                    (uint8_t) (value & 0xFF)
            };
            break;
        case TILE_ADDRESS ... TILE_ADDRESS + TILE_DATA_SIZE - 1: // Tile data
            tileData[(address - TILE_ADDRESS) / TILE_SIZE][(address - TILE_ADDRESS) % TILE_SIZE] = value;
            break;
        case BG_ADDRESS ... BG_ADDRESS + BG_DATA_SIZE - 1: // Background data
            backgroundData[address - BG_ADDRESS] = value;
            break;
        case WINDOW_ADDRESS ... WINDOW_ADDRESS + WINDOW_DATA_SIZE - 1: // Window data
            windowData[address - WINDOW_ADDRESS] = value;
            break;
        case SPRITE_ADDRESS ... SPRITE_ADDRESS + SPRITE_COUNT - 1: // Sprite data
            sprites[address - SPRITE_ADDRESS] = {
                    (uint8_t) ((value >> 20) & 0xFF),
                    (uint16_t) ((value >> 11) & 0x1FF),
                    (uint8_t) ((value >> 2) & 0x1FF),
                    (bool) (value & 2),
                    (bool) (value & 1)
            };
            break;
        default:
            break;
    }
}

void GPU::drawTile(int tile, int tileX, int tileY, bool sprite) {
    int tileOffset = tileX + tileY * TILE_WIDTH;
    int paletteIndex = (tileData[tile][tileOffset / 2] >> (tileX % 2 ? 0 : 4)) & 0xF;
    if (!sprite || paletteIndex)
        displayBuffer[row][column] = palette[paletteIndex];
}

int GPU::process() {
    int interrupts = 0;

    if (!render and column < DISPLAY_WIDTH and row < DISPLAY_HEIGHT)
        displayBuffer[row][column] = {};
    else if (column < DISPLAY_WIDTH and row < DISPLAY_HEIGHT) {
        int x, y;
        int tile;

        // Background rendering
        x = column + horizontalScroll;
        if (x < 0)
            x += WORLD_WIDTH;
        y = row + verticalScroll;
        if (y < 0)
            y += WORLD_HEIGHT;
        tile = backgroundData[x / TILE_WIDTH + y / TILE_WIDTH * (WORLD_WIDTH / TILE_WIDTH)];
        drawTile(tile, x % TILE_WIDTH, y % TILE_WIDTH, false);

        // Sprite rendering
        x = column + SPRITE_OFFSET;
        y = row + SPRITE_OFFSET;
        for (auto sprite: sprites) {
            if (sprite.x > x or sprite.x + SPRITE_WIDTH - 1 < x or sprite.y > y or sprite.y + SPRITE_WIDTH - 1 < y)
                continue;
            int spriteX = x - sprite.x;
            if (sprite.horizontalFlip)
                spriteX = TILE_WIDTH - 1 - spriteX;
            int spriteY = y - sprite.y;
            if (sprite.verticalFlip)
                spriteY = TILE_WIDTH - 1 - spriteY;
            if (spriteX < TILE_WIDTH and spriteY < TILE_WIDTH)
                tile = sprite.firstTile;
            else if (spriteX >= TILE_WIDTH and spriteY < TILE_WIDTH)
                tile = sprite.firstTile + 1;
            else if (spriteX < TILE_WIDTH and spriteY >= TILE_WIDTH)
                tile = sprite.firstTile + 2;
            else
                tile = sprite.firstTile + 3;
            int tileX = spriteX % TILE_WIDTH;
            if (tileX < 0)
                tileX += TILE_WIDTH;
            int tileY = spriteY % TILE_WIDTH;
            if (tileY < 0)
                tileY += TILE_WIDTH;
            drawTile(tile, tileX, tileY, true);
        }

        // Window rendering
        x = column - windowX;
        y = row - windowY;
        if (x >= 0 and x < DISPLAY_WIDTH and y >= 0 and y < DISPLAY_HEIGHT) {
            tile = windowData[x / TILE_WIDTH + y / TILE_WIDTH * (DISPLAY_WIDTH / TILE_WIDTH)];
            drawTile(tile, x % TILE_WIDTH, y % TILE_WIDTH, false);
        }
    }

    column++;

    if (column == DISPLAY_WIDTH && row <= DISPLAY_HEIGHT)
        interrupts |= 0x8;
    else if (column >= DISPLAY_WIDTH + HBLANK) {
        column = 0;
        row++;
        if (row == DISPLAY_HEIGHT)
            interrupts |= 0x4;
        else if (row >= DISPLAY_HEIGHT + VBLANK)
            row = 0;
    }
    return interrupts;
}
