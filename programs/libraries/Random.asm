; Random


; Seeds the random number generator with the ADC
seed_rng:
    push r0
    push r1

; Wait for ADC values
    ldr r1,100
seed_rng_delay_:
    dec r1
    bne seed_rng_delay_

; Seed RNG with ADC
    ldr r0,[{adc_0}]
    ldr r1,[{adc_1}]
    lsl r1,8
    or r0,r1
    ldr r1,[{adc_2}]
    lsl r1,16
    or r0,r1
    ldr r1,[{adc_3}]
    lsl r1,24
    or r0,r1
    str r0,[{random}]

    pop r1
    pop r0
    ret
