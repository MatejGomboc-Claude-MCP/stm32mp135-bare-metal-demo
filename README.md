# STM32MP135 Bare Metal Demo

A minimal bare metal example for the STM32MP135 Cortex-A7 processor. This demo boots the processor and runs an infinite NOP loop - the simplest possible "hello world" for ARM Cortex-A architecture.

## Overview

This project demonstrates:
- How to create a minimal bootable image for STM32MP135
- The STM32 boot header format required by the ROM bootloader 
- Basic ARM Cortex-A7 exception vectors
- Running code without any external bootloader (U-Boot, etc.)

## Prerequisites

### Hardware
- STM32MP135F-DK Discovery Kit (or compatible board)
- Micro SD card (any size)
- Micro USB cable for power

### Software (Windows 11)
- ARM GNU Toolchain: [Download here](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
  - Choose "arm-none-eabi" Windows hosted version
  - Add to PATH after installation
- STM32CubeProgrammer: [Download from ST](https://www.st.com/en/development-tools/stm32cubeprog.html)

## Project Structure

```
├── boot.S        # ARM assembly startup code
├── linker.ld     # Linker script defining memory layout
├── build.bat     # Windows build script
└── README.md     # This file
```

## How It Works

1. **ROM Bootloader**: The STM32MP1 has a built-in ROM bootloader that runs first
2. **Boot Source**: ROM checks boot pins and reads from SD card sector 34
3. **STM32 Header**: ROM validates our header (magic number, entry point, size)
4. **Load & Jump**: ROM loads our code to SYSRAM (0x2FFC0000) and jumps to it
5. **Our Code**: Simply enters an infinite NOP loop

## Building

1. Open Command Prompt in the project directory
2. Run the build script:
   ```cmd
   build.bat
   ```
3. You should see:
   ```
   Building STM32MP135 bare metal demo...
   
   Build successful!
   text    data     bss     dec     hex filename
    276       0       0     276     114 boot.elf
   
   Output file: boot.stm32
   ```

## Flashing to SD Card

### Method 1: STM32CubeProgrammer (Recommended)

1. Launch STM32CubeProgrammer
2. Insert SD card into your PC
3. Click "Open file" and select `boot.stm32`
4. Select "SD card" programming method
5. Choose your SD card from the list (be careful!)
6. Set address to `0x4400` (this is sector 34)
7. Click "Download"

### Method 2: Command Line (dd for Windows)

1. Download dd for Windows
2. Find your SD card number in Disk Management
3. Run as Administrator:
   ```cmd
   dd if=boot.stm32 of=\\.\PhysicalDriveN bs=512 seek=34
   ```
   Replace N with your SD card number

## Running

1. Set boot switches on STM32MP135F-DK for SD card boot:
   - BOOT0 = 0
   - BOOT2 = 1
2. Insert SD card into the board
3. Connect micro USB for power
4. Power on - the processor is now running your code!

## Verifying It Works

Since the code just runs an infinite loop, you can verify it's working by:
- Connecting a debugger (ST-LINK) to see the PC at the NOP loop
- The fact that the board doesn't go into DFU/recovery mode
- No error LEDs or signs of boot failure

## Next Steps

Once this works, you can expand by:
1. Setting up stack pointers for different CPU modes
2. Enabling caches and MMU
3. Initializing UART for "Hello World" output  
4. Setting up interrupts with the GIC
5. Initializing external DDR3 RAM
6. Building a simple RTOS

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

## Troubleshooting

- **Build errors**: Ensure ARM toolchain is in PATH
- **Board doesn't boot**: Check boot switch settings
- **SD card issues**: Try different card or reformat as FAT32
- **Wrong offset**: Ensure you're writing to sector 34 (offset 0x4400)

## License

Public domain - use however you want!
