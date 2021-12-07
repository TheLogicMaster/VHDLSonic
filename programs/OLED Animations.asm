; OLED Animations

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

    ; Setup initial animation
    ldr r3,animations
    add r3,4
    ldr r2,r3,0

loop:
; Handle animation switching
    ldr r0,[{button_1}]
    beq not_pressed
wait_for_release:
    ldr r0,[{button_1}]
    bne wait_for_release
    add r3,8
    ldr r0,r3,0
    bne not_repeat
    ldr r3,animations
    add r3,4
not_repeat:
    ldr r2,r3,0
not_pressed:

; Show next frame
    jsr ssd1306_display_compressed
    ldb r0,r2,0
    bne next_frame
    ldr r2,r3,0
next_frame:

    bra loop

; Animation table
animations:
    jmp horsey
    jmp space_invaders
    jmp bounce
    jmp stripes
    jmp swirl
    jmp dude
    jmp explode
    jmp flower
    jmp man
    jmp sans
    jmp skull
    jmp zoom
    jmp 0

; Animations
    horsey: bin "data/oled/horsey.bin"
    space_invaders: bin "data/oled/space_invaders.bin"
    bounce: bin "data/oled/bounce.bin"
    stripes: bin "data/oled/stripes.bin"
    swirl: bin "data/oled/swirl.bin"
    dude: bin "data/oled/dude.bin"
    explode: bin "data/oled/explode.bin"
    flower: bin "data/oled/flower.bin"
    man: bin "data/oled/man.bin"
    sans: bin "data/oled/sans.bin"
    skull: bin "data/oled/skull.bin"
    zoom: bin "data/oled/zoom.bin"

    data
    align 4
stack: ; Don't put anything after this line
