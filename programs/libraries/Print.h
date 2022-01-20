// Print and printf functionality

#pragma include "libraries/Print.asm"

#ifndef PRINTF_BUFFER
#define PRINTF_BUFFER 64
#endif

#define printf printf_wrapper
#define sprintf sprintf_wrapper

void print(const char *string) =
    "\tldr r0,sp,-4\n"
    "\tjsr print";

void sprintf_internal(char *buffer, const char *format, int *params) =
    "\tldr r0,sp,-4\n"
    "\tldr r1,sp,-8\n"
    "\tldr r2,sp,-12\n"
    "\tjsr sprintf_internal_";

void printf_wrapper(const char* format, ...) {
    char buffer[PRINTF_BUFFER];
    sprintf_internal(buffer, format, (int*)&format - 1);
    print(buffer);
}

void sprintf_wrapper(char *buffer, const char* format, ...) {
    sprintf_internal(buffer, format, (int*)&format - 1);
}
