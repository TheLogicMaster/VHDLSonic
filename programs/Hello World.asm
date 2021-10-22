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


message: db "Hello World!\n",0

main:
    ldr r2,message
print:
    inc r2
    ldb r3,r2,-1
    str r3,[{serial}]
    bne print

    halt
