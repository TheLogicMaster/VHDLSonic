; SD card utility functions for SDHC/SDXC cards

; Reference: https://github.com/arduino-libraries/SD/blob/master/src/utility/Sd2Card.cpp

    ifndef sd_cs=52

    include "Software SPI.asm"


; Reset and initialize the SD card
setup_sd_card:
    push r0
    push r1

    jsr spi_setup

    ldr r0,1
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

    ldr r0,1
    ldr r1,{sd_cs}
    str r0,r1,{arduino_modes}

; Dummy bytes for 74+ clock cycles
    ldr r0,$FF
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte

; Start communication with card
    ldr r0,0
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

; Send CMD0 to reset card
setup_sd_card_reset_:
    ldr r0,$FF
    jsr spi_send_byte
    ldr r0,$40
    jsr spi_send_byte
    ldr r0,$00
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    ldr r0,$95
    jsr spi_send_byte
    jsr sd_get_response
    beq setup_sd_card_reset_
    cmp r0,$1
    bne setup_sd_card_reset_

; Send CMD8 to get card version info (Not actually used for simplicity since only version 2 and up is supported)
    ldr r0,$FF
    jsr spi_send_byte
    ldr r0,$48
    jsr spi_send_byte
    ldr r0,$00
    jsr spi_send_byte
    jsr spi_send_byte
    ldr r0,$01
    jsr spi_send_byte
    ldr r0,$AA
    jsr spi_send_byte
    ldr r0,$87
    jsr spi_send_byte
    jsr sd_get_response
    jsr spi_receive_byte
    jsr spi_receive_byte
    jsr spi_receive_byte
    jsr spi_receive_byte

; Initialize the card and wait for it to be ready
setup_sd_card_init_:
; Send CMD55
    ldr r0,$FF
    jsr spi_send_byte
    ldr r0,$77
    jsr spi_send_byte
    ldr r0,$00
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr sd_get_response
    beq setup_sd_card_init_

; Send ACMD41
    ldr r0,$FF
    jsr spi_send_byte
    ldr r0,$69
    jsr spi_send_byte
    ldr r0,$40
    jsr spi_send_byte
    ldr r0,$00
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    jsr sd_get_response
    beq setup_sd_card_init_
    cmp r0,$0
    bne setup_sd_card_init_

; End communication with card
    ldr r0,1
    ldr r1,{sd_cs}
    str r0,r1,{arduino}

    pop r1
    pop r0
    ret


; Send CMD58 command to get SD card info.
; Fills A, B, H, and L with the 4 received bytes, repectively.
; Sets Zero flag upon failure
;get_sd_card_info:
;    ldr $0,A
;    out {sd_cs},A
;
;    ldr $FF,A
;    jsr spi_send_byte
;    ldr $7A,A
;    jsr spi_send_byte
;    ldr $00,A
;    jsr spi_send_byte
;    jsr spi_send_byte
;    jsr spi_send_byte
;    jsr spi_send_byte
;    jsr spi_send_byte
;    jsr sd_get_response
;    jr get_sd_card_info_read_,nZ
;    ldr $0,A
;    ret
;get_sd_card_info_read_:
;    jsr spi_receive_byte
;    push A
;    jsr spi_receive_byte
;    push A
;    jsr spi_receive_byte
;    push A
;    jsr spi_receive_byte
;    push A
;
;    ldr $1,A
;    out {sd_cs},A
;
;    pop L
;    pop H
;    pop B
;    pop A
;
;    ret


; Requests a read of block at the index in r0 and waits for data start
; Uses timer 1 with 600 ms timeout
; Sets Zero flag upon failure
sd_read_block:
    push r0

; CMD17 to request single block read
    ldr r0,$FF
    jsr spi_send_byte
    ldr r0,$51
    jsr spi_send_byte
    ldr r0,$00
    jsr spi_send_byte
    jsr spi_send_byte
    jsr spi_send_byte
    pop r0
    push r0
    jsr spi_send_byte
    ldr r0,$00
    jsr spi_send_byte
    jsr sd_get_response
    bne sd_read_block_wait_
    pop r0
    ret
sd_read_block_wait_:
    jsr sd_data_block_wait

    pop r0
    ret


; Wait for data block start.
; Uses timer 7 for a 600 ms timeout.
; Sets the Zero flag if it times out.
sd_data_block_wait:
    push r0
    push r1
    ldr r1,$1C
    ldr r0,600
    str r0,r1,{timer_compare}
    ldr r0,50000
    str r0,r1,{timer_prescale}
    ldr r0,0
    str r0,r1,{timer_count}
    ldr r0,1
    str r0,r1,{timer_enable}
sd_data_block_wait_loop_:
    jsr spi_receive_byte
    cmp r0,$FE
    beq sd_data_block_wait_done_
    ldr r0,r1,{timer_enable}
    bne sd_data_block_wait_loop_
    ldr r0,$0
    pop r1
    pop r0
    ret
sd_data_block_wait_done_:
    ldr r0,$1
    pop r1
    pop r0
    ret


; Wait up to 256 clk cycles for an SD card reponse to a command and return it in r0
; Zero flag is set upon failure
sd_get_response:
    push r1
    ldr r1,$FF
sd_get_response_loop_:
    dec r1
    beq sd_get_response_timeout_
    jsr spi_receive_byte
    push r0
    and r0,$80
    pop r0
    bne sd_get_response_loop_
    ldr r1,$1
    pop r1
    ret
sd_get_response_timeout_:
    ldr r0,$0
    pop r1
    ret
