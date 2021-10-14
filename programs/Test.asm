    jmp main
    jmp interrupt
    jmp 0
    jmp 0
    jmp 0
    jmp 0
    jmp 0
    jmp 0

main:
    ldr r0,%10
    str r0,[{IE}]
    sei
    sec
    int 1
    ldb r1,$FF

    ldr r0,123
    bne rel
    str r0,[$10000]
    halt

rel:
    ldr r1,$FF
    str r1,[$10000]
    tfr r0,r1
    add r0,$1
    add r0,r0
    sei

    cli
    sec
    clc
    push r0
    push r1
    pop r2
    pop r3
    inc r4
    dec r5
    ldr r6,jump2
    jmp r6
    halt

jump2:
    ldr r7,$ABCD
    jsr routine
    ldr r8,data
    ldr r9,r8,1
    ldr x,data
    ldr y,data
    ldr r10,x++
    ldr r11,--y
    ldb r0,$DD
    ldw r1,$EEEE
    ldr r2,$FFFFFFFF
    str r2,[variable]
    stw r1,[variable]
    stb r0,[variable]
    halt

routine:
    ldr r8,$1234
    ret

    halt
interrupt:
    ldr fp,$ABCD
    clc
    rti

data:
    db $12,$34,$56,$78,$9A,$BC,$DE,$F0

    data
    var[4]
variable: var[4]
