; Parrot

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"
    include "libraries/Print.asm"

message: db "Say something!\n", 0

main:
    ldr sp,stack ; Initialize stack

; Enable UART
    ldr r0,1
    ldr r1,4
    str r0,r1,{arduino_modes}
    str r0,[{uart_enable}]

; Print message
    ldr r0,message
    jsr print_string

loop:
    ldr r0,[{serial_available}] ; Check for bytes to read
    beq loop
    ldr r0,[{serial}] ; Read byte from serial
    str r0,[{serial}] ; Output byte to serial
    str r0,[{serial_available}] ; Pop byte from input FIFO
    bra loop

    data
stack:
