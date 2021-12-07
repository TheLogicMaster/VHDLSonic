// Snake in C

#include "libraries/Sonic.h"
#include "libraries/Graphics.h"

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

int apple_x, apple_y;
int snake_x, snake_y;
int size;
int can_render;
char segments[62];

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

int check_body_collision(int x, int y) {
    int current_x = x;
    int current_y = y;

    for (int i = 0; i < size; i++) {
        if (segments[i] == 0)
            current_x += 1;
        else if (segments[i] == 1)
            current_y += 1;
        else if (segments[i] == 2)
            current_x -= 1;
        else
            current_y -= 1;
        if (x == current_x && y == current_y)
            return 1;
    }

    return 0;
}

void generate_apple() {
    int x, y;

    while (1) {
        x = (Random & 0xFF) % 40;
        y = (Random & 0xFF) % 30;

        if (snake_x == x && snake_y == y)
            continue;

        if (!check_body_collision(x, y))
            break;
    }

    apple_x = x;
    apple_y = y;
}

void snake_game() {
    segments[0] = 2;
    segments[1] = 2;
    size = 2;
    snake_x = 4;
    snake_y = 4;
    int input = 0;

    generate_apple();

    while(1) {
        can_render = 1;

        // Movement delay
        for(int i = 0; i < 5000; i++) {
            int polled = poll_controls();
            if (polled && (!input || polled - 1 != (input - 1 + 2) % 4))
                input = polled;
        }

        can_render = 0;

        // Move snake
        int direction = input ? input - 1 : (segments[0] + 2) % 4;
        if (direction == 0)
            snake_x += 1;
        else if (direction == 1)
            snake_y += 1;
        else if (direction == 2)
            snake_x -= 1;
        else
            snake_y -= 1;
        if (check_body_collision(snake_x, snake_y) || snake_x < 0 || snake_x >= 40 || snake_y < 0 || snake_y >= 30)
            return;
        int needs_apple = 0;
        if (apple_x == snake_x && apple_y == snake_y) {
            size++;
            if (size > 62)
                return;
            needs_apple = 1;
        }
        int shift = (direction + 2) % 4;
        for (int i = 0; i < size; i++) {
            int temp = segments[i];
            segments[i] = shift;
            shift = temp;
        }
        if (needs_apple)
            generate_apple();
    }
}

int main() {
    IE |= 0x4; // Enable VBlank interrupt
    sei();

    // Set Background Data
    for (int i = 0; i < 8; i++)
        Tile_Data[i] = 0x55555555;
    copy_tiles(apple, 1, 1);
    copy_tiles(snake_body, 5, 1);
    copy_tiles(snake_head, 9, 1);
    for (int i = 0; i < 100 - 1; i += 2)
        BG_Data[snake_title[i] + 2 + 64 * (snake_title[i + 1] + 1)] = 5;
    BG_Data[5 + 64 * 3] = 9;

    // Enable rendering
    Render = 1;

    // Game loop
    while (1) {
        // Title screen
        H_Scroll = 0;

        can_render = 0;

        // Clear sprites
        for (int i = 0; i < 64; i++)
            Sprites[i] = 0;

        // Wait for input to start game
        while(poll_controls());
        while(!poll_controls());

        // Set BG scroll for play field
        H_Scroll = -320;

        snake_game();
    }
}

void vblank() {
    if (!can_render)
        return;

    set_sprite(0, 1, apple_x * 8 + 16, apple_y * 8 + 16, 0, 0);
    set_sprite(1, 9, snake_x * 8 + 16, snake_y * 8 + 16, 0, 0);
    int current_x = snake_x;
    int current_y = snake_y;
    for (int i = 0; i < size; i++) {
        if (segments[i] == 0)
            current_x += 1;
        else if (segments[i] == 1)
            current_y += 1;
        else if (segments[i] == 2)
            current_x -= 1;
        else
            current_y -= 1;

        set_sprite(2 + i, 5, current_x * 8 + 16, current_y * 8 + 16, 0, 0);
    }
}
