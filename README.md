# STM32MP135 Bare Metal Demo

A minimal bare metal example for the STM32MP135 Cortex-A7 processor using modern C++17, CMake, and VSCode. This demo boots the processor, runs some C++ code, and then enters an infinite loop. **Works on Windows, Linux, and macOS!**

## Overview

This project demonstrates:
- How to create a minimal bootable image for STM32MP135
- The STM32 boot header format required by the ROM bootloader 
- Basic ARM Cortex-A7 exception vectors
- Using modern C++17 in a bare metal environment
- CMake cross-compilation for ARM
- VSCode integration for embedded development
- **Cross-platform development and flashing**

## Prerequisites

### Hardware
- STM32MP135F-DK Discovery Kit (or compatible board)
- Micro SD card (any size)
- Micro USB cable for power

### Software (All Platforms)

#### 1. ARM GNU Toolchain
- **Download**: [ARM Developer](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
- Choose the appropriate version for your OS:
  - **Windows**: `arm-gnu-toolchain-*-mingw-w64-i686-arm-none-eabi.exe`
  - **Linux**: `arm-gnu-toolchain-*-x86_64-arm-none-eabi.tar.xz`
  - **macOS**: `arm-gnu-toolchain-*-darwin-x86_64-arm-none-eabi.pkg`
- Add to PATH after installation

#### 2. Build Tools
- **CMake**: [Download](https://cmake.org/download/) (3.20+)
- **Ninja**: [Download](https://ninja-build.org/)
- **Python 3**: [Download](https://www.python.org/) (for flash tool)

#### 3. VSCode
- [Download VSCode](https://code.visualstudio.com/)
- The project includes recommended extensions

#### 4. Platform-Specific Tools

**Windows:**
- Option A: [STM32CubeProgrammer](https://www.st.com/en/development-tools/stm32cubeprog.html)
- Option B: Python with pywin32: `pip install pywin32`

**Linux:**
- `dd` command (pre-installed)
- Python 3 (usually pre-installed)

**macOS:**
- `dd` command (pre-installed)
- Python 3: `brew install python3`

## Project Structure

```
├── .vscode/              # VSCode configuration
│   ├── settings.json     # Project settings
│   ├── tasks.json        # Build & flash tasks
│   ├── c_cpp_properties.json  # IntelliSense config
│   └── extensions.json   # Recommended extensions
├── cmake/
│   └── arm-none-eabi-toolchain.cmake  # CMake toolchain file
├── scripts/              # Platform-specific flash scripts
│   ├── flash.sh          # Linux/macOS flash script
│   ├── flash.ps1         # Windows PowerShell script
│   └── stm32flash.py     # Cross-platform Python tool
├── boot.S                # ARM assembly startup code
├── main.cpp              # C++ entry point
├── startup.cpp           # C++ runtime initialization
├── linker.ld             # Linker script
├── CMakeLists.txt        # CMake build configuration
└── README.md             # This file
```

## Building with VSCode

### 1. Clone and Open
```bash
git clone https://github.com/MatejGomboc-Claude-MCP/stm32mp135-bare-metal-demo.git
cd stm32mp135-bare-metal-demo
code .
```

### 2. Install Extensions
When VSCode opens, it will prompt you to install recommended extensions. Accept to install:
- C/C++ (Microsoft)
- CMake Tools
- Cortex-Debug (for future debugging)

### 3. Configure and Build
- **Configure**: Happens automatically, or press `Ctrl/Cmd+Shift+P` → "CMake: Configure"
- **Build**: Press `Ctrl/Cmd+Shift+B` or click the Build button in the status bar

Output files in `build/`:
- `stm32mp135-bare-metal.elf` - ELF file with debug symbols
- `stm32mp135-bare-metal.stm32` - Binary file for flashing
- `stm32mp135-bare-metal.map` - Linker map file

## Flashing to SD Card

### Method 1: VSCode Tasks (Recommended)

After building, use the Command Palette (`Ctrl/Cmd+Shift+P`) and run:
- **"Tasks: Run Task"** → **"Flash to SD Card"**

This will run the appropriate platform-specific script.

### Method 2: Cross-Platform Python Tool

```bash
# Install dependencies (first time only)
pip install -r requirements-flash.txt

# Run the flash tool
python scripts/stm32flash.py build/stm32mp135-bare-metal.stm32
```

The tool will:
1. Auto-detect removable drives
2. Verify the STM32 header
3. Flash at the correct offset (0x4400)

### Method 3: Platform-Specific Manual Methods

<details>
<summary><b>Windows Manual Method</b></summary>

**Using STM32CubeProgrammer:**
1. Launch STM32CubeProgrammer
2. Select "SD card" programming method
3. Choose your SD card (be careful!)
4. Set address to `0x4400`
5. Select `build\stm32mp135-bare-metal.stm32`
6. Click "Download"

**Using PowerShell (as Administrator):**
```powershell
# Run the provided script
powershell -ExecutionPolicy Bypass -File scripts\flash.ps1
```
</details>

<details>
<summary><b>Linux Manual Method</b></summary>

```bash
# Find your SD card device
lsblk

# Flash (replace /dev/sdX with your device)
sudo dd if=build/stm32mp135-bare-metal.stm32 of=/dev/sdX bs=512 seek=34 conv=fsync status=progress
```
</details>

<details>
<summary><b>macOS Manual Method</b></summary>

```bash
# Find your SD card device
diskutil list

# Unmount (replace diskN with your device)
diskutil unmountDisk /dev/diskN

# Flash
sudo dd if=build/stm32mp135-bare-metal.stm32 of=/dev/diskN bs=512 seek=34
```
</details>

## Running

1. Set boot switches on STM32MP135F-DK for SD card boot:
   - BOOT0 = 0
   - BOOT2 = 1
2. Insert SD card into the board
3. Connect micro USB for power
4. Power on - the processor is now running your code!

## Building from Command Line

If you prefer command line over VSCode:

```bash
# All platforms
mkdir build
cd build
cmake -G Ninja ..
ninja

# Or on Linux/macOS with Make
cmake ..
make
```

## How It Works

1. **ROM Bootloader**: Built-in bootloader reads sector 34 of SD card
2. **STM32 Header**: Validates magic number and entry point
3. **Code Loading**: Loads our binary to SYSRAM (0x2FFC0000)
4. **Execution Flow**:
   - `boot.S`: Sets up stack, calls C++ startup
   - `startup.cpp`: Initializes BSS, calls main()
   - `main.cpp`: Runs C++ code, enters infinite loop

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

## Extending the Project

Example next steps:

### 1. Add UART Output
```cpp
class UART {
    Register<uint32_t> dr{0x40011000};  // Data register
    Register<uint32_t> sr{0x40011004};  // Status register
public:
    void putc(char c) {
        while (!(sr.read() & (1 << 7))) {}  // Wait for TX ready
        dr.write(c);
    }
    
    void puts(const char* str) {
        while (*str) putc(*str++);
    }
};
```

### 2. Enable Caches
```cpp
// In main.cpp
asm volatile(
    "mrc p15, 0, r0, c1, c0, 0\n"  // Read SCTLR
    "orr r0, r0, #(1 << 12)\n"      // Enable I-cache
    "orr r0, r0, #(1 << 2)\n"       // Enable D-cache
    "mcr p15, 0, r0, c1, c0, 0\n"  // Write SCTLR
    ::: "r0"
);
```

### 3. Set Up Interrupts
- Configure GIC (Generic Interrupt Controller)
- Set up exception handlers
- Enable IRQ/FIQ in CPSR

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
- `0x2FFC0000`: SYSRAM (256KB) - Code and data
- `0xC0000000`: DDR3 RAM (not used yet)

## Troubleshooting

| Problem | Solution |
|---------|----------|
| CMake can't find compiler | Ensure ARM toolchain is in PATH |
| Build fails on Windows | Check if ninja.exe is in PATH |
| SD card not detected | Try different card or USB adapter |
| Board doesn't boot | Verify boot switches (BOOT0=0, BOOT2=1) |
| Permission denied (Linux/macOS) | Use `sudo` for flashing |
| Flash script fails | Try the Python tool instead |

## Contributing

Feel free to submit issues and pull requests! Some ideas:
- Add OpenOCD debugging configuration
- Create a minimal HAL for peripherals
- Add FreeRTOS support
- Implement a simple bootloader

## License

Public domain - use however you want!
