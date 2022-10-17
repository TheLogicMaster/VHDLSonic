; Software SPI

; SPI serial utilities

    ifndef spi_clk=40
    ifndef spi_miso=44
    ifndef spi_mosi=48

    include "Sonic.asm"


; Setup the pins for SPI communication
spi_setup:
    push r0
    push r1

    ldr r0,1
    ldr r1,{spi_clk}
    str r0,r1,{arduino_modes}
    ldr r1,{spi_mosi}
    str r0,r1,{arduino_modes}

    ldr r0,0
    ldr r1,{spi_clk}
    str r0,r1,{arduino}

    pop r1
    pop r0
    ret


; Receive a byte from the currently enabled SPI device in r0
spi_receive_byte:
    push r1
    push r2
    push r3

    ldr r2,1
    ldr r1,{spi_mosi}
    str r2,r1,{arduino}

    ldr r0,0
    ldr r3,8
spi_receive_byte_loop_:
    ldr r2,1
    ldr r1,{spi_clk}
    str r2,r1,{arduino}

    lsl r0,1
    ldr r1,{spi_miso}
    ldr r2,r1,{arduino}
    or r0,r2

    ldr r2,0
    ldr r1,{spi_clk}
    str r2,r1,{arduino}

    dec r3
    bne spi_receive_byte_loop_

    pop r3
    pop r2
    pop r1
    ret


; Send a single byte to the currently enabled SPI slave from r0
spi_send_byte:
    push r0
    push r1
    push r2
    push r3

    ldr r1,8
    lsl r0,24
spi_send_byte_loop_:
    lsl r0,1
    bhs spi_send_byte_1_
    ldr r2,0
    bra spi_send_byte_send_
spi_send_byte_1_:
    ldr r2,1
spi_send_byte_send_:
    ldr r3,{spi_mosi}
    str r2,r3,{arduino}

    ldr r2,1
    ldr r3,{spi_clk}
    str r2,r3,{arduino}

    ldr r2,0
    ldr r3,{spi_clk}
    str r2,r3,{arduino}

    dec r1
    bne spi_send_byte_loop_

    pop r3
    pop r2
    pop r1
    pop r0
    ret
