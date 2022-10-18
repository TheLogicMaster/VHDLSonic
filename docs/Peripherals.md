# Peripherals

## Memory Map
| Name             | Index   | Base Address | C Name           |
|------------------|---------|--------------|------------------|
| LEDs             | 0-9     | $40000       | LEDs             |
| Seven Segments   | 10-15   | $40028       | Seven_Segment    |
| GPIO             | 16-51   | $40040       | GPIO             |
| GPIO Modes       | 52-87   | $400D0       | GPIO_Modes       |
| Arduino          | 88-103  | $40160       | Arduino          |
| Arduino Modes    | 104-119 | $40416       | Arduino_Modes    |
| Switches         | 120-129 | $401E0       | Switches         |
| Buttons          | 130-131 | $40208       | Buttons          |
| Serial           | 132     | $40210       | Serial           |
| Serial Available | 133     | $40214       | Serial_Available |
| Serial Full      | 134     | $40218       | Serial_Full      |
| UART Enable      | 135     | $4021C       | UART_Enable      |
| ADCs             | 136-141 | $40220       | ADC              |
| PWM Enable       | 142-149 | $40238       | PWM_Enable       |
| PWM Duty         | 150-157 | $40258       | PWM_Duty         |
| Timer IE         | 158     | $40278       | Timer_IE         |
| Timer IF         | 159     | $4027C       | Timer_IF         |
| Timer Repeat     | 160-167 | $40280       | Timer_Repeat     |
| Timer Count      | 168-175 | $402A0       | Timer_Count      |
| Timer Prescale   | 176-183 | $402C0       | Timer_Prescale   |
| Timer Enable     | 184-191 | $402E0       | Timer_Enable     |
| Timer Compare    | 192-199 | $40300       | Timer_Compare    |

## UART Serial
The serial interface provides at least 64 byte input and output FIFO buffers. To write to the serial 
interface, read in `serial_full` to check if the output buffer is full then write to `serial` to 
output an 8-bit value. To read from the serial interface, first read from `serial_available` to 
check the number of bytes available to read, read from `serial` to read the byte from the top of 
the buffer, then write to `serial_available` to pop one byte from the top of the buffer. For 
using Serial on the dev board, the TX pin (Arduino header pin 1) needs to be set to output 
mode and `uart_enable` needs to be set to 1.

## GPIO
GPIO on the board is split into `gpio` and `arduino`, where `gpio` refers to the 40 pin header and 
`arduino` refers to the 16 I/O pins in the Arduino Uno header. The `gpio_modes` and `arduino_modes` 
control whether an I/O pin is in input mode or output mode. Input mode (0) is the default.
In the 40-pin header, 4 are reserved for power (5V, 3.3V, 2xGND). The memory space for 36 usable pins 
consists of 4 bytes per pin.

## Analog to Digital Converters
The dev board as 6 ADC channels broken out in the Arduino header. These each have 12-bits of precision
and need a few dozen or so cycles of delay before they can be used reliably.

## PWM
8-bit PWM is available on the first 8 GPIO pins. If the pin is set to output mode and its respective PWM
channel is enabled, the output will be pulsed at the specified 8-bit duty cycle.

## Timers
There are 8 timers that are each fully configurable. Timers are either in one-shot mode or repeating mode.
In repeating mode, after reaching the compare register value the count value rolls over to zero and the 
interrupt flag is set.
In one-shot mode, the same thing happens but additionally the timer enable register gets set to zero.
The timer prescale value controls the divider that is applied to the 50 MHz clock before incrementing 
the count register.
The Timer_IE flags controls whether timer interrupt flags will trigger the CPU timer interrupt.
