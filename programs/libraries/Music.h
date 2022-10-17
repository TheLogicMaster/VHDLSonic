// C wrapper for Music Assembly library

#ifndef MUSIC_H
#define MUSIC_H

#pragma include "libraries/Music.asm"

struct Song {
    void *track1, *track2, *track3;
}

void loadSong(struct Song *song) =
    "\tldr r0,sp,-4\n"
    "\tjsr load_song";

void playSong(struct Song *song) =
    "\tldr r0,sp,-4\n"
    "\tjsr play_song";

#endif // MUSIC_H
