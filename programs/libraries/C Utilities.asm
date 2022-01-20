; C Utilities


; Todo: Optimize memcpy to utilize 32-bit word copying for center of memory block
memcpy:
    ldr y,sp,-8
    ldr x,sp,-12
    ldr r0,sp,-16
    add r0,x
memcpy_loop_:
    ldb r1,x++
    stb r1,y++
    cmp r0,x
    bne memcpy_loop_
    ret
