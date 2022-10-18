# Architecture

## Specifications
- 32-bit
- 16 32-bit general purpose registers
- Big-endian
- 32-bit ALU
- On Reset, execution always starts at **0x00000000**
- 8 assignable interrupts

## Address Map
- 0x00000 to 0x17FFF: Program ROM
- 0x18000 to 0x1FFFF: Program RAM
- 0x20000 to 0x2FFFF: CPU registers
- 0x30000 to 0x3FFFF: Game console registers
- 0x40000 to 0x4FFFF: Microcontroller registers
- 0x50000 to 0x5FFFF: APU registers

## Memory
Consists of 32bit words. The input is an address which gets decoded to the index of the right memory word. In the address, the last two bits specify which byte in the mem word to read. However, since we can't read individual bytes within each mem word, we don't use the last two bits.

## Program Registers
All program registers can be controlled completely by the program, but some have specific purposes.
- **R0** - **R13**: General purpose
- **R14** (**FP**): The frame pointer
- **R15** (**SP**): The stack pointer

## Special Registers
Special registers aren't directly accessible by the program and can only be modified using special instructions.
- **PC**: 32-bit **P**rogram **C**ounter that points to the current instruction being executed.
- **F**: The status register.
- **IE**: The **I**nterrupt **E**nable register. ($20000)
- **IF**: The **I**nterrupt **F**lags register. ($20004)

## Status Flags
- **Z**: The **Z**ero flag.
- **C**: The **C**arry flag. Set if an unsigned carry took place in a previous instruction.
- **N**: The **N**egative flag. Set if the MSB was set in the result of a previous instruction.
- **V**: The o**v**erflow flag. Set if a signed overflow took place in a previous instruction.
- **I**: The Interrupt enable flag. Globally enables interrupts.

## Interrupts
- **INT0** (**Reset**): This is a non-maskable interrupt that resets the computer.
- **INT1** (**Except**): This is a non-maskable interrupt that is called when an exception occurs.
- **INT2** - **INT7**: Configurable interrupts

## CPU Memory Mapped Registers
- **0x20000**: Interrupt Enable (**IE**)
- **0x20004**: Interrupt Flags (**IF**)

## Addressing Modes

### Implicit
No parameters are required.
Example: `NOP`

### Immediate
A 32-bit immediate is read directly following the instruction as a parameter.
Example: `LDR #1234`

### Register and Immediate
A register and a 32-bit immediate are used in an operation and the result is stored in the register.
Format: (**23**-**20**) Register, (**19**-**16**) Unused
Example: `ADD R0, #123`

### Register and Register
A source register and an operand register are used in an operation and the result is stored in the source register.
Format: (**23**-**20**) Source register, (**19**-**16**) Operand register
Example: `XOR R0, R1`

### Absolute
A 32-bit value is read from the absolute memory location specified.
Format: (**23**-**20**) Register, (**19**-**16**) Unused
Example: `LDR R0, $ABCD`

### Indexed
Indexed addressing allows using a register as the address for an instruction with an optional pre/post increment or decrement.
Format: (**23**-**20**) Register, (**19**-**16**) Index register, (**15**) Pre/Post, (**14**) Increment, (**13**) Decrement
Example: `STR R0, R1+`

### Relative
Relative addressing allows for accessing an address at a 32-bit signed immediate offset from a register. This is especially useful for stack frame operations.
Format: (**23**-**20**) Register, (**3-0**) Unused
Example: `STR R0, R1, 4`

### Branching
Branch instructions take a signed 32-bit immediate offset and add it to the **PC** if the condition is true.
Example: `BNE #-63`

### Register to Register
One register is treated as an input and another is treated as the output of an operation.
Format: (**7**-**4**) Source register, (**3-0**) Destination register
Example: `MOV R0, R1`

## Instructions
| Mnemonic       | Function                            | Opcode       | Flags        | Type   | Operation Index |
|----------------|-------------------------------------|--------------|--------------|--------|-----------------|
| NOP            | No operation                        | $00 $**      |              | Misc   |                 |
| BEQ rel        | Branch if equal                     | $01 $**      | Z==1         | Flow   | 0               |
| BNE rel        | Branch if not equal                 | $02 $**      | Z==0         | Flow   | 1               |
| BHS rel        | Branch if unsigned higher or same   | $03 $**      | C==1         | Flow   | 2               |
| BLO rel        | Branch if unsigned lower            | $04 $**      | C==0         | Flow   | 3               |
| BMI rel        | Branch if minus                     | $05 $**      | N==1         | Flow   | 4               |
| BPL rel        | Branch if plus                      | $06 $**      | N==0         | Flow   | 5               |
| BVS rel        | Branch if overflow set              | $07 $**      | V==1         | Flow   | 6               |
| BVC rel        | Branch if overflow clear            | $08 $**      | V==0         | Flow   | 7               |
| BHI rel        | Branch if unsigned higher           | $09 $**      | C & ~Z       | Flow   | 8               |
| BLS rel        | Branch if unsigned lower or same    | $0A $**      | ~C &#124; Z  | Flow   | 9               |
| BGE rel        | Branch if signed greater or equal   | $0B $**      | N==V         | Flow   | 10              |
| BLT rel        | Branch if signed less               | $0C $**      | N≠V          | Flow   | 11              |
| BGT rel        | Branch if signed greater            | $0D $**      | ~Z & N==V    | Flow   | 12              |
| BLE rel        | Branch if signed less or equal      | $0E $**      | Z &#124; N≠V | Flow   | 13              |
| BRA rel        | Branch always                       | $0F $**      |              | Flow   | 14              |
| LDR r, imm     | Load immediate into register        | $12 $**      | Z            | Memory |                 |
| LDB r, addr    | Load byte from absolute address     | $13 $r*      | Z            | Memory |                 |
| LDW r, addr    | Load word from absolute address     | $14 $r*      | Z            | Memory |                 |
| LDR r, addr    | Load from absolute address          | $15 $r*      | Z            | Memory |                 |
| LDB r, +index- | Load byte from indexed address      | $16 $rr %pid | Z            | Memory |                 |
| LDW r, +index- | Load word from indexed address      | $17 $rr %pid | Z            | Memory |                 |
| LDR r, +index- | Load from indexed address           | $18 $rr %pid | Z            | Memory |                 |
| LDB r, r, rel  | Load byte from relative address     | $19 $rr      | Z            | Memory |                 |
| LDW r, r, rel  | Load word from relative address     | $1A $rr      | Z            | Memory |                 |
| LDR r, r, rel  | Load from relative address          | $1B $rr      | Z            | Memory |                 |
| STB r, addr    | Store byte into absolute address    | $1C $r*      |              | Memory |                 |
| STW r, addr    | Store word into absolute address    | $1D $r*      |              | Memory |                 |
| STR r, addr    | Store into absolute address         | $1E $r*      |              | Memory |                 |
| STB r, +index- | Store byte into indexed address     | $1F $rr %pid |              | Memory |                 |
| STW r, +index- | Store word into indexed address     | $20 $rr %pid |              | Memory |                 |
| STR r, +index- | Store into indexed address          | $21 $rr %pid |              | Memory |                 |
| STB r, r, rel  | Store byte into relative address    | $22 $rr      |              | Memory |                 |
| STW r, r, rel  | Store word into relative address    | $23 $rr      |              | Memory |                 |
| STR r, r, rel  | Store into relative address         | $24 $rr      |              | Memory |                 |
| TFR r, r       | Transfer one register to another    | $25 $rr      |              | Misc   |                 |
| MUL r, imm     | Multiply register by immediate      | $26 $r*      | Z            | ALU    | 0               |
| MUL r, r       | Multiply register by register       | $27 $rr      | Z            | ALU    | 0               |
| ADD r, imm     | Add immediate to register           | $28 $r*      | ZCNV         | ALU    | 1               |
| ADD r, r       | Add register to register            | $29 $rr      | ZCNV         | ALU    | 1               |
| ADC r, imm     | Add immediate and carry to register | $2A $r*      | ZCNV         | ALU    | 2               |
| ADC r, r       | Add register and carry to register  | $2B $rr      | ZCNV         | ALU    | 2               |
| SUB r, imm     | Subtract immediate from register    | $2C $r*      | ZCNV         | ALU    | 3               |
| SUB r, r       | Subtract register from register     | $2D $rr      | ZCNV         | ALU    | 3               |
| SBC r, imm     | Subtract immediate and borrow       | $2E $r*      | ZCNV         | ALU    | 4               |
| SBC r, r       | Subtract register and borrow        | $2F $rr      | ZCNV         | ALU    | 4               |
| AND r, imm     | AND register with immediate         | $30 $r*      | Z            | ALU    | 5               |
| AND r, r       | AND register with register          | $31 $rr      | Z            | ALU    | 5               |
| OR r, imm      | OR register with immediate          | $32 $r*      | Z            | ALU    | 6               |
| OR r, r        | OR register with register           | $33 $rr      | Z            | ALU    | 6               |
| XOR r, imm     | XOR register with immediate         | $34 $r*      | Z            | ALU    | 7               |
| XOR r, r       | XOR register with register          | $35 $rr      | Z            | ALU    | 7               |
| LSL r, imm     | Logical shift left by immediate     | $36 $r*      | ZC           | ALU    | 8               |
| LSL r, r       | Logical shift left by register      | $37 $rr      | ZC           | ALU    | 8               |
| LSR r, imm     | Logical shift right by immediate    | $38 $r*      | ZC           | ALU    | 9               |
| LSR r, r       | Logical shift right by register     | $39 $rr      | ZC           | ALU    | 9               |
| ASR r, imm     | Arithmetic shift right by immediate | $3A $r*      | ZC           | ALU    | 10              |
| ASR r, r       | Arithmetic shift right by register  | $3B $rr      | ZC           | ALU    | 10              |
| CMP r, imm     | Compare register with immediate     | $3C $r*      | ZCNV         | ALU    | 3               |
| CMP r, r       | Compare register with register      | $3D $rr      | ZCNV         | ALU    | 3               |
| INC r          | Increment register                  | $3E $r*      | ZCNV         | ALU    | 1               |
| DEC r          | Decrement register                  | $3F $rr      | ZCNV         | ALU    | 3               |
| SEI            | Set interrupt enable flag           | $40 $**      | I            | Flags  |                 |
| CLI            | Clear interrupt enable flag         | $41 $**      | I            | Flags  |                 |
| SEC            | Set carry flag                      | $42 $**      | C            | Flags  |                 |
| CLC            | Clear carry flag                    | $43 $**      | C            | Flags  |                 |
| PUSH r         | Push register to stack              | $44 $r*      |              | Stack  |                 |
| POP r          | Pop register from stack             | $45 $r*      |              | Stack  |                 |
| JMP addr       | Jump to absolute address            | $46 $**      |              | Flow   |                 |
| JMP r          | Jump to address in register         | $47 $r*      |              | Flow   |                 |
| JSR addr       | Jump to subroutine                  | $48 $**      |              | Flow   |                 |
| RET            | Return from subroutine              | $49 $**      |              | Flow   |                 |
| INT imm        | Trigger interrupt                   | $4A $**      | I            | Flow   |                 |
| RTI            | Return from interrupt               | $4B $**      | I            | Flow   |                 |
| HALT           | Halt CPU execution                  | $4C $**      |              | Misc   |                 |
