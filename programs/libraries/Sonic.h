// VHDLSonic C interfaces

// Memory mapped
extern int IE, IF, Serial;
extern void error();
extern void reset();

// Utils
extern void memcpy(void *dest, const void *src, unsigned int size);
