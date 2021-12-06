; Math Utilities


; Performs unsigned r0 mod r1 and stores the result in r0
umod:
    cmp r1,0
    beq mod_error_
mod_loop_:
    cmp r0,r1
    blo mod_done_
    sub r0,r1
    ;inc r2          ;modified so r2 returns how many times the subtraction been done aka returns quotient
    bra mod_loop_
mod_done_:
    ret
mod_error_:
    int 1
    ret


; Performs signed r0 mod r1 and stores the result in r0
mod:
    push r1
    push r2

; Save numerator value
    tfr r2,r0

; Convert parameters to unsigned
    cmp r0,0
    bpl mod_r0_pos_
    mul r0,-1
mod_r0_pos_:
    cmp r1,0
    bpl mod_r1_pos_
    mul r1,-1
mod_r1_pos_:

; Perform unsigned modulus
    jsr umod

; Fix sign of result
    push r0
    and r0,$80000000
    and r2,$80000000
    xor r0,r2
    pop r0
    beq mod_pos_
    mul r0,-1
mod_pos_:

    pop r2
    pop r1
    ret


; Performs unsigned r0 divided by r1 and stores the result in r0
udiv:
    push r2
    cmp r1,0
    beq div_error_
    ldr r2,0
div_loop_:
    cmp r0,r1
    blo div_done_
    sub r0,r1
    inc r2
    bra div_loop_
div_done_:
    tfr r0,r2
    pop r2
    ret
div_error_:
    int 1
    pop r2
    ret


; Performs signed r0 divided by r1 and stores the result in r0
div:
    push r1
    push r2

; Get result sign
    ldr r2,0
    push r0
    push r1
    and r0,$80000000
    and r1,$80000000
    xor r0,r1
    beq div_same_sign_
    ldr r2,1
div_same_sign_:
    pop r1
    pop r0

; Convert parameters to unsigned
    cmp r0,0
    bpl div_r0_pos_
    mul r0,-1
div_r0_pos_:
    cmp r1,0
    bpl div_r1_pos_
    mul r1,-1
div_r1_pos_:

; Perform unsigned division
    jsr udiv

; Restore result sign
    cmp r2,0
    beq div_no_fix_
    mul r0,-1
div_no_fix_:

    pop r2
    pop r1
    ret
