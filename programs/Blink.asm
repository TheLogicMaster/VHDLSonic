; Blink

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"

main:
    ldr sp,stack ; Initialize stack

; Setup timer 0 for 1000 milliseconds
    ldr r1,0
    ldr r0,50000
    str r0,r1,{timer_prescale}
    ldr r0,1000
    str r0,r1,{timer_compare}   ;one-shot

loop:
; 1 second delay
    ldr r0,0
    str r0,r1,{timer_count}     ;clear T0
    ldr r0,1
    str r0,r1,{timer_enable}
wait:
    ldr r0,r1,{timer_enable}
    bne wait

; Toggle LED 0
    ldr r2,[{led_0}]
    xor r2,1
    str r2,[{led_0}]

    bra loop

    data
stack: ; Don't put anything after this line
