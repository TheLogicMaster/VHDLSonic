# User Manual

## About the Project
The main premise of the project is to create a modular 32-bit CPU that interfaces with memory 
mapped peripherals to accomplish microcontroller and retro console functionality. An FPGA based 
hardware implementation and an emulated software implementation are provided. It comes with a full
suite of software to develop for said hardware platform. With support for three languages, 
a fully synthesizable computer with a custom architecture, an emulator/debugger, an IDE plugin, and
a provided software library with utilities, examples and games, it could be considered a complete platform. 
It was based around
the DE10-Lite dev board specifically, since it has a massive ~200KB of block RAM, which is mostly
eaten up for the ROM, RAM, and VRAM. As for the name of the project, it was the team name of the
Senior Design project that yielded this monster. As a four-person, two semester project, this would
still have been a beast, but it was in effect a one-man team. 

## Setup and Installation
For developing just for the emulator, only the **Core** **Software** section is required. 
If FPGA microcontroller development is required, the **FPGA Software** section should also be followed.

### Core Software
- Clone the repo
- Install a Jetbrains IDE with Python support (Pycharm, preferably)
- Install the Jetbrains IDE plugin from the repo Releases page or build manually
- Get the Emulator. Either find it on the Releases page and put it (With the DLLs on Windows) 
into the `emulator/build` directory or build it manually based on the GitHub workflow. If on Linux,
install the dependencies from the `CMakeLists.txt` file.
- Get the VBCC compiler binary. Either find it in the repo Releases and put it into `vbcc/bin` 
or build it manually by downloading the source from [here](http://sun.hasenbraten.de/vbcc/). 
It needs to be extracted into the __vbcc__ directory and built with 
`make TARGET=sonic bin/vbccsonic` from said directory.
- Set the paths to the assembler, emulator, and vbcc executables in the IDE plugin settings.

### FPGA Software
- Install Quartus Prime II with Max 10 device support and USB Blaster driver
- WSL is needed for Windows for the shell scripts
- Open `fpga/fpga.qpf` in Quartus, open `adc.qsys` and `uart.qsys`, and regenerate them
as VHDL. Compile to ensure that everything is functional.

## Software Suite

### Assembler
The Assembler program is a Python script that not only assembles programs into machine code, 
but also acts as a common entry point for the compiler, emulator, and deployment scripts. 
Can be used automatically by the IDE plugin or invoked manually using its command line interface. 
To see all available options, run the help command(`python3 assembler.py --help`). Plenty of
example programs and libraries are provided to demonstrate what it's capable of. The assembly
syntax itself is a bit quirky, since it's a mix of the different assembler syntax I'm familiar
with, along with custom features for the project.

#### Common Options
- Program type (--type): The type of program to assemble/compile
- Run program (--run): Run the assembled program in the emulator
- FPGA operation (--fpga): Flash and possibly debug the FPGA microcontroller
- Debug symbols (--debug): Generate debug symbols

### Jetbrains IDE Plugin
The IDE plugin provides support for developing with the custom Assembly language that is used 
for the project as well as managing run configurations. Pressing the green run button in the
code editor sidebar with an Assembly program open will create a run configuration for running
said program in the emulator. Adjust the parameters to enable debug symbols or flash the dev
board. To create a new assembly or C program, new-file templates are provided. There is only
basic syntax highlighting support for C and no automatic run configuration creation support,
so manual configuration is required by duplicating an assembly one and changing the type. The
same is true for creating programs using the Basic compiler. 
The plugin also offers other convenient features like navigating to symbol definitions. 

### Emulator
The emulator is built in ImGui and provided several preset layouts of the provided windows for
different development configurations. It has Emscripten support, so a web demo is provided that
contains the main demos. The emulator can be launched directly, but is most conveniently used
by the assembler by launching IDE run configurations. It provides basic assembly and C debugging
functionalities to greatly help with debugging programs. The emulator CPU execution works a bit
different from the synthesized CPU in that all instructions take a single emulated clock cycle,
but it only runs at 1 MHz, so the FPGA runs programs around 10x the speed, though instruction
cycles vary greatly and there is no instruction pipelining.

### C Compiler
C language support is provided in the form of a custom VBCC compiler backend that produces
compatible assembly. C language support is limited to part of C99 and earlier, and there is
no linker, so programming is a bit limited to simple programs. The generated assembly is not
optimized, so redundant register transfers and such will be present. Interrupt table insertion
is also done with function names that correlate to known ISR names. There is a very, very limited
subset of a standard library available in the project libraries directory. 

### C and Assembly Software Libraries
Various libraries are provided for accomplishing common tasks and interfacing with the built-in
peripherals. C wrappers are typically provided to wrap the assembly implementations. The
Python utility scripts are useful for importing binary data into programs or converting music/graphics
into usable formats. See the many example programs for useful examples.
- __Sonic__: Various global variables for memory mapped I/O
- __Graphics__: Routines for interfacing with the GPU to draw sprites and backgrounds (See the games) 
- __Music__: Routines for playing music with the APU (See the Music Player programs)
- __Math__: Routines for modulus and division (Comically inefficient, can take hours at worst)
- __Kernel__: Combined with the bootloader program, it provides "shared-library" functionality to cut
down on program binaries and allows loading programs from an SD card.
- __ILI9341__: A software driver for the LCD used by the GPU.
- __Print__: Basic printf/sprintf functionality.
- __Random__: Seeds the LFSR randomization hardware.
- __RTOS__: A simple RTOS implementation
- __SD__: A basic SD card reading library
- __Serial__: Utilities for printing numbers and strings over UART
- __Software I2C__: A purely-software I2C implementation
- __Software SPI__: A purely-software SPI implementation
- __SSD1306__: A simple OLED driver library

### Utility Scripts
An assortment of Python and Bash scripts are used in the project to work with binary formats and 
interface with the FPGA development tools. The names/header comments should be self-explanatory.

## Development

### Program Development
Support for C, Assembly, and BASIC development is provided. 

### Emulation Debugging
Especially with debug symbols, the emulator debugging experience is quite good. It's certainly not
to the level of GDB based debugging, but it's good in terms of retro console emulator debuggers. This
allows inspecting the relevant emulated internals of the GPU and APU, as well as the full CPU state.
Along with a disassembler and C source code debug symbols, setting breakpoints and debugging C or
assembly programs is a relatively good experience, all things considered. There are keyboard shortcuts
for common actions like running to the next breakpoint and the arrow keys are bound to GPIO pins
for game controller support. 

### Hardware Debugging
Good luck. The FPGA interfaces are super sketchy and unreliable, plus the debug register implementation
is also buggy and behaves differently every recompile. The approach taken was to use the proprietary,
no documentation provided Altera USB to JTAG interface for dumping registers, accessing memory, and
setting debug/breakpoint registers. This is all handled by the assembler script with various bash and
TCL scripts. When it works, it allows a slightly slower debugging experience than using the emulator,
but everything else should work. The emulator runs in a frontend-only mode where it is actually
just displaying data received from the assembler over a simple, bidirectional STDIO protocol. The
emulator handles bridging the FPGA interfaces with the emulator frontend. 

## Attributions
- [NES Font](https://fontstruct.com/fontstructions/show/406653/nintendo_nes_font)
- [Lospec Palette](https://lospec.com/palette-list/4-bit-rgb)
- [VBCC](http://sun.hasenbraten.de/vbcc/)
