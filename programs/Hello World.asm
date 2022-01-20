; Hello World

    jmp main
    jmp 0
    jmp 0
    jmp 0
    jmp 0
    jmp 0
    jmp 0
    jmp 0


    include "libraries/Sonic.asm"
    include "libraries/Print.asm"


message: db "Hello World!\n",0
message_format: db "%s %%  %c %i %x",0


main:
    ldr sp,stack

; Print string without formatting
    ldr r0,message
    jsr print

; Print format string
    tfr r2,sp
    ldr r0,$123
    push r0
    ldr r0,-123
    push r0
    ldr r0,'A'
    push r0
    ldr r0,message
    push r0
    ldr r0,message_format
    jsr printf
    tfr sp,r2

    halt


    data
stack:
