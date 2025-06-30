# Debugging STM32MP135 with ST-Link V2

This guide explains how to debug the STM32MP135 bare metal application using ST-Link V2 via SWD.

## Hardware Setup

### 1. ST-Link V2 Connections

Connect ST-Link V2 to the STM32MP135F-DK board:

```
ST-Link V2          STM32MP135F-DK CN11 (SWD)
----------          ------------------------
Pin 1  (VCC)    →   Pin 1  (VDD_3V3)
Pin 7  (SWDIO)  →   Pin 2  (SWDIO)
Pin 9  (SWCLK)  →   Pin 4  (SWCLK)  
Pin 15 (RESET)  →   Pin 10 (NRST)
Pin 20 (GND)    →   Pin 3  (GND)
```

**Note**: The STM32MP135F-DK has a built-in ST-Link V2, but using external ST-Link gives more control.

### 2. Boot Configuration

For debugging, you have two options:

**Option A - Debug from SYSRAM (Recommended):**
- Set boot switches for "Engineering Mode":
  - BOOT0 = 0
  - BOOT2 = 0
- This boots to a minimal state, waiting for debugger

**Option B - Debug after SD boot:**
- Normal SD card boot (BOOT0=0, BOOT2=1)
- Use "Attach" configuration instead of "Launch"

## Software Setup

### 1. Install Required Tools

**Windows:**
```powershell
# Install OpenOCD via MSYS2 or download binary
# https://github.com/openocd-org/openocd/releases

# Or via chocolatey
choco install openocd
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt install openocd

# Or build from source for latest STM32MP1 support
git clone https://github.com/openocd-org/openocd
cd openocd
./bootstrap
./configure --enable-stlink
make
sudo make install
```

**macOS:**
```bash
brew install openocd
```

### 2. Verify Connection

Test OpenOCD connection:
```bash
openocd -f openocd/stlink-v2.cfg -f openocd/stm32mp13x.cfg
```

You should see:
```
Info : clock speed 1000 kHz
Info : STLINK V2J29S7 (API v2) VID:PID 0483:3748
Info : Target voltage: 3.248V
Info : stm32mp13x.cpu: hardware has 6 breakpoints, 4 watchpoints
Info : starting gdb server for stm32mp13x.cpu on 3333
```

## Debugging in VSCode

### 1. Build with Debug Symbols

Ensure debug build:
```bash
cmake -DCMAKE_BUILD_TYPE=Debug ..
ninja
```

### 2. Start Debugging

1. Open VSCode in project directory
2. Go to Run and Debug (Ctrl+Shift+D)
3. Select "Debug STM32MP135" configuration
4. Press F5 to start debugging

### 3. Debugging Features

**Breakpoints:**
- Click in the gutter to set breakpoints
- Conditional breakpoints supported
- Hardware breakpoints limited to 6

**Watch Variables:**
- Add variables to watch window
- Hover over variables to see values
- View registers in "Cortex Registers" pane

**Memory View:**
- Use Command Palette: "Cortex-Debug: View Memory"
- Enter address like `0x2FFC0000`

**Peripheral Registers:**
- Download STM32MP135.svd from ST
- Place in project root
- View in "Cortex Peripherals" pane

## Common Debug Scenarios

### 1. Debug from Reset
```gdb
# In Debug Console
monitor reset halt
load
break reset_handler
continue
```

### 2. Debug Hardfault
```cpp
// Add to your code
extern "C" void HardFault_Handler() {
    // Breakpoint here
    __asm("bkpt #0");
    while(1);
}
```

### 3. View Disassembly
- Right-click in editor → "Open Disassembly View"
- Or use GDB: `disassemble reset_handler`

### 4. Check Stack
```gdb
# In Debug Console
info frame
backtrace
x/10x $sp
```

## Troubleshooting

### "Error: couldn't bind gdb to socket"
- Kill any existing OpenOCD processes
- Check if port 3333 is in use

### "Error: libusb_open() failed"
- **Linux**: Add udev rules:
  ```bash
  sudo cp /usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d/
  sudo udevadm control --reload-rules
  ```
- **Windows**: Use Zadig to install WinUSB driver

### "Target not examined yet"
- Ensure target is powered
- Check SWD connections
- Try slower adapter speed

### "Core is in lockup state"
- Invalid memory access or hardfault
- Check your code for null pointer access
- Verify stack pointer initialization

## Advanced Debugging

### 1. Semihosting (printf via debugger)
```cpp
// Add to main.cpp
extern "C" void initialise_monitor_handles();

// In main()
initialise_monitor_handles();
printf("Hello from STM32MP135!\n");
```

Add to CMakeLists.txt:
```cmake
target_link_libraries(${PROJECT_NAME}.elf PRIVATE
    gcc
    rdimon  # For semihosting
)

target_compile_definitions(${PROJECT_NAME}.elf PRIVATE
    USE_SEMIHOSTING
)
```

### 2. ITM Trace (if available)
```cpp
// Configure ITM
volatile uint32_t* ITM_STIM0 = (uint32_t*)0xE0000000;
void itm_putc(char c) {
    while (!(*ITM_STIM0 & 1));
    *ITM_STIM0 = c;
}
```

### 3. GDB Scripts
Create `.gdbinit` in project root:
```gdb
# Auto-load settings
set print pretty on
set print array on
set print array-indexes on

# Custom commands
define rst
    monitor reset halt
    load
    continue
end

define stack
    info frame
    x/32x $sp
end
```

## Performance Tips

1. **Increase adapter speed** after stable connection:
   ```
   monitor adapter speed 4000
   ```

2. **Use hardware breakpoints** for code in flash:
   ```gdb
   hbreak main
   ```

3. **Disable unused features**:
   - Turn off ITM if not using
   - Disable semihosting in release builds

Happy debugging!
