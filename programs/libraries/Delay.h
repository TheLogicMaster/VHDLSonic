// Delay functions using timer 7

#pragma include "libraries/Delay.asm"

void sleep_prescale(unsigned int ticks, unsigned short prescale) =
    "\tldr r0,sp,-4\n"
    "\tldr r1,sp,-8\n"
    "\tjsr sleep_prescale";

void sleep(unsigned int seconds) =
    "\tldr r0,sp,-4\n"
    "\tjsr sleep";

void sleep_millis(unsigned int milliseconds) =
    "\tldr r0,sp,-4\n"
    "\tjsr sleep_millis";

void sleep_micros(unsigned int microseconds) =
    "\tldr r0,sp,-4\n"
    "\tjsr sleep_micros";
