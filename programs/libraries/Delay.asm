; Delay Utilities

    def sleep_timer=$1C

    include "Sonic.asm"


; Sleep for r0 ticks with prescaler r1
sleep_prescale:
    push r2
    push r3

    ldr r2,{sleep_timer}
    str r0,r2,{timer_compare}
    str r1,r2,{timer_prescale}
    ldr r3,0
    str r3,r2,{timer_count}
    ldr r3,1
    str r3,r2,{timer_enable}
sleep_prescale_loop_:
    ldr r3,r2,{timer_enable}
    bne sleep_prescale_loop_

    pop r3
    pop r2
    ret


; Sleep for r0 seconds
sleep:
    push r0
    push r1

    mul r0,1000
    ldr r1,50000
    jsr sleep_prescale

    pop r1
    pop r0
    ret


; Sleep for r0 milliseconds
sleep_millis:
    push r1

    ldr r1,50000
    jsr sleep_prescale

    pop r1
    ret


; Sleep for r0 microseconds
sleep_micros:
    push r1

    ldr r1,50
    jsr sleep_prescale

    pop r1
    ret
