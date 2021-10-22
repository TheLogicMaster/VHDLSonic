; Math operations test

    jmp main
    bra -6
    bra -6
    bra -6
    bra -6
    bra -6
    bra -6
    bra -6


; Include libraries
    include "libraries/Math.asm"


; Program entry point
main:
; Initialize SP
    ldr sp,stack

    ldr r0,-65
    ldr r1,-20
    jsr mod
    halt


    data
; Program stack
stack:
