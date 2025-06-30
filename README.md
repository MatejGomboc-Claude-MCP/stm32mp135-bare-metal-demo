# STM32MP135 Bare Metal Demo

A minimal bare metal example for the STM32MP135 Cortex-A7 processor using modern C++17, CMake, and VSCode. This demo boots the processor, runs some C++ code, and then enters an infinite loop.

## Overview

This project demonstrates:
- How to create a minimal bootable image for STM32MP135
- The STM32 boot header format required by the ROM bootloader 
- Basic ARM Cortex-A7 exception vectors
- Using modern C++17 in a bare metal environment
- CMake cross-compilation for ARM
- VSCode integration for embedded development

## Prerequisites

### Hardware
- STM32MP135F-DK Discovery Kit (or compatible board)
- Micro SD card (any size)
- Micro USB cable for power

### Software (Windows 11)
- **ARM GNU Toolchain**: [Download here](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
  - Choose "arm-none-eabi" Windows hosted version
  - Add to PATH after installation
- **CMake**: [Download here](https://cmake.org/download/)
  - Version 3.20 or later
  - Add to PATH during installation
- **Ninja Build**: [Download here](https://ninja-build.org/)
  - Extract and add to PATH
- **VSCode**: [Download here](https://code.visualstudio.com/)
  - The project includes recommended extensions
- **STM32CubeProgrammer**: [Download from ST](https://www.st.com/en/development-tools/stm32cubeprog.html)

## Project Structure

```
├── .vscode/              # VSCode configuration
│   ├── settings.json     # Project settings
│   ├── tasks.json        # Build tasks
│   ├── c_cpp_properties.json  # IntelliSense config
│   └── extensions.json   # Recommended extensions
├── cmake/
│   └── arm-none-eabi-toolchain.cmake  # CMake toolchain file
├── boot.S                # ARM assembly startup code
├── main.cpp              # C++ entry point
├── startup.cpp           # C++ runtime initialization
├── linker.ld             # Linker script
├── CMakeLists.txt        # CMake build configuration
└── README.md             # This file
```

## Building with VSCode

1. **Open the project in VSCode**
   ```cmd
   code .
   ```

2. **Install recommended extensions** when prompted

3. **Configure CMake** (happens automatically on open, or press `Ctrl+Shift+P` → "CMake: Configure")

4. **Build the project** (press `Ctrl+Shift+B` or click the Build button in the status bar)

The output files will be in the `build` directory:
- `stm32mp135-bare-metal.elf` - ELF file with debug symbols
- `stm32mp135-bare-metal.stm32` - Binary file for flashing
- `stm32mp135-bare-metal.map` - Linker map file

## Building from Command Line

```cmd
# Create build directory
mkdir build
cd build

# Configure CMake
cmake -G Ninja ..

# Build
ninja

# Output files are now in the build directory
```

## How It Works

1. **ROM Bootloader**: The STM32MP1 has a built-in ROM bootloader that runs first
2. **Boot Source**: ROM checks boot pins and reads from SD card sector 34
3. **STM32 Header**: ROM validates our header (magic number, entry point, size)
4. **Load & Jump**: ROM loads our code to SYSRAM (0x2FFC0000) and jumps to it
5. **Assembly Init**: `boot.S` sets up the stack and calls C++ startup
6. **C++ Runtime**: `startup.cpp` initializes BSS and calls main()
7. **Main Function**: `main.cpp` demonstrates C++ code, then enters infinite loop

## C++ Features

This bare metal environment supports:
- ✅ C++17 language features
- ✅ Templates and constexpr
- ✅ Placement new
- ✅ Virtual functions (with limitations)
- ❌ Standard library (no iostream, vector, etc.)
- ❌ Exceptions (disabled for size/complexity)
- ❌ RTTI (disabled for size)
- ❌ Dynamic memory allocation (no heap)

## Flashing to SD Card

### Method 1: STM32CubeProgrammer (Recommended)

1. Launch STM32CubeProgrammer
2. Insert SD card into your PC
3. Click "Open file" and select `build/stm32mp135-bare-metal.stm32`
4. Select "SD card" programming method
5. Choose your SD card from the list (be careful!)
6. Set address to `0x4400` (this is sector 34)
7. Click "Download"

### Method 2: Command Line (dd for Windows)

1. Download dd for Windows
2. Find your SD card number in Disk Management
3. Run as Administrator:
   ```cmd
   dd if=build\stm32mp135-bare-metal.stm32 of=\\.\PhysicalDriveN bs=512 seek=34
   ```
   Replace N with your SD card number

## Running

1. Set boot switches on STM32MP135F-DK for SD card boot:
   - BOOT0 = 0
   - BOOT2 = 1
2. Insert SD card into the board
3. Connect micro USB for power
4. Power on - the processor is now running your code!

## Debugging with VSCode

The project is ready for debugging with OpenOCD and ST-LINK:

1. Connect ST-LINK debugger to the board
2. Install Cortex-Debug extension (included in recommendations)
3. Configure OpenOCD for STM32MP1
4. Press F5 to start debugging

## Extending the Project

Now that C++ is working, you can:

1. **Add peripheral drivers** - Create C++ classes for UART, GPIO, etc.
2. **Implement interrupt handling** - Set up GIC and add IRQ handlers
3. **Enable caches and MMU** - Add MMU configuration for better performance
4. **Add more C++ features** - Static constructors, simple containers, etc.
5. **Initialize DDR** - Set up external RAM for more memory
6. **Build an RTOS** - Implement a scheduler and tasks

Example next step - adding UART output:
```cpp
class UART {
    Register<uint32_t> dr;   // Data register
    Register<uint32_t> sr;   // Status register
public:
    void putc(char c) {
        while (!(sr.read() & TX_READY)) {}
        dr.write(c);
    }
};
```

## Technical Details

### STM32 Header Format
```
Offset  Size  Description
0x00    4     Magic number (0x00000001)
0x04    4     Entry point address
0x08    4     Reserved (must be 0)
0x0C    4     Image length in bytes
0x10    240   Reserved (padding to 256 bytes)
```

### Memory Map
- `0x2FFC0000`: SYSRAM (256KB) - Where our code runs
- `0xC0000000`: DDR3 RAM (not used in this demo)

### C++ ABI Support
The project includes minimal C++ runtime:
- BSS initialization
- Placement new operators
- Pure virtual handlers
- Stack unwinding stubs

## Troubleshooting

- **CMake errors**: Ensure CMake 3.20+ and Ninja are in PATH
- **Compiler not found**: Check ARM toolchain is in PATH
- **IntelliSense errors**: Let CMake configure complete first
- **Board doesn't boot**: Check boot switch settings
- **Build too large**: Enable optimization or remove unused code

## License

Public domain - use however you want!
