// C Hello World program

#include "libraries/Print.h"

static const char message[] = "Hello World!\n";

int main() {
    // Print string
    print(message);

    // Print format string
    printf("%s\nprintf format examples: %d %d %x %u %u %c\n", message, -1, 200, 0xABCD, 100, 0xFF, '!');
}
