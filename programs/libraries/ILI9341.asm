; ILI9341 LCD Driver Library
; https://github.com/adafruit/TFTLCD-Library

    def ili9341_softreset=$01
    def ili9341_sleepin=$10
    def ili9341_sleepout=$11
    def ili9341_normaldisp=$13
    def ili9341_invertoff=$20
    def ili9341_inverton=$21
    def ili9341_gammaset=$26
    def ili9341_displayoff=$28
    def ili9341_displayon=$29
    def ili9341_coladdrset=$2A
    def ili9341_pageaddrset=$2B
    def ili9341_memorywrite=$2C
    def ili9341_pixelformat=$3A
    def ili9341_framecontrol=$B1
    def ili9341_displayfunc=$B6
    def ili9341_entrymode=$B7
    def ili9341_powercontrol1=$C0
    def ili9341_powercontrol2=$C1
    def ili9341_vcomcontrol1=$C5
    def ili9341_vcomcontrol2=$C7
    def ili9341_memcontrol=$36
    def ili9341_madctl=$36
    def ili9341_madctl_my=$80
    def ili9341_madctl_mx=$40
    def ili9341_madctl_mv=$20
    def ili9341_madctl_ml=$10
    def ili9341_madctl_rgb=$00
    def ili9341_madctl_bgr=$08
    def ili9341_madctl_mh=$04

    def ili9341_rd=$20
    def ili9341_wr=$24
    def ili9341_cd=$28
    def ili9341_cs=$2C

    def ili9341_cd_command=0
    def ili9341_cd_data=1

    def ili9341_pixels=76800

    include "Sonic.asm"
    include "Delay.asm"


; Initialize ili9341 LCD display
ili9341_init:
    push r0
    push r1

    ldr r0,1
    ldr r1,{ili9341_cs}
    str r0,r1,{arduino}
    ldr r1,{ili9341_cd}
    str r0,r1,{arduino}
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}
    ldr r1,{ili9341_rd}
    str r0,r1,{arduino}

; Configure control lines
    ldr r0,1
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino_modes}
    ldr r1,{ili9341_rd}
    str r0,r1,{arduino_modes}
    ldr r1,{ili9341_cs}
    str r0,r1,{arduino_modes}
    ldr r1,{ili9341_cd}
    str r0,r1,{arduino_modes}

    ldr r0,1
    jsr ili9341_set_data_dir

    jsr ili9341_reset

    ldr r0,200
    jsr sleep_millis

    ldr r0,0
    ldr r1,{ili9341_softreset}
    jsr ili9341_write_reg_8

    ldr r0,50
    jsr sleep_millis

    ldr r0,0
    ldr r1,{ili9341_displayoff}
    jsr ili9341_write_reg_8

    ldr r0,$23
    ldr r1,{ili9341_powercontrol1}
    jsr ili9341_write_reg_8

    ldr r0,$10
    ldr r1,{ili9341_powercontrol2}
    jsr ili9341_write_reg_8

    ldr r0,$2B2B
    ldr r1,{ili9341_vcomcontrol1}
    jsr ili9341_write_reg_16

    ldr r0,$C0
    ldr r1,{ili9341_vcomcontrol2}
    jsr ili9341_write_reg_8

    ldr r0,{ili9341_madctl_mv}
    or r0,{ili9341_madctl_bgr}
    ldr r1,{ili9341_memcontrol}
    jsr ili9341_write_reg_8

    ldr r0,$55
    ldr r1,{ili9341_pixelformat}
    jsr ili9341_write_reg_8

    ldr r0,$001B
    ldr r1,{ili9341_framecontrol}
    jsr ili9341_write_reg_16

    ldr r0,$07
    ldr r1,{ili9341_entrymode}
    jsr ili9341_write_reg_8

    ldr r0,$00
    ldr r1,{ili9341_sleepout}
    jsr ili9341_write_reg_8

    ldr r0,150
    jsr sleep_millis

    ldr r0,$00
    ldr r1,{ili9341_displayon}
    jsr ili9341_write_reg_8

    ldr r0,500
    jsr sleep_millis

    jsr ili9341_reset_addr_window

    pop r1
    pop r0
    ret


; Reset ili9341 LCD display
ili9341_reset:
    push r0
    push r1

    ldr r0,1
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}
    ldr r1,{ili9341_rd}
    str r0,r1,{arduino}

    ldr r0,0
    ldr r1,{ili9341_cs}
    str r0,r1,{arduino}

    ldr r0,{ili9341_cd_command}
    ldr r1,{ili9341_cd}
    str r0,r1,{arduino}

    ldr r0,$00
    jsr ili9341_write_8

    ldr r0,0
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}
    ldr r0,1
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}
    ldr r0,0
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}
    ldr r0,1
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}
    ldr r0,0
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}
    ldr r0,1
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}

    ldr r0,1
    ldr r1,{ili9341_cs}
    str r0,r1,{arduino}

    pop r1
    pop r0
    ret


; Sets LCD address window to from (r0,r1) to (r2,r3)
; Coordinates must be 16-bit and sorted
ili9341_set_addr_window:
    push r0
    push r1

    lsl r0,16
    or r0,r2
    push r1
    ldr r1,{ili9341_coladdrset}
    jsr ili9341_write_reg_32
    pop r1

    tfr r0,r1
    lsl r0,16
    or r0,r3
    ldr r1,{ili9341_pageaddrset}
    jsr ili9341_write_reg_32

    pop r1
    pop r0
    ret


; Resets the LCD window
ili9341_reset_addr_window:
    push r0
    push r1
    push r2
    push r3

    ldr r0,0
    ldr r1,0
    ldr r2,319
    ldr r3,239
    jsr ili9341_set_addr_window

    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Fill rect with color r0 at (r1, r2) of size (r3, r4)
ili9341_fill_rect:
    push r1
    push r2
    push r3

    push r0
    tfr r0,r1
    tfr r1,r2
    tfr r2,r3
    tfr r3,r4
    add r2,r0
    add r3,r1
    sub r2,1
    sub r3,1
    jsr ili9341_set_addr_window
    pop r0

    tfr r1,r3
    mul r1,r4
    jsr ili9341_flood

    pop r3
    pop r2
    pop r1
    ret


; Draw RGB565 color r0 to pixel (r1, r2)
ili9341_draw_pixel:
    push r0
    push r1
    push r2
    push r3
    push r4

    tfr r4,r0
    tfr r0,r1
    tfr r1,r2
    ldr r2,319
    ldr r3,239
    jsr ili9341_set_addr_window

    ldr r2,0
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    ldr r2,{ili9341_cd_command}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

; Issue VRAM write command
    ldr r0,$2C
    jsr ili9341_write_8

    ldr r2,{ili9341_cd_data}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

    tfr r0,r4
    lsr r0,8
    jsr ili9341_write_8
    tfr r0,r4
    jsr ili9341_write_8

    ldr r2,1
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Writes r1 pixels from 16-bit raw pixel buffer at [r0]
; Starts a new write if r2 is true
ili9341_write_pixels:
    push r0
    push r1
    push r3
    push r4

    ldr r4,0
    ldr r3,{ili9341_cs}
    str r4,r3,{arduino}

    cmp r2,0
    beq ili9341_write_pixels_not_start_

    ldr r4,{ili9341_cd_command}
    ldr r3,{ili9341_cd}
    str r4,r3,{arduino}

; Issue VRAM write command
    push r0
    ldr r0,$2C
    jsr ili9341_write_8
    pop r0

ili9341_write_pixels_not_start_:

    ldr r4,{ili9341_cd_data}
    ldr r3,{ili9341_cd}
    str r4,r3,{arduino}

    mul r1,2 ; 2 bytes per pixel
    tfr r4,r0
ili9341_write_pixels_loop_:
    ldb r0,r4++
    jsr ili9341_write_8
    dec r1
    bne ili9341_write_pixels_loop_

    ldr r4,1
    ldr r3,{ili9341_cs}
    str r4,r3,{arduino}

    pop r4
    pop r3
    pop r1
    pop r0
    ret


; Write color r0 to r1 pixels in current address window
ili9341_flood:
    push r0
    push r1
    push r2
    push r3

    ldr r2,0
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    ldr r2,{ili9341_cd_command}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

; Issue VRAM write command
    push r0
    ldr r0,$2C
    jsr ili9341_write_8
    pop r0

    ldr r2,{ili9341_cd_data}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

    tfr r2,r0
    lsr r2,8
    tfr r3,r0

ili9341_flood_loop_:
    tfr r0,r2
    jsr ili9341_write_8
    tfr r0,r3
    jsr ili9341_write_8
    dec r1
    bne ili9341_flood_loop_

    ldr r2,1
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Fill the screen with the RGB565 value in r0
ili9341_fill_screen:
    push r0
    push r1

    jsr ili9341_reset_addr_window

    ldr r1,{ili9341_pixels}
    jsr ili9341_flood

    pop r1
    pop r0
    ret


; Write r0 to 32-bit register r1
ili9341_write_reg_32:
    push r0
    push r2
    push r3

    ldr r2,0
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    ldr r2,{ili9341_cd_command}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

    push r0
    tfr r0,r1
    jsr ili9341_write_8
    pop r0

    ldr r2,{ili9341_cd_data}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

    tfr r3,r0
    lsr r0,24
    jsr ili9341_write_8
    tfr r0,r3
    lsr r0,16
    jsr ili9341_write_8
    tfr r0,r3
    lsr r0,8
    jsr ili9341_write_8
    tfr r0,r3
    jsr ili9341_write_8

    ldr r2,1
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    pop r3
    pop r2
    pop r0
    ret


; Write r0 to 16-bit register r1
ili9341_write_reg_16:
    push r0
    push r2
    push r3

    ldr r2,0
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    ldr r2,{ili9341_cd_command}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

    push r0
    tfr r0,r1
    jsr ili9341_write_8
    pop r0

    ldr r2,{ili9341_cd_data}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

    push r0
    lsr r0,8
    jsr ili9341_write_8
    pop r0
    jsr ili9341_write_8

    ldr r2,1
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    pop r3
    pop r2
    pop r0
    ret


; Write r0 to 8-bit register r1
ili9341_write_reg_8:
    push r2
    push r3

    ldr r2,0
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    ldr r2,{ili9341_cd_command}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

    push r0
    tfr r0,r1
    jsr ili9341_write_8
    pop r0

    ldr r2,{ili9341_cd_data}
    ldr r3,{ili9341_cd}
    str r2,r3,{arduino}

    jsr ili9341_write_8

    ldr r2,1
    ldr r3,{ili9341_cs}
    str r2,r3,{arduino}

    pop r3
    pop r2
    ret


; Write 8-bit r0 to display
ili9341_write_8:
    push r0
    push r1
    push r2

; Set data line values
    ldr r2,0
ili9341_write_8_loop_:
    tfr r1,r0
    and r1,$01
    str r1,r2,{arduino}
    lsr r0,1
    add r2,4
    cmp r2,$20
    bne ili9341_write_8_loop_

; Strobe WR
    ldr r0,0
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}
    ldr r0,1
    ldr r1,{ili9341_wr}
    str r0,r1,{arduino}

    pop r2
    pop r1
    pop r0
    ret


; Set the data direction from r0, where 0 is input and 1 is output
ili9341_set_data_dir:
    push r1

    ldr r1,0
ili9341_set_data_dir_loop_:
    str r0,r1,{arduino_modes}
    add r1,4
    cmp r1,$20
    bne ili9341_set_data_dir_loop_

    pop r1
    ret
