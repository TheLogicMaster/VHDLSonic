; RTOS

    include "Sonic.asm"


; Set task ptr r0 (0 to 9) with priority r1
rtos_set_task:
    push r1
    mul r1,4
    str r0,r1,tasks
    pop r1
    ret


; Sleep task for r0 millis
rtos_sleep:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    ldb r1,[current_task]
    mul r1,4
    str r0,r1,task_timers
    str sp,r1,task_stack_pointers
    bra rtos_loop_


; Wait on sempahore r0 (0 to 9)
rtos_semaphore_pend:
    push r1
    ldb r1,r0,semaphores
    pop r1
    bne rtos_semaphore_pend_switch_

    push r1
    ldr r1,1
    stb r1,r0,semaphores
    pop r1
    ret

rtos_semaphore_pend_switch_:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    ldb r1,[current_task]
    add r0,1
    stb r0,r1,task_semaphores
    mul r1,4
    str sp,r1,task_stack_pointers
    bra rtos_loop_


; Release semaphore r0 (0 to 9)
rtos_semaphore_post:
    push r1
    ldr r1,0
    stb r1,r0,semaphores
    pop r1
    ret


; Called when there's a timer 0 interrupt
rtos_timer:
    push r0
    push r1
    push r2

; Decrement task delay counts
    ldr r0,0
rtos_timer_loop_:
    tfr r1,r0
    mul r1,4
    ldr r2,r1,task_timers
    beq rtos_timer_zero_
    dec r2
    str r2,r1,task_timers
rtos_timer_zero_:
    inc r0
    cmp r0,10
    bne rtos_timer_loop_

; Clear timer interrupt flag
    ldr r0,[{timer_if}]
    and r0,$FFFFFFFE
    str r0,[{timer_if}]

    pop r2
    pop r1
    pop r0
    ret


; Start RTOS (Doesn't return, so just BRA here)
rtos_begin:
; Enable millisecond timer
    sei
    ldr r0,[{ie}]
    or r0,%10000
    str r0,[{ie}]
    ldr r0,50000
    str r0,[{timer_prescale}]
    ldr r0,2
    str r0,[{timer_compare}]
    ldr r0,$1
    str r0,[{timer_ie}]
    str r0,[{timer_repeat}]
    str r0,[{timer_enable}]

; Initialize task stacks
    ldr r0,0
    ldr r4,task_stacks
rtos_setup_loop_:
    tfr r1,r0
    mul r1,4
    ldr r3,r1,tasks
    tfr r2,r0
    mul r2,1024
    add r2,r4
    str r3,r2
    add r2,64
    str r2,r1,task_stack_pointers
    inc r0
    cmp r0,10
    bne rtos_setup_loop_

rtos_loop_:

    ldr r0,0
rtos_search_loop_:
    tfr r1,r0
    mul r1,4
    ldr r2,r1,tasks
    beq rtos_task_not_ready_
    ldr r2,r1,task_timers
    bne rtos_task_not_ready_
    tfr r1,r0
    ldb r2,r1,task_semaphores
    beq rtos_task_not_pending_
    sub r2,1
    ldb r3,r2,semaphores
    bne rtos_task_not_ready_
    ldr r3,0
    ldb r2,r1,task_semaphores
    ldr r3,1
    stb r3,r2,semaphores
rtos_task_not_pending_:
    mul r1,4
    stb r0,[current_task]
    ldr sp,r1,task_stack_pointers
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret
rtos_task_not_ready_:
    inc r0
    cmp r0,10
    bne rtos_search_loop_

    bra rtos_loop_


    data
semaphores: var[10] ; Array of current semaphore states
task_semaphores: var[10] ; Array of task semaphore wating states
    align 4 ; 32-bit word align
tasks: var[40] ; Array of task entry points
task_timers: var[40] ; Array of task timer values
task_stack_pointers: var[40] ; Array of task stack pointers
task_stacks: var[10240] ; Buffer for task stacks
current_task: var ; The index of the current task
