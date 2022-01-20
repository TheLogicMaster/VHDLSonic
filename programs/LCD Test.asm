; LCD Test

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"
    include "libraries/ILI9341.asm"

test: db $00,$11,$22,$33,$44,$55,$66,$77,$88,$99,$AA,$BB,$CC,$DD,$EE,$FF

main:
    ldr sp,stack ; Initialize stack

; Initialize LCD
    jsr ili9341_init

; Fill screen with red
    ldr r0,%11111000000000000
    jsr ili9341_fill_screen

; Draw blue rectangle
    ldr r0,%00000000000011111
    ldr r1,2
    ldr r2,2
    ldr r3,10
    ldr r4,10
    jsr ili9341_fill_rect

; Draw white pixel
    ldr r0,$FFFF
    ldr r1,2
    ldr r2,2
    jsr ili9341_draw_pixel

; Draw raw pixel data
    jsr ili9341_reset_addr_window
    ldr r0,test
    ldr r1,8
    ldr r2,1
    jsr ili9341_write_pixels

loop:

    bra loop

    data
    align 4
stack: ; Don't put anything after this line
