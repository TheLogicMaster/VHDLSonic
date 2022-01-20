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


; Set BG tile (r1, r2) to r0
set_bg_tile:
    push r2

    mul r2,64
    add r2,r1
    mul r2,4
    str r0,r2,{bg_data}

    pop r2
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
    mul y,32
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


; Draw text at r0 to tile (r1, r2) from font first tile r3
draw_text:
    push r0
    push r4
    push r5

    tfr r4,r2
    mul r4,64
    add r4,r1
    mul r4,4
    add r4,{bg_data}

draw_text_loop_:
    ldb r5,r0++
    beq draw_text_done_
    cmp r5,'A'
    blo draw_text_not_uppercase_
    cmp r5,'Z'
    bhi draw_text_not_uppercase_
    sub r5,'A'
    bra draw_text_draw_
draw_text_not_uppercase_:
    cmp r5,'a'
    blo draw_text_not_letter_
    cmp r5,'z'
    bhi draw_text_not_letter_
    sub r5,'a'
    add r5,26
    bra draw_text_draw_
draw_text_not_letter_:
    cmp r5,'0'
    blo draw_text_not_number_
    cmp r5,'9'
    bhi draw_text_not_number_
    sub r5,'0'
    add r5,52
    bra draw_text_draw_
draw_text_not_number_:
    cmp r5,'!'
    blo draw_text_not_special_
    cmp r5,'&'
    bhi draw_text_not_special_
    sub r5,'!'
    add r5,62
    bra draw_text_draw_
draw_text_not_special_:
    cmp r5,'.'
    bne draw_text_not_period_
    ldr r5,68
    bra draw_text_draw_
draw_text_not_period_:
    cmp r5,','
    bne draw_text_not_comma_
    ldr r5,69
    bra draw_text_draw_
draw_text_not_comma_:
    cmp r5,'?'
    bne draw_text_not_question_
    ldr r5,70
    bra draw_text_draw_
draw_text_not_question_:
    cmp r5,':'
    bne draw_text_not_colon_
    ldr r5,71
    bra draw_text_draw_
draw_text_not_colon_:
    ldr r5,0
    sub r5,r3
draw_text_draw_:
    add r5,r3
    str r5,r4++
    bra draw_text_loop_
draw_text_done_:

    pop r5
    pop r4
    pop r0
    ret


; Clears BG data
clear_bg_data:
    push r0
    push r1
    push r2

    ldr r0,0
    ldr r1,4096
    ldr r2,{bg_data}
clear_bg_data_loop_:
    str r0,r2++
    dec r1
    bne clear_bg_data_loop_

    pop r2
    pop r1
    pop r0
    ret
