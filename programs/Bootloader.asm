; Emulator Bootloader

    include "libraries/Kernel.asm"

cursor: bin "data/tiles/face.bin"
font: bin "data/tiles/font.bin"

entry:
    ldr sp,kernel_stack ; Initialize stack

; Clear display
    jsr clear_bg_data
    jsr clear_tile_data
    jsr clear_sprites
    jsr clear_win_data

; Copy font into tile data starting at tile 2
    ldr r0,font
    ldr r1,2
    ldr r2,72
    jsr copy_tiles

; Copy cursor into tile 1
    ldr r0,cursor
    ldr r1,1
    jsr copy_tile

    jsr setup_sd_card

    ldr r0,0
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

    jsr sd_read_block

    ldr r5,0
    ldr r1,3
    ldr r2,5
    ldr r3,2
boot_load_loop:
    jsr spi_receive_byte
    cmp r0,0
    beq boot_load_done
    ldr r4,program_main
boot_load_name:
    stb r0,r4++
    jsr spi_receive_byte
    cmp r0,0
    bne boot_load_name
boot_load_name_done:
    ldr r0,0
    stb r0,r4
    ldr r0,program_main
    jsr draw_text
    inc r2
    inc r5
    bra boot_load_loop
boot_load_done:

    ldr r0,1
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

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
    bne pressed
;    ldr r0,[{gpio_11}]
;    bne pressed
    bra not_pressed
pressed:
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
    tfr r1,r5
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
    ldr r0,0
    str r0,[{render}]
    jsr clear_win_data
    jsr clear_tile_data
    jsr clear_sprites
    jsr clear_bg_data

    ldr r0,0
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

; Copy program into memory
    tfr r3,r2
    mul r3,56
    add r3,1
    ldr r4,56
    ldr r2,program_main
copy_program:
    tfr r0,r3
    jsr sd_read_block
    bne not_fail

; Re-init SD card on error
    ldr r0,1
    ldr r1,{sd_cs}
    str r0,r1,{arduino}
    jsr setup_sd_card
    ldr r0,0
    ldr r1,{sd_cs}
    str r0,r1,{arduino}
    bra copy_program

not_fail:
    ldr r1,512
copy_program_block:
    jsr spi_receive_byte
    stb r0,r2++
    dec r1
    bne copy_program_block
    inc r3
    dec r4
    bne copy_program

    ldr r0,1
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

    jmp program_main

; Hijack entry point
    org $0
    jmp entry
