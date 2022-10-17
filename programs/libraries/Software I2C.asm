; Software I2C library

    include "Sonic.asm"

    ifndef scl=$400B8
    ifndef sda=$400BC
    ifndef scl_out=$40148
    ifndef sda_out=$4014C


; Starts an I2C write mode transmission to address r0
; Sets Zero flag if not ACKnowldged and clears it otherwise
i2c_start_write:
    push r1
    ldr r1,0
    jsr i2c_start
    pop r1
    ret


; Starts an I2C read mode transmission to address r0
; Sets Zero flag if not ACKnowldged and clears it otherwise
i2c_start_read:
    push r1
    ldr r1,1
    jsr i2c_start
    pop r1
    ret


; Begin I2C transmission to address r0 with mode r1
; Set r1 to a 0 for write mode and 1 for read, anything else is undefined behavior
; Sets Zero flag if not ACKnowldged and clears it otherwise
i2c_start:
    push r0
    push r1

; Start
    push r1
    ldr r1,1
    str r1,[{sda_out}]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ldr r1,0
    str r1,[{scl_out}]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ldr r1,1
    str r1,[{scl_out}]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    pop r1

; Address byte
    lsl r0,1
    or r0,r1
    push r0
    pop r1
    jsr i2c_send_byte

    pop r1
    pop r0
    ret


; Stops I2C transmission
i2c_stop:
    push r0

    ldr r0,1
    str r0,[{sda_out}]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ldr r0,0
    str r0,[{scl_out}]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ldr r0,0
    str r0,[{sda_out}]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    pop r0
    ret


; Sends a byte from r1 in current I2C transmission
; Sets Zero flag if not ACKnowldged and clears it otherwise
i2c_send_byte:
    push r0
    push r1

    push r1
    pop r0
    ldr r1,8
    lsl r0,24
i2c_send_byte_loop_:
    lsl r0,1
    push r0
    bhs i2c_send_bit_1_
    ldr r0,0
    bra i2c_send_byte_bit_
i2c_send_bit_1_:
    ldr r0,1
i2c_send_byte_bit_:
    jsr i2c_send_bit
    pop r0
    dec r1
    bne i2c_send_byte_loop_

; Data ACK
    ldr r1,1
    jsr i2c_send_bit
    bne i2c_send_byte_ack_
    ldr r1,0
i2c_send_byte_ack_:

    pop r1
    pop r0
    ret


; Receive a byte into r0 in the current I2C transmission
; Set r1 to 0 if this is the final byte to be received
i2c_receive_byte:
    push r2
    push r3

    ldr r0,0
    ldr r2,8
i2c_receive_byte_loop_:
    lsl r0,1
    ldr r3,1
    jsr i2c_send_bit
    bne i2c_receive_byte_0_
    or r0,1
i2c_receive_byte_0_:
    dec r2
    bne i2c_receive_byte_loop_

    ; ACK
    push r0
    ldr r0,0
    cmp r0,r1
    pop r0
    beq i2c_receive_byte_final_
    ldr r2,0
    bra i2c_receive_byte_ack_
i2c_receive_byte_final_:
    ldr r2,1
i2c_receive_byte_ack_:
    jsr i2c_send_bit

    pop r3
    pop r2
    ret


; Sends a single bit based on the Zero Flag.
; Sets Zero Flag based on read value on SCL rise
i2c_send_bit:
    push r0

; Set SDA pin
    beq send_set_sda_0_
    ldr r0,0
    str r0,[{sda_out}]
    bra send_set_sda_done_
send_set_sda_0_:
    ldr r0,1
    str r0,[{sda_out}]
send_set_sda_done_:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

; Read SDA and invert value
    ldr r0,[{sda}]
    xor r0,1
    push r0

; Set SCL high
    ldr r0,0
    str r0,[{scl_out}]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

; Set SCL low
    ldr r0,1
    str r0,[{scl_out}]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

; Set Zero flag based on read value
    pop r0
    cmp r0,0

    pop r0
    ret
