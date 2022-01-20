; Controller Test

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"

    def scl=$40040
    def sda=$40044
    def scl_out=$400D0
    def sda_out=$400D4
    include "libraries/Nunchuk.asm"

main:
    ldr sp,stack ; Initialize stack

    jsr nunchuck_init

loop:
    jsr nunchuck_update
    ldb r0,[nunchuck_joystick_x]
    str r0,[{seven_segment_0}]

    bra loop

    data
stack: ; Don't put anything after this line
