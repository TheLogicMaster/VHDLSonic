; Random Test

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"
    include "libraries/Random.asm"

main:
    ldr sp,stack ; Initialize stack

    jsr seed_rng

loop:

; Set random values to seven segment displays
    ldr r1,20
random_loop:
    ldr r0,[{random}]
    str r0,r1,{seven_segment}
    sub r1,4
    bhs random_loop

; Wait for button press
button_high_loop:
    ldr r0,[{button_1}]
    bne button_high_loop
button_low_loop:
    ldr r0,[{button_1}]
    beq button_high_loop

    bra loop

    data
stack: ; Don't put anything after this line
