// C Demo

#include "libraries/Sonic.h"

int main() {
    while(1) {
        // Set LEDs based on switches
        for (int i = 0; i < 10; i++)
            LEDs[i] = Switches[i];

        // Display decimal counter
        for (int i = 0; i < 6; i++) {
            Seven_Segment[i]++;
            if (Seven_Segment[i] <= 9)
                break;
            Seven_Segment[i] = 0;
        }

        // A bit of delay
        for (int i = 0; i < 100; i++);
    }
}
