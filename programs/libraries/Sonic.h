// VHDLSonic C interfaces

// Memory mapped
extern int IE, IF;
extern int Random;
extern int Serial;
extern int GPIO[36];

extern void error();
extern void reset();
extern void cli();
extern void sei();

// Utils
extern void memcpy(void *dest, const void *src, unsigned int size);
