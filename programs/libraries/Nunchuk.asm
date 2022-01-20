; Nunchuck --- Provides support for Wii remote peripherals like the Nunchuck over I2C

    include "Software I2C.asm"
    include "Delay.asm"


; Initialize the connected nunchuck
nunchuck_init:
    push r0
    push r1

    ldr r0,$52 ; Nunchuck address

    jsr i2c_start_write
    ldr r1,$F0
    jsr i2c_send_byte
    ldr r1,$55
    jsr i2c_send_byte
    jsr i2c_stop

    jsr i2c_start_write
    ldr r1,$FB
    jsr i2c_send_byte
    ldr r1,$00
    jsr i2c_send_byte
    jsr i2c_stop

    pop r1
    pop r0
    ret


; Retreives data from nunchuck
; Uses delays
nunchuck_update:
    push r0
    push r1
    push r2

; Set read address to 0
    ldr r0,$52 ; Nunchuck address
    jsr i2c_start_write
    ldr r1,$0
    jsr i2c_send_byte
    jsr i2c_stop

    ldr r0,1
    jsr sleep_millis

; Read 6 bytes
    ldr r0,$52 ; Nunchuck address
    jsr i2c_start_read
    ldr r1,5
    ldr r2,nunchuck_data_0_
nunchuck_update_loop_:
    jsr i2c_receive_byte
    stb r0,r2++
    dec r1
    bhs nunchuck_update_loop_
    jsr i2c_stop

    pop r2
    pop r1
    pop r0
    ret


; Retrieves the current nunchuck C button state in r0
; Sets Zero flag based on state
nunchuck_get_c_button:
    ldb r0,[nunchuck_data_5_]
    lsr r0,1
    and r0,$1
    xor r0,$1
    ret


; Retrieves the current nunchuck Z button state in r0
; Sets Zero flag based on state
nunchuck_get_z_button:
    ldb r0,[nunchuck_data_5_]
    and r0,$1
    xor r0,$1
    ret


    data
nunchuck_data_0_:
; The joystick X value
nunchuck_joystick_x: var
nunchuck_data_1_:
; The joystick Y value
nunchuck_joystick_y: var
nunchuck_data_2_:
; The gyro X value
nunchuck_gyro_x: var
nunchuck_data_3_:
; The gyro Y value
nunchuck_gyro_y: var
nunchuck_data_4_:
; The gyro Z value
nunchuck_gyro_z: var
nunchuck_data_5_: var
