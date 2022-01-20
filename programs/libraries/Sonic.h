// VHDLSonic C interfaces

#pragma include "libraries/C Utilities.asm"

// CPU registers
extern int IE, IF;
extern int Random;

// Microcontroller registers
extern int LEDs[10];
extern int Seven_Segment[6];
extern int GPIO[36];
extern int GPIO_Modes[36];
extern int Arduino[16];
extern int Arduino_Modes[16];
extern int Switches[10];
extern int Buttons[2];
extern int Serial;
extern int Serial_Available;
extern int Serial_Full;
extern int UART_Enable;
extern int ADC[6];
extern int PWM_Enable[8];
extern int PWM_Duty[8];
extern int Timer_IE;
extern int Timer_IF;
extern int Timer_Repeat[8];
extern int Timer_Count[8];
extern int Timer_Prescale[8];
extern int Timer_Enable[8];
extern int Timer_Compare[8];

// Graphics registers
extern int Render;
extern int H_Scroll, V_Scroll;
extern int Window_X, Window_Y;
extern int Palette[16];
extern int Tile_Data[256 * 32];
extern int BG_Data[64 * 64];
extern int Win_Data[40 * 30];
extern int Sprites[32];

// Audio registers
extern int Audio_Channels[3];

// Inline instruction wrappers
void cli() = "\tcli";
void sei() = "\tsei";
void error() = "\tint 1";
void reset() = "\tint 0";

// Utils
extern void memcpy(void *dest, const void *src, unsigned int size);
