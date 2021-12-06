; Print

    include "Sonic.asm"
    include "Math.asm"


; Print string pointer in R0
print_string:
    push r0
    push r1
print_string_loop_:
    ldr r1,[{serial_full}]
    bne print_string_loop_
    ldb r1,r0++
    beq print_string_done_
    str r1,[{serial}]
    bra print_string_loop_
print_string_done_:
    pop r1
    pop r0
    ret


; Print int in R0
print_int:
    push r0
    push r1
    push r2

    ldr r2,-1
    cmp r0,0
    bge print_int_not_neg_
    ldr r1,'-'
    str r1,[{serial}]
    mul r0,-1
    bra print_int_loop_
print_int_not_neg_:
    bne print_int_loop_
    ldr r1,'0'
    str r1,[{serial}]
    bra print_int_done_
print_int_loop_:
    ldr r1,10
    cmp r0,0
    beq print_int_print_
    push r0
    jsr mod
    add r0,'0'
    inc r2
    stb r0,r2,serial_buffer
    pop r0
    jsr div
    bra print_int_loop_
print_int_print_:
    ldb r0,r2,serial_buffer
    str r0,[{serial}]
    dec r2
    bge print_int_print_
print_int_done_:

    pop r2
    pop r1
    pop r0
    ret


; Clear the input buffer
clear_input:
    push r0

clear_input_loop_:
    str r0,[{serial_available}]
    ldr r0,[{serial_available}]
    bne clear_input_loop_

    pop r0
    ret


; Read the next integer over serial into r0
input_int:
    push r1
    push r2
    push r3

    jsr clear_input
    ldr r1,0

; Read integer into buffer
input_int_loop_:
    ldr r0,[{serial_available}]
    beq input_int_loop_
    ldr r0,[{serial}]
    cmp r1,0
    bne input_int_not_first
    cmp r0,'-'
    beq input_int_got_int_
input_int_not_first:
    cmp r0,'0'
    blt input_int_not_int_
    cmp r0,'9'
    ble input_int_got_int_
input_int_not_int_:
    str r0,[{serial_available}]
    cmp r1,1
    bgt input_int_parse_
    cmp r1,0
    beq input_int_not_int_first_
    cmp r0,'-'
    bne input_int_parse_
input_int_not_int_first_:
    ldr r1,0
    bra input_int_loop_
input_int_got_int_:
    cmp r1,9
    bgt input_int_loop_
    stb r0,r1,serial_buffer
    inc r1
    str r0,[{serial_available}]
    bra input_int_loop_

; Parse integer from buffer
input_int_parse_:
    ldr r0,0
    ldr r3,0
input_int_parse_loop_:
    ldb r2,r3,serial_buffer
    cmp r2,'-'
    beq input_int_parse_neg_
    mul r0,10
    add r0,r2
    sub r0,'0'
input_int_parse_neg_:
    inc r3
    cmp r3,r1
    blt input_int_parse_loop_

; Multiply by -1 if needed
    ldb r2,[serial_buffer]
    cmp r2,'-'
    bne input_int_not_neg_
    mul r0,-1
input_int_not_neg_:

    pop r3
    pop r2
    pop r1
    ret


    data
; Buffer for reversing integer values
serial_buffer: var[12]
