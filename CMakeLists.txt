cmake_minimum_required(VERSION 3.20)

# Set the toolchain file before project() call
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/arm-none-eabi-toolchain.cmake)

project(stm32mp135-bare-metal
    VERSION 1.0.0
    LANGUAGES C CXX ASM
)

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Target MCU settings
set(MCU_FLAGS "-mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard -mthumb")

# Compiler flags
set(CMAKE_C_FLAGS "${MCU_FLAGS} -Wall -fdata-sections -ffunction-sections")
set(CMAKE_CXX_FLAGS "${MCU_FLAGS} -Wall -fdata-sections -ffunction-sections -fno-exceptions -fno-rtti")
set(CMAKE_ASM_FLAGS "${MCU_FLAGS}")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS "${MCU_FLAGS} -T${CMAKE_SOURCE_DIR}/linker.ld -nostdlib -Wl,--gc-sections -Wl,-Map=${PROJECT_NAME}.map")

# Source files
set(SOURCES
    boot.S
    main.cpp
    startup.cpp
)

# Create executable
add_executable(${PROJECT_NAME}.elf ${SOURCES})

# Generate binary file for flashing
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary ${PROJECT_NAME}.elf ${PROJECT_NAME}.stm32
    COMMENT "Generating binary file for STM32MP1 ROM bootloader"
)

# Print size information
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_SIZE} ${PROJECT_NAME}.elf
    COMMENT "Size information:"
)

# Clean target
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES
    "${PROJECT_NAME}.map"
    "${PROJECT_NAME}.stm32"
)
