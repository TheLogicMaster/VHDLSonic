# Audio Processing Unit

## Memory Map
| Name            | Indices | Address |
|-----------------|---------|---------|
| Audio Channel 0 | 0       | $50000  |
| Audio Channel 1 | 1       | $50004  |
| Audio Channel 2 | 2       | $50008  |

## Audio Channels
There are 3 square wave channels with constant volumes and frequencies.

## Volume
Each channel has a constant volume (bits 16 through 18) which specifies the volume of that 
particular channel. A volume envelope may later be included which would allow for an 
increasing or decreasing volume.

## Frequency
Each square wave channel has a constant period field which specifies the period of the wave 
(bits 0 to 15) in units of 44 kHz samples. A frequency sweep may later be implemented 
allowing for increasing or decreasing frequencies.

## Length
Audio channels each have length fields (bits 19 to 30) that determine the duration of a sound 
if the finite field (bit 31) set.
