; Printing and formatting library

    ifndef printf_buffer=64 ; Must be a positive multiple of 4

    include "Math.asm"


; Print string pointer in R0
print:
    push r0
    push r1
print_loop_:
    ldr r1,[{serial_full}]
    bne print_loop_
    ldb r1,r0++
    beq print_done_
    str r1,[{serial}]
    bra print_loop_
print_done_:
    pop r1
    pop r0
    ret


; Prints integer r5 with base r6 into buffer [ro]
; Modifies r0
sprintf_internal_print_base_:
    push r1
    push r2
    push r3
    push r5
    add sp,12

    cmp r5,0
    bne sprintf_internal_print_base_not_zero_
    ldr r1,'0'
    stb r1,r0++
    bra sprintf_internal_print_base_done_
sprintf_internal_print_base_not_zero_:
    tfr r2,sp
    sub r2,12
    ldr r3,0
sprintf_internal_print_base_loop_:
    inc r3
    push r0
    tfr r0,r5
    tfr r1,r6
    jsr umod
    cmp r0,10
    blo sprintf_internal_print_base_numeric_digit_
    sub r0,10
    ldr r1,'A'
    bra sprintf_internal_print_base_digit_
sprintf_internal_print_base_numeric_digit_:
    ldr r1,'0'
sprintf_internal_print_base_digit_:
    add r1,r0
    stb r1,r2++
    tfr r0,r5
    tfr r1,r6
    jsr udiv
    tfr r5,r0
    pop r0
    cmp r5,0
    bne sprintf_internal_print_base_loop_
sprintf_internal_print_base_print_:
    ldb r1,--r2
    stb r1,r0++
    dec r3
    bne sprintf_internal_print_base_print_
sprintf_internal_print_base_done_:

    sub sp,12
    pop r5
    pop r3
    pop r2
    pop r1
    ret


; Print into buffer [ro] with format string [r1] using final parameter at [r2]
; Supports escaped '%', but requires a dummy character after it, to make the implementation simpler
sprintf_internal_:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6

    ldr r4,0
sprintf_internal_loop_:
    tfr r3,r4
    ldb r4,r1++
    beq sprintf_internal_done_
    cmp r3,'%'
    bne sprintf_internal_not_prev_format_
    cmp r4,'%'
    bne sprintf_internal_not_percent_
    ldr r5,'%'
    stb r5,r0++
    bra sprintf_internal_loop_
sprintf_internal_not_percent_:
    cmp r4,'i'
    beq sprintf_internal_int_
    cmp r4,'d'
    bne sprintf_internal_not_int_
sprintf_internal_int_:
    ldr r5,r2--
    cmp r5,0
    bpl sprintf_internal_int_positive_
    ldr r6,'-'
    stb r6,r0++
    mul r5,-1
sprintf_internal_int_positive_:
    ldr r6,10
    jsr sprintf_internal_print_base_
    bra sprintf_internal_loop_
sprintf_internal_not_int_:
    cmp r4,'u'
    bne sprintf_internal_not_uint_
    ldr r5,r2--
    ldr r6,10
    jsr sprintf_internal_print_base_
    bra sprintf_internal_loop_
sprintf_internal_not_uint_:
    cmp r4,'x'
    bne sprintf_internal_not_hex_
    ldr r5,r2--
    ldr r6,16
    jsr sprintf_internal_print_base_
    bra sprintf_internal_loop_
sprintf_internal_not_hex_:
    cmp r4,'c'
    bne sprintf_internal_not_char_
    ldr r5,r2--
    stb r5,r0++
    bra sprintf_internal_loop_
sprintf_internal_not_char_:
    cmp r4,'s'
    bne sprintf_internal_loop_
    ldr r5,r2--
sprintf_internal_string_loop_:
    ldb r6,r5++
    beq sprintf_internal_loop_
    stb r6,r0++
    bra sprintf_internal_string_loop_
sprintf_internal_not_prev_format_:
    cmp r4,'%'
    beq sprintf_internal_loop_
    stb r4,r0++
    bra sprintf_internal_loop_
sprintf_internal_done_:
    ldr r5,0
    stb r5,r0++

    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Print into buffer [r0] with format string [r1] using pushed parameters
; Supports escaped '%', but requires a dummy character after it, to make the implementation simpler
; Format parameters must be pushed in reverse order
sprintf:
    push r2

    tfr r2,sp
    sub r2,12
    jsr sprintf_internal_

    pop r2
    ret


; Print format string [r0] with pushed parameters
; Supports escaped '%', but requires a dummy character after it, to make the implementation simpler
; Format parameters must be pushed in reverse order
; Uses buffer on stack of size {printf_buffer}
printf:
    push r0
    push r1
    push r2
    add sp,{printf_buffer}

    tfr r1,r0
    tfr r2,sp
    sub r2,{printf_buffer}
    tfr r0,r2
    sub r2,20
    jsr sprintf_internal_
    jsr print

    sub sp,{printf_buffer}
    pop r2
    pop r1
    pop r0
    ret
