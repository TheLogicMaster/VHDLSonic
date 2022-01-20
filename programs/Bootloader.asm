; Emulator Bootloader

    include "libraries/Kernel.asm"

cursor: bin "data/tiles/face.bin"
font: bin "data/tiles/font.bin"

blink: db "Blink", 0
demo: db "Demo", 0

entry:
    ldr sp,kernel_stack ; Initialize stack

; Copy font into tile data starting at tile 2
    ldr r0,font
    ldr r1,2
    ldr r2,72
    jsr copy_tiles

; Copy cursor into tile 1
    ldr r0,cursor
    ldr r1,1
    jsr copy_tile

; Clear BG data
    jsr clear_bg_data

; Draw program menu
    ldr r0,blink
    ldr r1,3
    ldr r2,5
    ldr r3,2
    jsr draw_text
    ldr r0,demo
    inc r2
    jsr draw_text

; Enable rendering
    ldr r0,1
    str r0,[{render}]

; Setup timer 0 for 1000 milliseconds
    ldr r1,0
    ldr r0,50000
    str r0,r1,{timer_prescale}
    ldr r0,1000
    str r0,r1,{timer_compare}

    ldr r2,0
loop:

    ldr r0,[{button_1}]
    beq not_pressed
    ldr r0,0
    str r0,r1,{timer_count}
    ldr r0,1
    str r0,r1,{timer_enable}
wait_for_release:
    ldr r0,r1,{timer_enable}
    beq run_program
    ldr r0,[{button_1}]
    bne wait_for_release

; Clear old cursor position
    ldr r0,0
    ldr r1,1
    push r2
    add r2,5
    jsr set_bg_tile
    pop r2

; Switch to program
    inc r2
    tfr r0,r2
    ldr r1,2
    jsr umod
    tfr r2,r0
not_pressed:

; Draw cursor
    ldr r0,1
    ldr r1,1
    push r2
    add r2,5
    jsr set_bg_tile
    pop r2

    bra loop

run_program:
    jsr setup_sd_card

    ldr r0,0
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

; Copy program into memory
    tfr r3,r2
    mul r3,56
    ldr r4,56
    ldr r2,program_main
copy_program:
    tfr r0,r3
    jsr sd_read_block
;    beq fail ; Todo: Handle error
    ldr r1,512
copy_program_block:
    jsr spi_receive_byte
    stb r0,r2++
    dec r1
    bne copy_program_block
    dec r4
    bne copy_program

    ldr r0,1
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

    jmp program_main

; Hijack entry point
    org $0
    jmp entry
