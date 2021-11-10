// VHDLSonic C interfaces

extern int IE, IF;
extern int Random;

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

extern int Render;
extern int H_Scroll, V_Scroll;
extern int Window_X, Window_Y;
extern int Palette[16];
extern int Tile_Data[256 * 32];
extern int BG_Data[64 * 64];
extern int Win_Data[40 * 30];
extern int Sprites[32];

extern void error();
extern void reset();
extern void cli();
extern void sei();

// Utils
extern void memcpy(void *dest, const void *src, unsigned int size);