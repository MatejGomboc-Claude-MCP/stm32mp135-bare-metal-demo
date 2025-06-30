cmake_minimum_required(VERSION 3.20)

# Set the toolchain file before project() call
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/arm-none-eabi-toolchain.cmake)

project(stm32mp135-bare-metal
    VERSION 1.0.0
    LANGUAGES CXX
)

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Target MCU settings
set(MCU_FLAGS "-mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard -mthumb")

# Compiler flags
set(CMAKE_CXX_FLAGS "${MCU_FLAGS} -Wall -Wextra -fdata-sections -ffunction-sections")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions -fno-rtti -fno-threadsafe-statics")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-unwind-tables -fno-asynchronous-unwind-tables")

# Optimization flags
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g3")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -flto")
set(CMAKE_CXX_FLAGS_MINSIZEREL "-Os -flto")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS "${MCU_FLAGS} -T${CMAKE_SOURCE_DIR}/linker.ld")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -nostdlib -nodefaultlibs -nostartfiles")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections -Wl,-Map=${PROJECT_NAME}.map")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--no-undefined -Wl,--print-memory-usage")

# LTO for release builds
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "-flto")
set(CMAKE_EXE_LINKER_FLAGS_MINSIZEREL "-flto")

# Source files - pure C++ now!
set(SOURCES
    boot.cpp
    startup.cpp
    main.cpp
)

# Create executable
add_executable(${PROJECT_NAME}.elf ${SOURCES})

# Link against libgcc for compiler intrinsics
target_link_libraries(${PROJECT_NAME}.elf PRIVATE
    gcc  # For compiler intrinsics like __aeabi_* functions
)

# Generate binary file for flashing
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary ${PROJECT_NAME}.elf ${PROJECT_NAME}.stm32
    COMMENT "Generating binary file for STM32MP1 ROM bootloader"
)

# Print size information
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_SIZE} --format=berkeley ${PROJECT_NAME}.elf
    COMMENT "Size information:"
)

# Platform-specific flash instructions
if(WIN32)
    set(FLASH_INSTRUCTION "Use 'Tasks: Run Task' → 'Flash to SD Card' in VSCode, or run scripts/flash.ps1 as Administrator")
elseif(APPLE)
    set(FLASH_INSTRUCTION "Use 'Tasks: Run Task' → 'Flash to SD Card' in VSCode, or run scripts/flash.sh")
elseif(UNIX)
    set(FLASH_INSTRUCTION "Use 'Tasks: Run Task' → 'Flash to SD Card' in VSCode, or run scripts/flash.sh")
    # Make script executable on Linux
    execute_process(COMMAND chmod +x ${CMAKE_SOURCE_DIR}/scripts/flash.sh)
endif()

# Print flash instructions after build
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo ""
    COMMAND ${CMAKE_COMMAND} -E echo "Build complete! Binary file: ${PROJECT_NAME}.stm32"
    COMMAND ${CMAKE_COMMAND} -E echo "To flash: ${FLASH_INSTRUCTION}"
    COMMAND ${CMAKE_COMMAND} -E echo ""
)

# Clean target
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES
    "${PROJECT_NAME}.map"
    "${PROJECT_NAME}.stm32"
)

# Create a custom target for flashing
if(WIN32)
    add_custom_target(flash
        COMMAND powershell -ExecutionPolicy Bypass -File ${CMAKE_SOURCE_DIR}/scripts/flash.ps1
        DEPENDS ${PROJECT_NAME}.elf
        COMMENT "Flashing to SD card..."
    )
else()
    add_custom_target(flash
        COMMAND ${CMAKE_SOURCE_DIR}/scripts/flash.sh
        DEPENDS ${PROJECT_NAME}.elf
        COMMENT "Flashing to SD card..."
    )
endif()
