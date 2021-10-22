// C Graphics Test

#include "libraries/Sonic.h"
#include "libraries/Graphics.h"

#include "data/face.h"
#include "data/face_sprite.h"

int main() {
    copy_tiles(face, 1, 1);
    copy_tiles(face_sprite, 2, 4);
    set_sprite(0, 2, 32, 32, 0, 0);
    BG_Data[0] = 1;
    Render = 1;

    while(1);
}
