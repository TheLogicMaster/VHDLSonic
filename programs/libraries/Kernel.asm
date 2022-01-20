; Kernel

    jmp 0
    jmp program_int_1
    jmp program_int_2
    jmp program_int_3
    jmp program_int_4
    jmp program_int_5
    jmp program_int_6
    jmp program_int_7

; Allocate 4 KB for program/bootloader RAM
    data
    org $1F000
    rodata

; Include shared libraries
    include "Sonic.asm"
    include "SD.asm"
    include "Delay.asm"
    include "Serial.asm"
    include "Math.asm"
    include "Random.asm"
    include "Graphics.asm"

    data
kernel_stack:

    org $18000
program_main: var[8]
program_int_1: var[8]
program_int_2: var[8]
program_int_3: var[8]
program_int_4: var[8]
program_int_5: var[8]
program_int_6: var[8]
program_int_7: var[8]
