# ARM none EABI Toolchain file for CMake
# Works on Windows, Linux, and macOS

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)

# Set toolchain prefix
set(TOOLCHAIN_PREFIX arm-none-eabi-)

# Find toolchain executable suffix (.exe on Windows)
if(WIN32)
    set(TOOLCHAIN_SUFFIX ".exe")
else()
    set(TOOLCHAIN_SUFFIX "")
endif()

# Find the toolchain programs
find_program(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}gcc${TOOLCHAIN_SUFFIX}
    HINTS $ENV{ARM_TOOLCHAIN_PATH}/bin
    REQUIRED
)
find_program(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}g++${TOOLCHAIN_SUFFIX}
    HINTS $ENV{ARM_TOOLCHAIN_PATH}/bin
    REQUIRED
)
find_program(CMAKE_ASM_COMPILER ${TOOLCHAIN_PREFIX}gcc${TOOLCHAIN_SUFFIX}
    HINTS $ENV{ARM_TOOLCHAIN_PATH}/bin
    REQUIRED
)
find_program(CMAKE_AR ${TOOLCHAIN_PREFIX}ar${TOOLCHAIN_SUFFIX}
    HINTS $ENV{ARM_TOOLCHAIN_PATH}/bin
    REQUIRED
)
find_program(CMAKE_OBJCOPY ${TOOLCHAIN_PREFIX}objcopy${TOOLCHAIN_SUFFIX}
    HINTS $ENV{ARM_TOOLCHAIN_PATH}/bin
    REQUIRED
)
find_program(CMAKE_OBJDUMP ${TOOLCHAIN_PREFIX}objdump${TOOLCHAIN_SUFFIX}
    HINTS $ENV{ARM_TOOLCHAIN_PATH}/bin
    REQUIRED
)
find_program(CMAKE_SIZE ${TOOLCHAIN_PREFIX}size${TOOLCHAIN_SUFFIX}
    HINTS $ENV{ARM_TOOLCHAIN_PATH}/bin
    REQUIRED
)
find_program(CMAKE_DEBUGGER ${TOOLCHAIN_PREFIX}gdb${TOOLCHAIN_SUFFIX}
    HINTS $ENV{ARM_TOOLCHAIN_PATH}/bin
)

# Set compiler flags
set(CMAKE_C_FLAGS_INIT "")
set(CMAKE_CXX_FLAGS_INIT "")
set(CMAKE_ASM_FLAGS_INIT "")
set(CMAKE_EXE_LINKER_FLAGS_INIT "")

# Don't run the linker for compiler tests
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# For libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
