# Basic

## Basic Basics
- Variables are all 32-bit integers
- Case-insensitive
- Single quote for line comments
- Up to 14 arithmetic operations per line
- Compiled to Assembly

## Commands
| Command                    | Function                                |
|----------------------------|-----------------------------------------|
| GOTO @label                | Jump to label                           |
| INPUT var                  | Input integer from serial               |
| GOSUB @label               | Jump to subroutine at label             |
| RETURN                     | Return from subroutine                  |
| END                        | End program                             |
| PRINT var                  | Print variable to serial                |
| PRINT "string"             | Print string to serial                  |
| INC var                    | Increment variable                      |
| DEC var                    | Decrement variable                      |
| SETLED led, value          | Set an LED                              |
| SETSEVENSEG display, value | Set seven segment display               |
| SETGPIO pin, value         | Set a GPIO pin                          |
| SETGPIOMODE pin, value     | Set a GPIO pin to input or output mode  |
| SETARDUINO pin, value      | Set an Arduino pin                      |
| SETARDUINOMODE pin, value  | Set Arduino pin to input or output mode |
| GETLED var, led            | Load LED value into variable            |
| GETSEVENSEG var, display   | Load seven segment value into variable  |
| GETGPIO var, pin           | Load GPIO value into variable           |
| GETGPIOMODE var, pin       | Load GPIO mode into variable            |
| GETARDUINO var, pin        | Load Arduino value into variable        |
| GETARDUINOMODE var, pin    | Load Arduino mode into variable         |
| SEEDRNG seed               | Seed RNG with value                     |
| RANDOM var                 | Load random value into variable         |
| EXITWHILE                  | Exit the current WHILE loop             |
| EXITFOR                    | Exit the current FOR loop               |
| EXITDO                     | Exit the current DO loop                |

## Operators

| Operator | Function               | Precedence |
|----------|------------------------|------------|
| &#124;   | Logical OR             | 11         |
| &&       | Logical AND            | 10         |
| or       | Bitwise OR             | 9          |
| xor      | Bitwise XOR            | 8          |
| and      | Bitwise AND            | 7          |
| ==       | Equality               | 6          |
| ≠        | Inequality             | 6          |
| ≥        | Greater than or equal  | 5          |
| ≤        | Less than or equal     | 5          |
| \>       | Greater than           | 5          |
| <        | Less than              | 5          |
| <<       | Arithmetic shift left  | 4          |
| \>>      | Arithmetic shift right | 4          |
| -        | Subtraction            | 3          |
| +        | Addition               | 3          |
| *        | Multiplication         | 2          |
| /        | Division               | 2          |
| mod      | Modulo                 | 2          |
| !        | Logical NOT            | 1          |
| not      | Bitwise NOT            | 1          |

## Variables

Variables are all initialized to zero and no variable declaration is needed. Variable assignments 
are in the form: 

```basic
<var> = <expression>
```

## Control Flow

### Inline IF statement

```basic
if <expression> then <statement>
```

### Inline IF-ELSE statement

```basic
if <expression> then <statement> else <statement>
```

### Multi-line IF-ELSEIF-ELSE statement

```basic
if <expression> then
	<statements>
elseif <expression> then
	<statements>
else
	<statements>
endif
```

### GOTO

```basic
@loop
<statements>
goto @loop
```

### GOSUB

```basic
gosub @subroutine
end

@subroutine
<statements>
return
```

### WHILE loop

```basic
while <expression>
	<statements>
wend
```

### FOR loop default step

```basic
for <var> = <start_val> to <end_val>
	<statements>
next

```

### FOR loop custom step

```basic
for <var> = <start_val> to <end_val> step <const_increment>
	<statements>
next
```

### DO-WHILE loop

```basic
do
	<statements>
loop while <expression>
```

### DO-UNTIL loop

```basic
do
	<statements>
loop until <expression>
```
