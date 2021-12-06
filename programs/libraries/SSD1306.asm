; SSD1306 Software I2C implementation
; SSD1306 128x64 I2C OLED display library that uses a 1 KB display buffer
; Reference: https://github.com/adafruit/Adafruit_SSD1306/blob/master/Adafruit_SSD1306.cpp

    include "Software I2C.asm"
    include "Math.asm"


; Initialize I2C SSD1306 display
; Set [ssd1306_addr] to the display's I2C address before calling
setup_ssd1306:
    push r0
    push r1

    ldb r0,[ssd1306_addr]

    jsr i2c_start_write
    ldr r1,0
    jsr i2c_send_byte
    ldr r1,$AE
    jsr i2c_send_byte
    ldr r1,$D5
    jsr i2c_send_byte
    ldr r1,$80
    jsr i2c_send_byte
    ldr r1,$A8
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$3F
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$D3
    jsr i2c_send_byte
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$40
    jsr i2c_send_byte
    ldr r1,$8D
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$14
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$20
    jsr i2c_send_byte
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$A1
    jsr i2c_send_byte
    ldr r1,$C8
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$DA
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$12
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$81
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$CF
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$D9
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$F1
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$DB
    jsr i2c_send_byte
    ldr r1,$40
    jsr i2c_send_byte
    ldr r1,$A4
    jsr i2c_send_byte
    ldr r1,$A6
    jsr i2c_send_byte
    ldr r1,$2E
    jsr i2c_send_byte
    ldr r1,$AF
    jsr i2c_send_byte
    jsr i2c_stop

    pop r1
    pop r0
    ret


; Draws sprite from [r2] at (r1,r0)
; Modifies [ssd1306_color]
ssd1306_draw_sprite:
    push r0
    push r1
    push r2

    str r1,[ssd1306_temp_]
    ldr r1,$0
ssd1306_draw_sprite_loop_:
    push r0

; Set color
    push r1
    ldr r1,r2,0
    stb r1,[ssd1306_color]
    inc r2
    pop r1

; Calculate Y
    push r1
    push r0
    push r1
    pop r0
    ldr r1,$8
    jsr udiv
    push r0
    pop r1
    pop r0
    add r0,r1
    pop r1

    push r1

; Calculate X
    push r0
    push r1
    pop r0
    ldr r1,$8
    jsr umod
    ldr r1,[ssd1306_temp_]
    add r0,r1
    push r0
    pop r1
    pop r0

; Draw pixel
    jsr ssd1306_draw_pixel

    pop r1

    inc r1
    ldr r0,64
    cmp r0,r1
    pop r0
    bne ssd1306_draw_sprite_loop_

    pop r2
    pop r1
    pop r0
    ret


; Draw a monochrome pixel to the display buffer with [ssd1306_color] at (r1,r0)
ssd1306_draw_pixel:
    push r0
    push r1
    push r2

; Get address of pixel's column
    push r0
    push r1
    ldr r1,$8
    jsr udiv
    ldr r1,128
    mul r0,r1
    tfr r2,r0
    pop r0
    add r2,r0
    ldr r0,ssd1306_buffer
    add r2,r0
    pop r0

; Set bit for pixel
    ldr r1,$8
    jsr umod
    push r0
    pop r1
    ldr r0,$1
    push r0
    ldr r0,$0
    cmp r0,r1
    pop r0
ssd1306_draw_pixel_shift_:
    beq ssd1306_draw_pixel_shift_done_
    lsl r0,1
    dec r1
    bra ssd1306_draw_pixel_shift_
ssd1306_draw_pixel_shift_done_:
    ldb r1,[ssd1306_color]
    beq ssd1306_draw_pixel_0_
    push r0
    pop r1
    ldb r0,r2,0
    or r0,r1
    bra ssd1306_draw_pixel_store_
ssd1306_draw_pixel_0_:
    xor r0,$FF
    push r0
    pop r1
    ldb r0,r2,0
    and r0,r1
ssd1306_draw_pixel_store_:
    stb r0,r2,0

    pop r2
    pop r1
    pop r0
    ret


; Clears the display buffer with [ssd1306_color]
ssd1306_clear:
    push r0
    push r1
    push r2

    ldr r1,$0
    ldb r0,[ssd1306_color]
    beq ssd1306_clear_0_
    ldr r1,$FF
ssd1306_clear_0_:
    str r1,[ssd1306_temp_]
    ldr r0,1024
    ldr r2,ssd1306_buffer
ssd1306_clear_loop_:
    ldr r1,[ssd1306_temp_]
    stb r1,r2,0
    inc r2
    dec r0
    bne ssd1306_clear_loop_

    pop r2
    pop r1
    pop r0
    ret


; Push the display buffer to the SSD1306 display
ssd1306_update:
    push r2

    ldr r2,ssd1306_buffer
    jsr ssd1306_display

    pop r2
    ret


; Draw a 128x64 binary image at [r2] to the display buffer
ssd1306_draw_image:
    push r0
    push r1
    push r2
    push r3

    ldr r3,ssd1306_buffer
    ldr r1,1024
ssd1306_draw_image_loop_:
    ldb r0,r2++
    stb r0,r3++
    dec r1
    bne ssd1306_draw_image_loop_

    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Update display with pixel data at [r2]
ssd1306_display:
    push r0
    push r1

    ldb r0,[ssd1306_addr]

; Set display start address
    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$22
    jsr i2c_send_byte
    ldr r1,$00
    jsr i2c_send_byte
    ldr r1,$FF
    jsr i2c_send_byte
    ldr r1,$21
    jsr i2c_send_byte
    ldr r1,$0
    jsr i2c_send_byte
    jsr i2c_stop
    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    ldr r1,$7F
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$40
    jsr i2c_send_byte

    ldr r0,1024
ssd1306_display_loop_:
    ldb r1,r2,0
    inc r2
    jsr i2c_send_byte
    dec r0
    bne ssd1306_display_loop_

    jsr i2c_stop

    pop r1
    pop r0
    ret


    data
; The I2C address of the display
ssd1306_addr: var
; The current color to draw with
ssd1306_color: var

    align 4
ssd1306_temp_: var[4]
ssd1306_buffer: var[1024]
