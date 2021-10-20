// C Exception Handler Test

#include "libraries/Sonic.h"
#include "libraries/Print.h"

int main() {
    print("Calculating result:\n");
    int n = 20;
    int d = 0;
    int result = n / d;
    print("Whelp, this isn't good...\n");
}

void exception() {
    print("Division by zero!\n");
    for (unsigned int i = 0; i < 0x100000; i++); // ~10 second delay
    print("Resetting!\n");
    reset();
}
