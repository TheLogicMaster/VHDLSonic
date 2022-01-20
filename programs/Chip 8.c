// Chip 8

#include "libraries/Sonic.h"
#include "libraries/Graphics.h"
#include "libraries/Delay.h"

#include "data/tiles/tetris_block.h"
#include "data/tiles/selection_arrow.h"
#include "data/tiles/font.h"

#include "data/chip8/binding.ch8.h"
#include "data/chip8/blinky.ch8.h"
#include "data/chip8/blitz.ch8.h"
#include "data/chip8/br8kout.ch8.h"
#include "data/chip8/brix.ch8.h"
#include "data/chip8/cell1d.ch8.h"
#include "data/chip8/chipquarium.ch8.h"
#include "data/chip8/connect4.ch8.h"
#include "data/chip8/danm8ku.ch8.h"
#include "data/chip8/dodge.ch8.h"
#include "data/chip8/down8.ch8.h"
#include "data/chip8/dvn8.ch8.h"
#include "data/chip8/eaty.ch8.h"
#include "data/chip8/flightrunner.ch8.h"
#include "data/chip8/flutterby.ch8.h"
#include "data/chip8/guess.ch8.h"
#include "data/chip8/hidden.ch8.h"
#include "data/chip8/horseyjump.ch8.h"
#include "data/chip8/invaders.ch8.h"
#include "data/chip8/kaleid.ch8.h"
#include "data/chip8/knight.ch8.h"
#include "data/chip8/maze.ch8.h"
#include "data/chip8/merlin.ch8.h"
#include "data/chip8/missile.ch8.h"
#include "data/chip8/octoachip8story.ch8.h"
#include "data/chip8/octogon.ch8.h"
#include "data/chip8/octopeg.ch8.h"
#include "data/chip8/ordinaryidlegarden.ch8.h"
#include "data/chip8/petdog.ch8.h"
#include "data/chip8/piper.ch8.h"
#include "data/chip8/pong.ch8.h"
#include "data/chip8/pong2.ch8.h"
#include "data/chip8/puzzle.ch8.h"
#include "data/chip8/puzzle15.ch8.h"
#include "data/chip8/rockto.ch8.h"
#include "data/chip8/rps.ch8.h"
#include "data/chip8/snake.ch8.h"
#include "data/chip8/snek.ch8.h"
#include "data/chip8/spacejam.ch8.h"
#include "data/chip8/sub8.ch8.h"
#include "data/chip8/supersquare.ch8.h"
#include "data/chip8/sysygy.ch8.h"
#include "data/chip8/tank.ch8.h"
#include "data/chip8/tetris.ch8.h"
#include "data/chip8/tictac.ch8.h"
#include "data/chip8/trucksimul8or.ch8.h"
#include "data/chip8/ufo.ch8.h"
#include "data/chip8/ultimatetictactoe.ch8.h"
#include "data/chip8/vbrix.ch8.h"
#include "data/chip8/vers.ch8.h"
#include "data/chip8/wipeoff.ch8.h"

#define ROM(rom) rom,sizeof(rom)

struct Rom {
    char *name;
    const char *data;
    int size;
};

const char chip8_font[80] = {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80  // F
};

int playing;
int rom_selection;
char display_buffer[32 * 16];

unsigned char memory[4096];
unsigned short pc;
unsigned char sp;
unsigned char delay_timer;
unsigned char sound_timer;
unsigned short previous_keys;
unsigned short stack[16];
unsigned char v_registers[16];
unsigned short reg_i;

void draw(int x, int y, int height) {
    for (int sprite_y = 0; sprite_y < height; sprite_y++) {
        int line = memory[reg_i + sprite_y];
        unsigned char pixel_y = y + sprite_y;
        if (pixel_y >= 32)
            continue;
        for (int sprite_x = 0; sprite_x < 8; sprite_x++) {
            if (!(line & 0x80 >> sprite_x))
                continue;
            unsigned char pixel_x = x + sprite_x;
            if (pixel_x >= 64)
            continue;
            int tile = pixel_y / 2 * 32 + pixel_x / 2;
            int mask = 1 << ((pixel_x % 2) + 2 * (pixel_y % 2));
            if (display_buffer[tile] & mask) {
                v_registers[0xF] = 1;
                display_buffer[tile] &= ~mask;
            } else
                display_buffer[tile] |= mask;
        }
    }
}

void run() {
    int keys = 0;
    for (int i = 0; i < 16; i++)
        keys |= GPIO[i] << i;
    int pressed = keys & ~previous_keys;
    previous_keys = keys;

    if (delay_timer > 0)
        delay_timer--;

    // Todo: Play tone when (sound_timer > 0)
    if (sound_timer > 0)
        sound_timer--;

    int opcode = memory[pc] << 8 | memory[pc + 1];
    pc += 2;

    int address = opcode & 0x0FFF;
    int top_nibble = opcode & 0xF000;
    int low_byte = opcode & 0x00FF;
    int nibble = opcode & 0x000F;
    int x_var = (opcode & 0x0F00) >> 8;
    int y_var = (opcode & 0x00F0) >> 4;

    if (opcode == 0x00E0) { // CLS --- Clear the display
        for (int i = 0; i < 32 * 16; i++)
            display_buffer[i] = 0;
    } else if (opcode == 0x00EE) { // RET --- Return from subroutine
        pc = stack[--sp];
    } else if (top_nibble == 0x1000) { // JP --- Jump to address at nnn
        pc = address;
    } else if (top_nibble == 0x2000) { // CALL addr --- Call subroutine at nnn
        stack[sp++] = pc;
        pc = address;
    } else if (top_nibble == 0x3000) { // SE Vx, byte --- Skip next instruction if Vx = kk
        if (v_registers[x_var] == low_byte)
            pc += 2;
    } else if (top_nibble == 0x4000) { // SNE Vx, byte --- Skip next instruction if Vx != kk
        if (v_registers[x_var] != low_byte)
            pc += 2;
    } else if (top_nibble == 0x5000) { // SE Vx, Vy --- Skip next instruction if Vx = Vy
        if (v_registers[x_var] == v_registers[y_var])
            pc += 2;
    } else if (top_nibble == 0x6000) { // LD Vx, byte --- Loads immediate kk into Vx
        v_registers[x_var] = low_byte;
    } else if (top_nibble == 0x7000) { // ADD Vx, byte --- Adds immediate kk to Vx
        v_registers[x_var] += low_byte;
    } else if (top_nibble == 0x8000) { // Variable register operations
        if (nibble == 0x0) { // LD Vx, Vy --- Load Vy into Vx
            v_registers[x_var] = v_registers[y_var];
        } else if (nibble == 0x1) { // OR Vx, Vy --- Performs bitwise OR on Vx with Vy
            v_registers[x_var] |= v_registers[y_var];
        } else if (nibble == 0x2) { // AND Vx, Vy --- Performs bitwise AND on Vx with Vy
            v_registers[x_var] &= v_registers[y_var];
        } else if (nibble == 0x3) { // XOR Vx, Vy --- Performs bitwise XOR on Vx with Vy
            v_registers[x_var] ^= v_registers[y_var];
        } else if (nibble == 0x4) { // ADD Vx, Vy --- Adds Vy to Vx and sets VF to the carry
            v_registers[0xF] = v_registers[x_var] + v_registers[y_var] > 0xFF;
            v_registers[x_var] += v_registers[y_var];
        } else if (nibble == 0x5) { // SUB Vx, Vy --- Subtracts Vy from Vx and sets VF to NOT borrow
            v_registers[0xF] = v_registers[x_var] >= v_registers[y_var];
            v_registers[x_var] -= v_registers[y_var];
        } else if (nibble == 0x6) { // SHR Vx --- Bitwise shift Vx right and sets VF to the shift-out
            v_registers[0xF] = v_registers[x_var] & 0x1;
            v_registers[x_var] >>= 1;
        } else if (nibble == 0x7) { // SUBN Vx, Vy --- Assigns "Vy - Vx" to Vx and VF to NOT borrow
            v_registers[0xF] = v_registers[x_var] <= v_registers[y_var];
            v_registers[x_var] = v_registers[y_var] - v_registers[x_var];
        } else if (nibble == 0xE) { // SHL Vx --- Bitwise shift Vx left and sets VF to the shift-out
            v_registers[0xF] = (v_registers[x_var] & 0x80) != 0;
            v_registers[x_var] <<= 1;
        }
    } else if (top_nibble == 0x9000) { // SNE Vx, Vy --- Skip next instruction if Vx != Vy
        if (v_registers[x_var] != v_registers[y_var])
            pc += 2;
    } else if (top_nibble == 0xA000) { // LD I, addr --- Loads immediate nnn into I
        reg_i = address;
    } else if (top_nibble == 0xB000) { // JP V0, addr --- Jump to address nnn + V0
        pc = address + v_registers[0x0];
    } else if (top_nibble == 0xC000) { // RND Vx, byte --- Set Vx to a random byte AND immediate kk
        v_registers[x_var] = Random & low_byte;
    } else if (top_nibble == 0xD000) { // DRW Vx, Vy, nibble --- Draw immediate n byte sprite starting at I and set VF to Collision
        draw(v_registers[x_var] % 64, v_registers[y_var] % 32, nibble);
    } else if (top_nibble == 0xE000) { // Keyboard instructions
        if (low_byte == 0x9E) { // SKP Vx --- Skip the next instruction if key Vx is pressed
            if (keys & 1 << v_registers[x_var])
                pc += 2;
        } else if (low_byte == 0xA1) { // SKNP Vx --- Skip the next instruction if key Vx is not pressed
            if ((keys & 1 << v_registers[x_var]) == 0)
                pc += 2;
        }
    } else if (top_nibble == 0xF000) { // Vx operations
        if (low_byte == 0x07) { // LD Vx, DT --- Assign Delay Timer to Vx
            v_registers[x_var] = delay_timer;
        } else if (low_byte == 0x0A) { // LD Vx, K --- Wait for key press and store key value in Vx
            if (pressed) {
                for (int i = 0; i < 16; i++)
                    if (pressed & 1 << i)
                        v_registers[x_var] = i;
            } else
                pc -= 2;
        } else if (low_byte == 0x15) { // LD DT, Vx --- Assign Vx to Delay Timer
            delay_timer = v_registers[x_var];
        } else if (low_byte == 0x18) { // LD ST, Vx --- Assign Vx to Sound Timer
            sound_timer = v_registers[x_var];
        } else if (low_byte == 0x1E) { // ADD I, Vx --- Adds Vx to I
            reg_i += v_registers[x_var];
            v_registers[0xF] = reg_i > 0xFFF;
        } else if (low_byte == 0x29) { // LD F, Vx --- Assign font digit address for digit Vx to I
            reg_i = v_registers[x_var] * 5;
        } else if (low_byte == 0x33) { // LD B, Vx --- Store BCD representation of Vx at I, "I + 1", and "I + 2"
            memory[reg_i] = v_registers[x_var] / 100;
            memory[reg_i + 1] = (v_registers[x_var] / 10) % 10;
            memory[reg_i + 2] = v_registers[x_var] % 10;
        } else if (low_byte == 0x55) { // LD [I], Vx --- Stores V0 through Vx in memory starting at I
            for (int i = 0; i <= x_var; i++)
                memory[reg_i + i] = v_registers[i];
            reg_i += v_registers[x_var] + 1;
        } else if (low_byte == 0x65) { // LD Vx, [I] --- Loads V0 through Vx from memory locations starting at I
            for (int i = 0; i <= x_var; i++)
                v_registers[i] = memory[reg_i + i];
            reg_i += v_registers[x_var] + 1;
        }
    }
}

int main() {
    for (int i = 0; i < 16; i++)
        for (int j = 0; j < 8; j++) {
            int value;
            if (j < 4)
                value = ((i & 1) >> 0) * 0x33330000 | ((i & 2) >> 1) * 0x00003333;
            else
                value = ((i & 4) >> 2) * 0x33330000 | ((i & 8) >> 3) * 0x00003333;
            Tile_Data[i * 8 + j] = value;
        }

    copy_tiles(tetris_block, 16, 1);
    copy_tiles(SELECTION_ARROW, 17, 1);
    copy_tiles(font, 100, 72);

    struct Rom roms[] = {
        {"Binding", ROM(BINDING)},
        {"Blinky", ROM(BLINKY)},
        {"Blitz", ROM(BLITZ)},
        {"Br8kout", ROM(BR8KOUT)},
        {"Brix", ROM(BRIX)},
        {"1D Cellular Automata", ROM(CELL1D)},
        {"Chipquarium", ROM(CHIPQUARIUM)},
        {"Connect 4", ROM(CONNECT4)},
        {"Danm8ku", ROM(DANM8KU)},
        {"Dodge", ROM(DODGE)},
        {"Down 8", ROM(DOWN8)},
        {"DVN8", ROM(DVN8)},
        {"Eaty", ROM(EATY)},
        {"Flight Runner", ROM(FLIGHTRUNNER)},
        {"Flutterby", ROM(FLUTTERBY)},
        {"Guess", ROM(GUESS)},
        {"Hidden", ROM(HIDDEN)},
        {"Horsey Jump", ROM(HORSEYJUMP)},
        {"Invaders", ROM(INVADERS)},
        {"Kaleid", ROM(KALEID)},
        {"Knight", ROM(KNIGHT)},
        {"Maze", ROM(MAZE)},
        {"Merlin", ROM(MERLIN)},
        {"Missile", ROM(MISSILE)},
        {"Octo: a Chip 8 Story", ROM(OCTOACHIP8STORY)},
        {"Super Octogon", ROM(OCTOGON)},
        {"Octopeg", ROM(OCTOPEG)},
        {"Ordinary Idle Garden", ROM(ORDINARYIDLEGARDEN)},
        {"Pet Dog", ROM(PETDOG)},
        {"Piper", ROM(PIPER)},
        {"Pong", ROM(PONG)},
        {"Pong 2", ROM(PONG2)},
        {"Puzzle", ROM(PUZZLE)},
        {"15 Puzzle", ROM(PUZZLE15)},
        {"Rockto", ROM(ROCKTO)},
        {"Rock Paper Scissors", ROM(RPS)},
        {"Snake", ROM(SNAKE)},
        {"Snek", ROM(SNEK)},
        {"Spacejam!", ROM(SPACEJAM)},
        {"Sub8", ROM(SUB8)},
        {"Super Square", ROM(SUPERSQUARE)},
        {"Sysygy", ROM(SYSYGY)},
        {"Tank", ROM(TANK)},
        {"Tetris", ROM(TETRIS)},
        {"Tic-tac-toe", ROM(TICTAC)},
        {"Truck Simul8or", ROM(TRUCKSIMUL8OR)},
        {"UFO", ROM(UFO)},
        {"Ultimate Tic-tac-toe", ROM(ULTIMATETICTACTOE)},
        {"Vbrix", ROM(VBRIX)},
        {"Vers", ROM(VERS)},
        {"Wipeoff", ROM(WIPEOFF)}
    };
    int rom_count = sizeof(roms) / sizeof(struct Rom);

    clear_bg();
    for (int i = 0; i < rom_count; i++)
        draw_text(roms[i].name, 100, 3, i);

    IE |= 0x4; // Enable VBlank interrupt
    sei(); // Global interrupt enable
    Render = 1; // Enable GPU rendering

    while(1) {
        if (GPIO[9]) {
            while(GPIO[9]);
            break;
        } else if (GPIO[8] && rom_selection < rom_count - 1) {
            rom_selection++;
            sleep_millis(150);
        }
        else if (GPIO[5] && rom_selection > 0) {
            rom_selection--;
            sleep_millis(150);
        }
    }

    Render = 0;
    playing = 1;

    V_Scroll = 0;
    set_sprite(0, 0, 0, 0, 0, 0);
    clear_bg();
    for (int i = 0; i <= 33; i++)
        BG_Data[i] = BG_Data[i + 64 * 17] = 16;
    for (int i = 0; i <= 17; i++)
        BG_Data[64 * i] = BG_Data[64 * i + 33] = 16;

    Render = 1;

    memcpy(memory + 0x200, roms[rom_selection].data, roms[rom_selection].size);
    memcpy(memory, chip8_font, 80);
    pc = 0x200;

    while (1) {
        run();
//        sleep_micros(1429); // Lock clock speed to ~700 Hz
    }
}

void vblank() {
    if (!playing) {
        if (rom_selection < 30) {
            set_sprite(0, 17, 3 * 8, (2 + rom_selection) * 8, 0, 0);
            V_Scroll = 0;
        } else {
            set_sprite(0, 17, 3 * 8, (2 + rom_selection - 30) * 8, 0, 0);
            V_Scroll = 30 * 8;
        }
    } else {
        int tile = 0;
        for (int y = 1; y < 17; y++)
            for (int x = 1; x < 33; x++)
                BG_Data[y * 64 + x] = display_buffer[tile++];
    }
}
