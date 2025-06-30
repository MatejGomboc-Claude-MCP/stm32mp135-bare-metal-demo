# STM32MP135 Bare Metal Demo - Pure C++17

A minimal bare metal example for the STM32MP135 Cortex-A7 processor using **pure C++17** with zero assembly files! This demo showcases modern C++ techniques in embedded systems, boots the processor, and runs without any external dependencies.

## 🚀 Key Features

- **100% C++** - No assembly files! Everything is implemented in modern C++
- **C++17** - Uses latest language features like `inline constexpr`, CTAD, and more
- **Minimal & Clean** - Simplified linker script with only essential sections
- **Cross-Platform** - Build and flash on Windows, Linux, or macOS
- **VSCode Integration** - Full IntelliSense and debugging support
- **Hardware Debugging** - ST-Link V2 debugging via SWD with breakpoints and stepping
- **Safe Flashing** - Multiple methods with safety checks

## Overview

This project demonstrates:
- Pure C++ boot code with inline assembly only where required
- C++17 features in bare metal (constexpr, templates, inline variables)
- GNU attributes for low-level control (`[[gnu::naked]]`, `[[gnu::section]]`)
- Minimal runtime without bloat (no preinit_array, no exception handling)
- Hardware register access using C++ templates
- Static constructors support for global objects
- **Full debugging with GDB and VSCode**

## Prerequisites

### Hardware
- STM32MP135F-DK Discovery Kit (or compatible board)
- Micro SD card
- Micro USB cable for power
- ST-Link V2 debugger (optional, for debugging)

### Software (All Platforms)

1. **ARM GNU Toolchain** (latest version)
   - [Download](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
   - Choose version for your OS
   - Add to PATH

2. **Build Tools**
   - CMake 3.20+ ([Download](https://cmake.org/download/))
   - Ninja ([Download](https://ninja-build.org/))
   - Python 3 (optional, for flash tool)

3. **VSCode** ([Download](https://code.visualstudio.com/))

4. **Debugging Tools** (optional)
   - OpenOCD ([Download](https://github.com/openocd-org/openocd/releases))
   - Cortex-Debug VSCode extension (auto-installed)

## Quick Start

```bash
# Clone and open
git clone https://github.com/MatejGomboc-Claude-MCP/stm32mp135-bare-metal-demo.git
cd stm32mp135-bare-metal-demo
code .

# Build in VSCode: Ctrl/Cmd+Shift+B
# Flash in VSCode: Ctrl/Cmd+Shift+P → "Flash to SD Card"
# Debug in VSCode: F5 (with ST-Link connected)
```

## Project Structure

```
├── boot.cpp            # Pure C++ boot code with vector table
├── startup.cpp         # C++ runtime initialization
├── main.cpp            # Application code with C++17 examples
├── linker.ld           # Minimal linker script
├── CMakeLists.txt      # Modern CMake configuration
├── .vscode/
│   ├── launch.json     # Debug configurations
│   ├── tasks.json      # Build and flash tasks
│   └── settings.json   # Project settings
├── openocd/            # OpenOCD configs for debugging
│   ├── stlink-v2.cfg   # ST-Link V2 interface
│   └── stm32mp13x.cfg  # STM32MP13x target
├── scripts/            # Cross-platform flashing tools
└── docs/
    └── debugging.md    # Detailed debugging guide
```

## Pure C++ Implementation

### Boot Code (boot.cpp)
```cpp
// C++ vector table - no assembly needed!
[[gnu::used, gnu::section(".vectors")]]
const void* vector_table[8] = {
    reinterpret_cast<void*>(reset_handler),     // Reset
    reinterpret_cast<void*>(default_handler),   // Undefined
    // ... more vectors
};

// Minimal inline assembly for stack setup
[[gnu::naked, gnu::section(".text.reset_handler")]]
extern "C" void reset_handler() {
    asm volatile(
        "ldr sp, =%0\n"
        "b __startup\n"
        :: "i"(stack_top)
    );
}
```

### Modern C++17 Features Used

1. **Inline Variables**
```cpp
inline constexpr uint32_t RCC_BASE = 0x50000000;
```

2. **Class Template Argument Deduction (CTAD)**
```cpp
CircularBuffer buffer{std::array<uint32_t, 16>{}};  // C++17 CTAD
```

3. **Constexpr Improvements**
```cpp
template<typename T>
class Register {
    volatile T* const addr;
public:
    explicit constexpr Register(uint32_t address) 
        : addr(reinterpret_cast<volatile T*>(address)) {}
};
```

4. **If Constexpr**
```cpp
template<bool EnableDebugging>
void process_data(uint32_t data) {
    if constexpr (EnableDebugging) {
        // Eliminated at compile time if false
        event_buffer.push(data);
    }
}
```

## Building

### VSCode (Recommended)
1. Open project in VSCode
2. CMake configures automatically
3. Press `Ctrl/Cmd+Shift+B` to build

### Command Line
```bash
mkdir build && cd build
cmake -G Ninja ..
ninja
```

### Build Outputs
- `stm32mp135-bare-metal.elf` - ELF with debug symbols
- `stm32mp135-bare-metal.stm32` - Binary for flashing
- `stm32mp135-bare-metal.map` - Memory map

## Flashing

### Method 1: VSCode Task
`Ctrl/Cmd+Shift+P` → "Tasks: Run Task" → "Flash to SD Card"

### Method 2: Python Tool
```bash
python scripts/stm32flash.py build/stm32mp135-bare-metal.stm32
```

### Method 3: Direct Command
```bash
# Linux/macOS
sudo dd if=build/stm32mp135-bare-metal.stm32 of=/dev/sdX bs=512 seek=34

# Windows (as Administrator)
dd if=build\stm32mp135-bare-metal.stm32 of=\\.\PhysicalDriveN bs=512 seek=34
```

## 🔧 Hardware Debugging

### Quick Setup

1. **Connect ST-Link V2 to SWD header** (CN11 on STM32MP135F-DK)
2. **Set boot switches** for Engineering Mode (BOOT0=0, BOOT2=0)
3. **Press F5 in VSCode** to start debugging

### Debug Features
- **Breakpoints** - Click in the gutter or use `break main`
- **Step Through Code** - F10 (over), F11 (into)
- **Variable Watch** - Hover or add to watch window
- **Memory View** - Inspect any memory address
- **Register View** - See CPU and peripheral registers
- **Call Stack** - Full backtrace support

See [docs/debugging.md](docs/debugging.md) for detailed debugging instructions.

## Memory Layout

```
0x2FFC0000: STM32 Header (256 bytes)
0x2FFC0100: Vector Table
0x2FFC0120: Code (.text)
0x2FFCxxxx: Initialized Data (.data)
0x2FFCxxxx: Zero-initialized Data (.bss)
```

## Extending the Project

### Add UART Driver
```cpp
class UART {
    static constexpr uint32_t BASE = 0x40010000;
    Register<uint32_t> dr{BASE + 0x00};
    Register<uint32_t> sr{BASE + 0x04};
public:
    void write(std::string_view str) {
        for (char c : str) {
            while (!(sr.read() & TX_READY)) {}
            dr.write(c);
        }
    }
};
```

### Enable Caches (C++ style)
```cpp
class CortexA7 {
public:
    static void enableCaches() {
        uint32_t sctlr;
        asm volatile("mrc p15, 0, %0, c1, c0, 0" : "=r"(sctlr));
        sctlr |= (1 << 12) | (1 << 2);  // I-cache | D-cache
        asm volatile("mcr p15, 0, %0, c1, c0, 0" :: "r"(sctlr));
    }
};
```

## Simplified Linker Script

The linker script has been optimized for modern toolchains:
- ✅ Only essential sections (`.text`, `.data`, `.bss`, `.init_array`)
- ❌ No `.preinit_array` or `.fini_array` (not needed)
- ❌ No exception handling sections
- ❌ No RTTI sections

## C++ Runtime Features

### Supported ✅
- Global constructors (static initialization)
- Placement new
- Templates and constexpr
- Virtual functions (with care)
- STL type traits and utilities

### Not Included ❌
- Heap allocation (no malloc/new)
- Exceptions
- RTTI
- Standard library containers
- Threads

## Technical Details

- **Compiler**: arm-none-eabi-g++ (latest)
- **C++ Standard**: C++17
- **Optimization**: `-O3` for release, `-Os` for size
- **Link Time Optimization**: Enabled for release builds
- **Stack**: 4KB (configurable in boot.cpp)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Undefined reference to `__aeabi_*` | Link with `-lgcc` (already in CMakeLists.txt) |
| Vector table not at 0x00 | Check `.vectors` section is first in linker script |
| Static constructors not called | Ensure `.init_array` is kept in linker script |
| Code too large | Enable `-Os` optimization or LTO |
| Can't connect debugger | Check SWD connections and OpenOCD installation |
| Breakpoint not hit | Ensure debug build (`-O0 -g3`) |

## Why Pure C++?

1. **Type Safety** - Even at the lowest level
2. **Compile-Time Computation** - Extensive use of constexpr
3. **Zero Overhead** - C++ features compile to efficient code
4. **Modern Practices** - No need for legacy assembly patterns
5. **Maintainability** - One language throughout the project

## Contributing

Ideas for contributions:
- Add MPU configuration in C++
- Implement interrupt handling with C++ lambdas
- Create constexpr peripheral definitions
- Add compile-time pin configuration
- Improve debugging experience

## License

Public domain - use however you want!
