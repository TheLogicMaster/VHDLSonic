; OLED Test

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"
    include "libraries/SSD1306.asm"

main:
    ldr sp,stack ; Initialize stack

; Initialize display with address 0x3C
    ldr r0,$3C
    stb r0,[ssd1306_addr]
    jsr setup_ssd1306

loop:
; Clear screen
    ldr r0,$0
    stb r0,[ssd1306_color]
    jsr ssd1306_clear

; Draw image to display buffer
    ldr r2,image
    jsr ssd1306_draw_image

; Draw lines along sides of sceen over image to demonstrate refresh rate
    ldr r0,$1
    stb r0,[ssd1306_color]
    ldr r0,63
draw_lines:
    ldr r1,0
    jsr ssd1306_draw_pixel
    ldr r1,127
    jsr ssd1306_draw_pixel
    dec r0
    cmp r0,15
    bne draw_lines

; Update display with display buffer
    jsr ssd1306_update

; Draw image directly to display
    ldr r2,image
    jsr ssd1306_display

    bra loop

    image: bin "data/oled/lm8.bin"

    data
    align 4
stack: ; Don't put anything after this line
