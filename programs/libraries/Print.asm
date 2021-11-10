; Print


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
