; Graphics Utilities

    include "Sonic.asm"


; Fully set a sprite
; R0: Sprite index
; R1: First tile
; R2: X coord
; R3: Y coord
; R4: Horizontal flip
; R5: Vertical flip
set_sprite:
    push r0
    push r6
    push r7

    mul r0,4
    tfr r7,r5
    tfr r6,r4
    lsl r6,1
    or r7,r6
    tfr r6,r3
    lsl r6,2
    or r7,r6
    tfr r6,r2
    lsl r6,11
    or r7,r6
    tfr r6,r1
    lsl r6,20
    or r7,r6
    str r7,r0,{sprites}

    pop r7
    pop r6
    pop r0
    ret


; Copy tile data into VRAM
; R0: Source data pointer
; R1: First tile index
; R2: Tile count
copy_tiles:
    push x
    push y
    push r3
    push r4

    tfr x,r0
    tfr r3,r2
    mul r3,32
    add r3,x
    tfr y,r1
    mul y,128
    add y,{tile_data}
copy_tiles_loop_:
    ldr r4,x++
    str r4,y++
    cmp x,r3
    bne copy_tiles_loop_

    pop r4
    pop r3
    pop y
    pop x
    ret


; Copy sprite tiles into VRAM
; R0: Source data pointer
; R1: First tile index
copy_sprite:
    push r2
    ldr r2,4
    jsr copy_tiles
    pop r2
    ret


; Copy a single tile into VRAM
; R0: Source data pointer
; R1: Tile index
copy_tile:
    push r2
    ldr r2,1
    jsr copy_tiles
    pop r2
    ret


; Sets the window to display the tileset
; Also sets the windows coords to (0,0)
debug_tiles:
    push r0
    push x

    ldr r0,0
    str r0,{window_x}
    str r0,{window_y}
    ldr x,{win_data}
debug_tiles_loop_:
    str r0,x++
    inc r0
    cmp r0,256
    bne debug_tiles_loop_

    pop x
    pop r0
    ret