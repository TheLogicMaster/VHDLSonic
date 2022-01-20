; SD Test

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"
    include "libraries/SD.asm"

main:
    ldr sp,stack ; Initialize stack

    jsr setup_sd_card

    ldr r0,0
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

    ldr r0,0
    jsr sd_read_block
    beq fail

test:
    jsr spi_receive_byte
;    bra test
    str r0,[{seven_segment_0}]

    ldr r0,1
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

loop:

    bra loop

fail:
    ldr r0,1
    str r0,[{led_0}]
    halt

    data
    align 4
stack: ; Don't put anything after this line
