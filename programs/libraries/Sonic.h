// VHDLSonic C interfaces

// Memory mapped
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

extern void error();
extern void reset();
extern void cli();
extern void sei();

// Utils
extern void memcpy(void *dest, const void *src, unsigned int size);
