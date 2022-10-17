#ifndef RTOS_H
#define RTOS_H

#pragma include "libraries/RTOS.asm"

#define rtos_set_task rtos_set_task_c
void rtos_set_task_c(void (*task)(void), int priority) =
    "\tldr r0,sp,-4\n"
    "\tldr r1,sp,-8\n"
    "\tjsr rtos_set_task";

#define rtos_sleep rtos_sleep_c
void rtos_sleep_c(int millis) =
    "\tldr r0,sp,-4\n"
    "\tjsr rtos_sleep";

#define rtos_semaphore_pend rtos_semaphore_pend_c
void rtos_semaphore_pend_c(int task) =
    "\tldr r0,sp,-4\n"
    "\tjsr rtos_semaphore_pend";

#define rtos_semaphore_post rtos_semaphore_post_c
void rtos_semaphore_post_c(int task) =
    "\tldr r0,sp,-4\n"
    "\tjsr rtos_semaphore_post";

#define rtos_begin rtos_begin_c
void rtos_begin_c() = "\tbra rtos_begin";

extern void rtos_timer();

#endif
