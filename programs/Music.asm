; Music
; https://github.com/robsoncouto/arduino-songs

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

; Set buzzer pin to output mode
    ldr r1,0
    ldr r0,1
    str r0,r1,{arduino_modes}

; Setup note length timer
    ldr r1,0
    ldr r0,50000
    str r0,r1,{timer_prescale}

; Setup note period timer
    ldr r1,4
    ldr r0,25
    str r0,r1,{timer_prescale}

; Setup note pause period timer
    ldr r1,8
    ldr r0,5000
    str r0,r1,{timer_prescale}

; Load initial song
    ldr r3,0

loop:
; Play current song
    jsr play_song

; Wait a second between songs
    ldr r1,0
    ldr r0,0
    str r0,r1,{timer_count}
    ldr r0,1
    str r0,r1,{timer_enable}
    ldr r0,1000
    str r0,r1,{timer_compare}
song_transition:
    ldr r0,r1,{timer_enable}
    bne song_transition

; Select next song
    ldr r0,[{switch_0}]
    bne repeat
    inc r3
    ldr r0,[{switch_1}]
    beq not_shuffle
    ldr r3,[{random}]
    and r3,$3F
not_shuffle:
    tfr r0,r3
    ldr r1,43
    jsr umod
    tfr r3,r0
repeat:

    bra loop


; Plays song in r3
play_song:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5

; Load song address
    mul r3,8
    ldr r2,songs
    add r3,r2
    add r3,4
    ldr r3,r3,0

; Initialize buzzer toggle register
    ldr r2,0

play_song_loop:
; Load and play next note
    ldr r1,0
    ldr r0,0
    str r0,r1,{timer_count}
    ldr r0,1
    str r0,r1,{timer_enable}
    ldw r5,r3++
    beq play_song_done
    str r5,r1,{timer_compare}
    ldw r4,r3++
play_song_note:

; Wait for one period of note
    ldr r1,4
    ldr r0,0
    str r0,r1,{timer_count}
    ldr r0,1
    str r0,r1,{timer_enable}
    str r4,r1,{timer_compare}
play_song_tone:
    ldr r0,r1,{timer_enable}
    bne play_song_tone

; Toggle buzzer pin
    ldr r0,0
    xor r2,1
    str r2,r0,{arduino}

; Check for skip button
    ldr r0,[{button_1}]
    bne play_song_done

; Loop until note is done
    ldr r1,0
    ldr r0,r1,{timer_enable}
    bne play_song_note

; Wait for 1/10th of note duration to add note separation
    ldr r1,8
    ldr r0,0
    str r0,r1,{timer_count}
    ldr r0,1
    str r0,r1,{timer_enable}
    str r5,r1,{timer_compare}
play_song_pause:
    ldr r0,r1,{timer_enable}
    bne play_song_pause

    bra play_song_loop

play_song_done:

    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret


; Table of songs
songs:
    jmp dragonballsuper
    jmp spongebob
    jmp asabranca
    jmp babyelephantwalk
    jmp badinerie
    jmp bloodytears
    jmp brahmslullaby
    jmp cannonind
    jmp cantinaband
    jmp doom
    jmp furelise
    jmp gameofthrones
    jmp greenhill
    jmp greensleeves
    jmp happybirthday
    jmp harrypotter
    jmp imperialmarch
    jmp jigglypuffsong
    jmp keyboardcat
    jmp merrychristmas
    jmp miichannel
    jmp minuetg
    jmp nevergonnagiveyouup
    jmp nokia
    jmp odetojoy
    jmp pacman
    jmp pinkpanther
    jmp princeigor
    jmp professorlayton
    jmp pulodagaita
    jmp silentnight
    jmp songofstorms
    jmp startrekintro
    jmp starwars
    jmp supermariobros
    jmp takeonme
    jmp tetris
    jmp thegodfather
    jmp thelick
    jmp thelionsleepstonight
    jmp vampirekiller
    jmp zeldaslullaby
    jmp zeldatheme
    jmp 0

    align 2
; Custom songs
    dragonballsuper: bin "data/songs/dragonballsuper.bin"
    spongebob: bin "data/songs/spongebob.bin"

; arduino-song songs
    asabranca: bin "data/songs/asabranca.bin"
    babyelephantwalk: bin "data/songs/babyelephantwalk.bin"
    badinerie: bin "data/songs/badinerie.bin"
    bloodytears: bin "data/songs/bloodytears.bin"
    brahmslullaby: bin "data/songs/brahmslullaby.bin"
    cannonind: bin "data/songs/cannonind.bin"
    cantinaband: bin "data/songs/cantinaband.bin"
    doom: bin "data/songs/doom.bin"
    furelise: bin "data/songs/furelise.bin"
    gameofthrones: bin "data/songs/gameofthrones.bin"
    greenhill: bin "data/songs/greenhill.bin"
    greensleeves: bin "data/songs/greensleeves.bin"
    happybirthday: bin "data/songs/happybirthday.bin"
    harrypotter: bin "data/songs/harrypotter.bin"
    imperialmarch: bin "data/songs/imperialmarch.bin"
    jigglypuffsong: bin "data/songs/jigglypuffsong.bin"
    keyboardcat: bin "data/songs/keyboardcat.bin"
    merrychristmas: bin "data/songs/merrychristmas.bin"
    miichannel: bin "data/songs/miichannel.bin"
    minuetg: bin "data/songs/minuetg.bin"
    nevergonnagiveyouup: bin "data/songs/nevergonnagiveyouup.bin"
    nokia: bin "data/songs/nokia.bin"
    odetojoy: bin "data/songs/odetojoy.bin"
    pacman: bin "data/songs/pacman.bin"
    pinkpanther: bin "data/songs/pinkpanther.bin"
    princeigor: bin "data/songs/princeigor.bin"
    professorlayton: bin "data/songs/professorlayton.bin"
    pulodagaita: bin "data/songs/pulodagaita.bin"
    silentnight: bin "data/songs/silentnight.bin"
    songofstorms: bin "data/songs/songofstorms.bin"
    startrekintro: bin "data/songs/startrekintro.bin"
    starwars: bin "data/songs/starwars.bin"
    supermariobros: bin "data/songs/supermariobros.bin"
    takeonme: bin "data/songs/takeonme.bin"
    tetris: bin "data/songs/tetris.bin"
    thegodfather: bin "data/songs/thegodfather.bin"
    thelick: bin "data/songs/thelick.bin"
    thelionsleepstonight: bin "data/songs/thelionsleepstonight.bin"
    vampirekiller: bin "data/songs/vampirekiller.bin"
    zeldaslullaby: bin "data/songs/zeldaslullaby.bin"
    zeldatheme: bin "data/songs/zeldatheme.bin"

    data
    align 4
stack: ; Don't put anything after this line
