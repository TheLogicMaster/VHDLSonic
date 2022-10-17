// Tetris

#include "libraries/Sonic.h"
#include "libraries/Graphics.h"
#include "libraries/Print.h"

#include "data/tiles/tetris_block.h"
#include "data/tiles/font.h"

#define GRID_WIDTH 10
#define GRID_HEIGHT 15
#define FONT_INDEX 100

const char I_PIECE[2][16] = {
    { // Rotation 0
        0, 0, 0, 0,
        1, 1, 1, 1,
        0, 0, 0, 0,
        0, 0, 0, 0,
    },
    { // Rotation 1
        0, 0, 1, 0,
        0, 0, 1, 0,
        0, 0, 1, 0,
        0, 0, 1, 0,
    }
};

const char T_PIECE[4][16] = {
    { // Rotation 0
        0, 0, 0, 0,
        1, 1, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    },
    { // Rotation 1
        0, 1, 0, 0,
        1, 1, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    },
    { // Rotation 2
        0, 0, 0, 0,
        0, 1, 0, 0,
        1, 1, 1, 0,
        0, 0, 0, 0,
    },
    { // Rotation 3
        0, 1, 0, 0,
        0, 1, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    }
};

const char L_PIECE[4][16] = {
    { // Rotation 0
        0, 0, 0, 0,
        1, 1, 1, 0,
        1, 0, 0, 0,
        0, 0, 0, 0,
    },
    { // Rotation 1
        1, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    },
    { // Rotation 2
        0, 0, 0, 0,
        0, 0, 1, 0,
        1, 1, 1, 0,
        0, 0, 0, 0,
    },
    { // Rotation 3
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
    }
};

const char J_PIECE[4][16] = {
    { // Rotation 0
        0, 0, 0, 0,
        1, 1, 1, 0,
        0, 0, 1, 0,
        0, 0, 0, 0,
    },
    { // Rotation 1
        0, 1, 0, 0,
        0, 1, 0, 0,
        1, 1, 0, 0,
        0, 0, 0, 0,
    },
    { // Rotation 2
        0, 0, 0, 0,
        1, 0, 0, 0,
        1, 1, 1, 0,
        0, 0, 0, 0,
    },
    { // Rotation 3
        0, 1, 1, 0,
        0, 1, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    }
};

const char S_PIECE[2][16] = {
    { // Rotation 0
        0, 0, 0, 0,
        0, 1, 1, 0,
        1, 1, 0, 0,
        0, 0, 0, 0,
    },
    { // Rotation 1
        1, 0, 0, 0,
        1, 1, 0, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    }
};

const char Z_PIECE[2][16] = {
    { // Rotation 0
        0, 0, 0, 0,
        1, 1, 0, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
    },
    { // Rotation 1
        0, 0, 1, 0,
        0, 1, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 0,
    }
};

const char O_PIECE[1][16] = {
    { // Rotation 0
        0, 0, 0, 0,
        0, 1, 1, 0,
        0, 1, 1, 0,
        0, 0, 0, 0,
    }
};

const char PIECE_ROTATIONS[7] = {2, 4, 4, 4, 2, 2, 1};

const int SCORING[4] = {40, 100, 300, 1200};

const int STATE_TITLE = 0;
const int STATE_GAME = 1;
const int STATE_DEAD = 2;

int state;
int score;
int last_direction;
int piece;
int x;
int y;
int rotation;
char grid[GRID_HEIGHT][GRID_WIDTH];

//int poll_controls() {
//    if (GPIO[13]) // D
//        return 1;
//    if (GPIO[11]) // S
//        return 2;
//    if (GPIO[12]) // A
//        return 3;
//    if (GPIO[10]) // W
//        return 4;
//    return 0;
//}

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

void draw_title_screen() {
    clear_bg();
    draw_text("Tetris", FONT_INDEX, 17, 10);
    draw_text("Press any key", FONT_INDEX, 13, 13);
}

void reset_piece() {
    piece = (Random & 0x7) % 7;
    x = 3;
    y = 0;
    rotation = 0;
}

int get_block(int block_x, int block_y) {
    int index = block_x + block_y * 4;
    switch (piece) {
        case 0:
            return I_PIECE[rotation][index];
        case 1:
            return T_PIECE[rotation][index];
        case 2:
            return L_PIECE[rotation][index];
        case 3:
            return J_PIECE[rotation][index];
        case 4:
            return S_PIECE[rotation][index];
        case 5:
            return Z_PIECE[rotation][index];
        case 6:
            return O_PIECE[rotation][index];
        default:
            return 1;
    }
}

int check_collision(int piece_x, int piece_y) {
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            if (get_block(i, j) && (piece_x + i >= GRID_WIDTH || piece_y + j >= GRID_HEIGHT || piece_x + i < 0 || grid[piece_y + j][piece_x + i]))
                return 1;
    return 0;
}

void draw_score() {
    char buffer[20];
    sprintf(buffer, "Score: %i", score);
    draw_text(buffer, FONT_INDEX, 20, 4);
}

void play_game() {
    // Reset game
    score = 0;
    last_direction = poll_controls();
    reset_piece();
    for (int i = 0; i < GRID_HEIGHT; i++)
        for (int j = 0; j < GRID_WIDTH; j++)
            grid[i][j] = 0;

    // Draw play field
    clear_bg();
    for (int i = 0; i <= GRID_WIDTH; i++)
        BG_Data[i + 1 + GRID_HEIGHT * 64] = 1;
    for (int i = 0; i <= GRID_HEIGHT; i++) {
        BG_Data[i * 64] = 1;
        BG_Data[GRID_WIDTH + 1 + i * 64] = 1;
    }

    draw_score();

    while (1) {
        // Delay loop
        for (int i = 0; i < 5000; i++) {
            int dir = poll_controls();
            if (dir != last_direction && dir % 2) {
                if (GPIO[0]) {
                    int old_rot = rotation;
                    rotation += dir == 1 ? 1 : -1;
                    if (rotation < 0)
                        rotation = PIECE_ROTATIONS[piece] - 1;
                    else if (rotation >= PIECE_ROTATIONS[piece])
                        rotation = 0;
                    if (check_collision(x, y))
                        rotation = old_rot;
                } else {
                    int move = dir == 1 ? 1 : -1;
                    if (!check_collision(x + move, y))
                        x += move;
                }
                for (int j = 0; j < 100; j++); // Debounce delay
            }
            last_direction = dir;
            if (dir == 2 && i > 1000)
                break;
        }

        if (check_collision(x, y + 1)) {
            // Place piece
            for (int i = 0; i < 4; i++)
                for (int j = 0; j < 4; j++)
                    if (get_block(j, i)) {
                        grid[y + i][x + j] = 1;
                        BG_Data[x + 1 + j + (y + i) * 64] = 5 + piece * 4;
                    }

            // Check for rows
            int rows = 0;
            for (int i = 3; i >= 0; i--) {
                if (y + i + rows >= GRID_HEIGHT)
                    continue;
                int incomplete = 0;
                for (int j = 0; j < GRID_WIDTH; j++)
                    if (!grid[y + i + rows][j])
                        incomplete = 1;
                if (!incomplete) {
                    for (int j = y + i + rows; j > 0; j--) {
                        for (int k = 0; k < GRID_WIDTH; k++) {
                            grid[j][k] = grid[j - 1][k];
                            BG_Data[k + 1 + j * 64] = BG_Data[k + 1 + (j - 1) * 64];
                            grid[j - 1][k] = 0;
                            BG_Data[k + 1 + (j - 1) * 64] = 0;
                        }
                    }
                    rows++;
                }
            }
            if (rows) {
                score += SCORING[rows - 1];
                draw_score();
            }

            reset_piece();
            if (check_collision(x, y))
                break;
        } else
            y++;
    }

    // Game over screen
    draw_text("Game Over!", FONT_INDEX, 20, 8);
    state = STATE_DEAD;
    while(poll_controls());
    while(!poll_controls());
}

int main() {
    IE |= 0x4; // Enable VBlank interrupt
    sei(); // Global interrupt enable

    // Load graphics data
    copy_tiles(tetris_block, 1, 1);
    copy_tiles(font, FONT_INDEX, 72);

    // Load color variations
    for (int i = 0; i < 7; i++)
        for (int j = 0; j < 8; j++) {
            int data = 0x11111111;
            for (int k = 0; k < 8; k++)
                data |= (i + 1) << (1 + 4 * k);
            Tile_Data[j + 8 * (5 + i * 4)] = Tile_Data[j + 8] & data;
        }

    // Game loop
    while (1) {
        Render = 0; // Disable rendering

        state = STATE_TITLE;

        // Clear sprites
        for (int i = 0; i < 4; i++)
            Sprites[i] = 0;

        draw_title_screen();

        Render = 1; // Enable rendering

        // Wait for input to start game
        while(poll_controls());
        while(!poll_controls());

        state = STATE_GAME;
        play_game();
    }
}

void vblank() {
    if (state == STATE_GAME) {
        int sprite = 0;
        for (int i = 0; i < 4; i++)
            for (int j = 0; j < 4; j++)
                if (get_block(i, j)) {
                    set_sprite(sprite, 5 + piece * 4, (x + i + 1) * 8 + 16, (y + j) * 8 + 16, 0, 0);
                    sprite++;
                }
    }
}
