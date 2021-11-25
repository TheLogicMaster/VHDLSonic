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
print_int_loop_:
    ldr r1,10
    cmp r0,0
    beq print_int_done_
    push r0
    jsr mod
    add r0,'0'
    str r0,[{serial}]
    pop r0
    jsr div
    bra print_int_loop_
print_int_done_:

    pop r1
    pop r0
    ret


; Read the next integer over serial into r0
input_int:
; Todo
ret
