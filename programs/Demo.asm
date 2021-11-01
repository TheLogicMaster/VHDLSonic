; Demo

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

loop:
; Set LEDs based on switches
    ldr r1,36
switch_loop:
    ldr r0,r1,{switches}
    str r0,r1,{leds}
    sub r1,4
    bhs switch_loop

; Decimal counter
    ldr r1,0
seg_7_loop:
    ldr r0,r1,{seven_segment}
    inc r0
    str r0,r1,{seven_segment}
    cmp r0,10
    blo seg_7_loop_done
    ldr r0,0
    str r0,r1,{seven_segment}
    add r1,4
    cmp r1,24
    blo seg_7_loop
seg_7_loop_done:

; A bit of delay
    ldr r1,300
delay:
    dec r1
    bhs delay

    bra loop
