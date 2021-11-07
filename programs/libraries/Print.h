// Print and printf functionality

#include "Sonic.h"

void print(const char* string) {
    while(*string)
        Serial = *(string++);
}

#define PRINTF_BUFFER 64

void sprintf_internal(char *buffer, const char** format) {
    char *buffer_ptr = buffer;

    const char *format_ptr = *format;

    int *arg_ptr = (int*)format - 1;

    int count;
    char digits[5];

    char prev = 0;
    while (*format_ptr) {
        if (prev == '%') {
            if (*format_ptr == '%') {
                *(buffer_ptr++) = '%';
            } else if (*format_ptr == 'd' || *format_ptr == 'i') {
                int value = *(arg_ptr--);
                if (value < 0) {
                    *(buffer_ptr++) = '-';
                    value = -value;
                } else if (value == 0)
                    *(buffer_ptr++) = '0';
                count = 0;
                while (value > 0) {
                    digits[count++] = '0' + value % 10;
                    value /= 10;
                }
                for (int i = 0; i < count; i++)
                    *(buffer_ptr++) = digits[count - 1 - i];
            } else if (*format_ptr == 'u') {
                unsigned int value = *(unsigned int*)(arg_ptr--);
                if (value == 0)
                    *(buffer_ptr++) = '0';
                count = 0;
                while (value > 0) {
                    digits[count++] = '0' + value % 10;
                    value /= 10;
                }
                for (int i = 0; i < count; i++)
                    *(buffer_ptr++) = digits[count - 1 - i];
            } else if (*format_ptr == 'x') {
                unsigned int value = *(unsigned int*)(arg_ptr--);
                if (value == 0)
                    *(buffer_ptr++) = '0';
                count = 0;
                while (value > 0) {
                    unsigned int adjusted = value % 16;
                    digits[count++] = (adjusted < 10 ? '0' : 'A' - 10) + adjusted;
                    value /= 16;
                }
                for (int i = 0; i < count; i++)
                    *(buffer_ptr++) = digits[count - 1 - i];
            } else if (*format_ptr == 'c') {
                *(buffer_ptr++) = *(arg_ptr--);
            } else if (*format_ptr == 's') {
                char *string = *(char**)(arg_ptr--);
                while(*string)
                    *(buffer_ptr++) = *(string++);
            }
        } else if (*format_ptr != '%') {
            *(buffer_ptr++) = *format_ptr;
        }
        prev = *format_ptr;
        format_ptr++;
    }
    *buffer_ptr = 0;
}

void sprintf(char *buffer, const char* format, ...) {
    sprintf_internal(buffer, &format);
}

void printf(const char* format, ...) {
    char buffer[PRINTF_BUFFER];
    sprintf_internal(buffer, &format);
    print(buffer);
}
