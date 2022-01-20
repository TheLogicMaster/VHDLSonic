; Music

    include "Sonic.asm"


; Load song from [r1] into 3 pointer struct [r0]
; Todo: Clear APU channels?
load_song:
    push r0
    push r1
    push r2
    push r3
    push r4

    tfr r4,r1
    ldr r3,3
load_song_loop_:
    ldw r2,r1++
    beq load_song_loop_null_
    add r2,r4
load_song_loop_null_:
    str r2,r0++
    dec r3
    bne load_song_loop_

    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Play song in 3 pointer struct [r0]
; Call this continuously to update APU with song notes
; Modifies struct [r0] every invocation and clears r0 if the song is done
play_song:
    push r1
    push r2
    push r3
    push r4
    push r5

    push r0
    ldr r1,3
    ldr r5,0
play_song_loop_:
    ldr r3,r0,0
    beq play_song_loop_next_
    ldr r4,r5,{audio_channels}
    and r4,$7FF80000
    bne play_song_loop_wait_
    ldw r4,r3++
    beq play_song_track_end_
    lsl r4,19
    or r4,$80070000
    ldw r2,r3++
    or r4,r2
    str r4,r5,{audio_channels}
    str r3,r0++
    bra play_song_loop_next_
play_song_loop_wait_:
    add r0,4
    bra play_song_loop_next_
play_song_track_end_:
    str r4,r0++
play_song_loop_next_:
    add r5,4
    dec r1
    bne play_song_loop_
    pop r0

    ldr r1,3
    tfr r2,r0
play_song_check_:
    ldr r3,r2++
    bne play_song_not_done_
    dec r1
    bne play_song_check_
    ldr r0,0
play_song_not_done_:

    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    ret
