    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"
    include "libraries/Math.asm"

main:
    ldr sp,stack ; Initialize stack

; Activation trigger
; Configure T0 in repeat mode to count in ms - sets sample taking at 10Hz
    ldr r0, 50000                   ; prescaler
    str r0, [{timer_prescale}]      ; write prescaler value for T0
    ldr r0, 100                     ; compare value (100ms)
    str r0, [{timer_repeat}]        ; write repeat value

; Configure T1 in one-shot mode for trigger
    ldr r0, 50                      ; prescaler
    ldr r1, 4                       ; move to next timer address
    str r0, r1, {timer_prescale}    ; wrote prescale value for T1
    ldr r0, 10                      ; trigger duration
    str r0, r1, {timer_compare}     ; write one-shot duration

; Configure GPIO - P0 used for output; P1 for input set by default
    ldr r0, 1
    str r0, {gpio_modes}            ; set P0 to output (1)

loop:
    ldr r0, 1
    str r0, [{timer_enable}]        ; enable T0
    str r0, [{gpio}]                ; set P0 high
    str r0, r1, {timer_enable}      ; enable T1
    ldr r3, 500

trigger:
    dec r3
    bhs trigger
    ldr r0, 0
    str r0, [{gpio}]                ; set P0 low
    ldr r3, 0                       ; counter

echo_pulse_begins:
    ldr r2, [{gpio1}]               ; load P1 - input
    beq echo_pulse_begins           ; keep checking P1 until it's High

echo_pulse_ends:
    inc r3                          ; increment counter
    ldr r2, [{gpio1}]               ; load P1
    bne echo_pulse_ends             ; keep checking P1 until it's Low
    ldr r0, 1
    tfr r0, r3
    ldr r1, 294                     ; sound travels at approx. 340 m/s = 29.412 µs/cm
    jsr udiv                        ; div duration in ns by 10^9 to get seconds; result is in r0

; display result to 7seg display
; mod by 100 to get hundreds, then by 10, to get tens, and the remaining is singles
    push r0                         ; save result
    ldr r1, 10                      ; load value for mod 10
    jsr umod                        ; perform mod10 to get singles
    str r0, [{seven_segment_0}]     ; display singles

    pop r0
    jsr udiv                        ; divide by 10 to isolate hundreds and tens. truncates floating point
    push r0
    jsr umod                        ; mod10 to get tens digit
    str r0, [{seven_segment_1}]     ; display tens

    pop r0
    jsr udiv                        ; divide by 10 to get hundreds digit
    str r0, [{seven_segment_2}]

sampling:
    ldr r0, [{timer_count}]         ; check if T0 has rolled over
    bne sampling
    bra loop
    data
    align 4
stack: ; Don't put anything after this line
