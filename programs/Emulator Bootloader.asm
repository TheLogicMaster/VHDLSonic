; Emulator Bootloader

    include "libraries/Kernel.asm"

    align 4
    program: bin "build/Blink.img"
    program_end: db 0

entry:
    ldr r1,program
    ldr r2,program_end
    ldr r3,$18000
copy_program:
    ldr r0,r1++
    str r0,r3++
    cmp r1,r2
    blo copy_program

    jmp program_main

; Hijack entry point
    org $0
    jmp entry
