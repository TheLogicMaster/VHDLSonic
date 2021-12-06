; Pulse LED connected to GPIO pin 0

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"

main:
    ldr sp,stack ; Initialize stack

; Set up PWM on GPIO pin 0
    ldr r0,1
    ldr r1,0
    str r0,r1,{gpio_modes}
    str r0,r1,{gpio}
    str r0,r1,{pwm_enable}

; Set initial values for counting logic
    ldr r0,$0
    ldr r2,1

loop:
; Set PWM duty cycle
    str r0,r1,{pwm_duty}

; A bit of delay
    ldr r3,20000
delay:
    dec r3
    bne delay

; Update output value
    add r0,r2
    cmp r0,0
    blt toggle
    cmp r0,$FF
    bgt toggle
    bra loop
toggle:
    mul r2,-1
    add r0,r2
    bra loop

    data
    align 4
stack: ; Don't put anything after this line
