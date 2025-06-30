@echo off
REM build.bat - Build script for Windows
REM
REM Prerequisites: ARM GNU Toolchain (arm-none-eabi-gcc)
REM Download from: https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads

echo Building STM32MP135 bare metal demo...

REM Assemble the boot code
arm-none-eabi-as -mcpu=cortex-a7 boot.S -o boot.o
if errorlevel 1 goto error

REM Link using our custom linker script
arm-none-eabi-ld -T linker.ld boot.o -o boot.elf
if errorlevel 1 goto error

REM Convert ELF to binary format for ROM bootloader
arm-none-eabi-objcopy -O binary boot.elf boot.stm32
if errorlevel 1 goto error

REM Display size information
echo.
echo Build successful!
arm-none-eabi-size boot.elf
echo.
echo Output file: boot.stm32
echo Flash this file to SD card at sector 34 (offset 0x4400)
goto end

:error
echo.
echo Build failed!
exit /b 1

:end
