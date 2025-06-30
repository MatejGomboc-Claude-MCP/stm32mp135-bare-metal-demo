/*
 * linker.ld - Simplified linker script for STM32MP135 bare metal
 *
 * Optimized for C++17 with modern toolchain
 */

MEMORY
{
    /* 256KB of internal SYSRAM */
    SYSRAM (rwx) : ORIGIN = 0x2FFC0000, LENGTH = 256K
}

/* Entry point is the reset handler */
ENTRY(reset_handler)

SECTIONS
{
    /* Start at SYSRAM base address */
    . = ORIGIN(SYSRAM);
    
    /* STM32 header required by ROM bootloader */
    .header : {
        LONG(0x00000001);                    /* Magic number: STM32 header v1 */
        LONG(ABSOLUTE(reset_handler));       /* Entry point address */
        LONG(0x00000000);                    /* Reserved */
        LONG(__image_end - ORIGIN(SYSRAM)); /* Image length in bytes */
        . = 0x100;                           /* Header must be 256 bytes */
    } > SYSRAM
    
    /* Code and read-only data */
    .text : {
        KEEP(*(.vectors))                    /* Exception vectors must be first */
        *(.text.reset_handler)               /* Reset handler */
        *(.text .text.*)                     /* Code */
        *(.rodata .rodata.*)                 /* Read-only data */
        . = ALIGN(4);
    } > SYSRAM
    
    /* C++ initialization array */
    .init_array : {
        __init_array_start = .;
        KEEP(*(SORT(.init_array.*)))         /* Sorted init array */
        KEEP(*(.init_array))                 /* Init array */
        __init_array_end = .;
        . = ALIGN(4);
    } > SYSRAM
    
    /* Initialized data (in SYSRAM, no need to copy) */
    .data : {
        *(.data .data.*)
        . = ALIGN(4);
    } > SYSRAM
    
    /* Uninitialized data */
    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(8);
        __bss_end = .;
    } > SYSRAM
    
    /* End of image marker for header */
    __image_end = .;
    
    /* Discard unneeded sections */
    /DISCARD/ : {
        *(.ARM.exidx*)        /* ARM exception index - not needed */
        *(.ARM.extab*)        /* ARM exception table - not needed */
        *(.preinit_array)     /* Not needed for bare metal */
        *(.fini_array)        /* Destructors - not needed */
        *(.eh_frame)          /* Exception handling frame - not needed */
        *(.comment)           /* Comments */
    }
}
