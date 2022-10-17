; RTOS Test

; Interrupt vector table
    jmp main
    bra -8
    bra -8
    bra -8
    bra timer_isr
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"
    include "libraries/RTOS.asm"


main:
    ldr sp,entry_stack

    ldr r0,task1
    ldr r1,0
    jsr rtos_set_task
    ldr r0,task2
    ldr r1,1
    jsr rtos_set_task
    ldr r0,task3
    ldr r1,2
    jsr rtos_set_task

    bra rtos_begin


task1:
    ldr r0,0
    jsr rtos_semaphore_pend
    ldr r1,[{led_0}]
    xor r1,1
    str r1,[{led_0}]
    jsr rtos_semaphore_post
    ldr r0,500
    jsr rtos_sleep
    bra task1


task2:
    ldr r1,[{led_1}]
    xor r1,1
    str r1,[{led_1}]
    ldr r0,1000
    jsr rtos_sleep
    bra task2


task3:
    ldr r1,1
    str r1,[{led_2}]
    ldr r0,0
    jsr rtos_semaphore_pend

    ldr r0,2000
    jsr rtos_sleep

    ldr r1,0
    str r1,[{led_2}]
    ldr r0,0
    jsr rtos_semaphore_post

    ldr r0,5000
    jsr rtos_sleep

    bra task3


timer_isr:
    jsr rtos_timer
    rti


    data
    align 4
entry_stack: var[64]
