; Fancy Music Player

    jmp main
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8
    bra -8

    include "libraries/Sonic.asm"
    include "libraries/Music.asm"

main:
    ldr sp,stack ; Initialize stack

    ldr r1,test
    ldr r0,song
    jsr load_song

loop:
    jsr play_song
    cmp r0,0
    beq done

    bra loop

done: bra done

; Table of songs
songs:
    jmp test
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
test: bin "data/songs/test.bin"

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
song: var [12] ; Song struct {ptr, ptr, ptr}

stack: ; Don't put anything after this line
