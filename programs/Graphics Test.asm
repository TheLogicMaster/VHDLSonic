; Graphics Test

    jmp main
    bra -8
    jmp vblank
    jmp hblank
    bra -8
    bra -8
    bra -8
    bra -8


    include "libraries/Sonic.asm"
    include "libraries/Graphics.asm"


; Program entry point
main:
; Initialize SP
    ldr sp,stack

    ldr r0,%00001100
    str r0,{ie}
    sei

    ldr r0,face
    ldr r1,1
    jsr copy_tile

    ldr r0,face_sprite
    ldr r1,2
    jsr copy_sprite

; Set sprite index zero to tiles 2-5 at (32,32) with no mirroring
    ldr r0,0
    ldr r1,2
    ldr r2,32
    ldr r3,32
    ldr r4,0
    ldr r5,0
    jsr set_sprite

;    jsr debug_tiles

; Set BG tile 0-4 to to tile index 1-5
    ldr r0,0
    ldr x,{bg_data}
    str r0,x++
    inc r0
    str r0,x++
    inc r0
    str r0,x++
    inc r0
    str r0,x++
    inc r0
    str r0,x++

; Enable rendering
    ldr r0,1
    str r0,{render}

loop:

    bra loop

vblank:
    inc r8
    rti

hblank:
    inc r9
    rti

face: bin "data/face.bin"
face_sprite: bin "data/face_sprite.bin"

    data
    var[4] ; Padding to prevent memory boundary issues
; Program stack
stack:
