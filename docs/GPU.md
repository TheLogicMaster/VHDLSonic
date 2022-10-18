# Graphics Processing Unit
The GPU supports output via either the VGA port or an ILI9341 based LCD 
(Needs the parallel interface variant with 8 data lines). The selection is a constant parameter
set in the VHDL to compile the needed interface.

## Memory Map
| Name              | Indices   | Address |
|-------------------|-----------|---------|
| Render            | 0         | $30000  |
| Horizontal Scroll | 1         | $30004  |
| Vertical Scroll   | 2         | $30008  |
| Window X          | 3         | $3000C  |
| Window Y          | 4         | $30010  |
| Palette           | 5-20      | $30014  |
| Tile Data         | 21-2068   | $30054  |
| Background Data   | 2069-6164 | $32054  |
| Window Data       | 6165-7364 | $36054  |
| Sprite Data       | 7365-7428 | $37314  |

## Tiles
- 64 32-byte tiles. 4 bits per pixel allowing for a 16-color palette.
- Tile containing images with dimensions multiples of 8 can be converted to binary 
- and header files for use in programs using the **image_convert.py** script.
- Subroutines and functions are provided for copying tiles into VRAM.

## Background
- 1 byte tile index for each tile in world (64 by 64 tiles)
- Scrollable vertically and horizontally

## Window
- 1 byte tile index for each tile in window (30 by 40 tiles)
- Moveable position
- Drawn over background and sprites

## Palette
- 16 RGB888 colors
- GIMP palette file is provided for ease of use

## Sprites
- Composed of 4 sequential tiles in a 2 by 2 grid
- 9 bit x and 9 bit y coordinates
- 8 bits specifying for the first tile
- 2 bits for vertical/horizontal flip
- Priority is based on sprite index with lower ones drawn first
- Palette color zero is transparent
