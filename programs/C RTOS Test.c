// C RTOS Test

#include "libraries/Sonic.h"
#include "libraries/RTOS.h"

void task1() {
    while (1) {
        rtos_semaphore_pend(0);
        LEDs[0] = !LEDs[0];
        rtos_semaphore_post(0);
        rtos_sleep(500);
    }
}

void task2() {
    while (1) {
        LEDs[1] = !LEDs[1];
        rtos_sleep(1000);
    }
}

void task3() {
    while (1) {
        LEDs[2] = 1;
        rtos_semaphore_pend(0);
        rtos_sleep(2000);
        rtos_semaphore_post(0);
        LEDs[2] = 0;
        rtos_sleep(5000);
    }
}

int main() {
    rtos_set_task(task1, 0);
    rtos_set_task(task2, 1);
    rtos_set_task(task3, 2);

    rtos_begin();
}

void timer() {
    rtos_timer();
}
