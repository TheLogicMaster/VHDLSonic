// C Parrot

#include "libraries/Sonic.h"
#include "libraries/Print.h"

int main() {
    // Enable UART
    Arduino_Modes[1] = 1;
    UART_Enable = 1;

    print("Say something!\n");

    while (1) {
        if (Serial_Available) { // Check if there are bytes to read
            Serial = Serial; // "Parrot" read byte
            Serial_Available = 0x0; // Pop read byte from FIFO
        }
    }
}
