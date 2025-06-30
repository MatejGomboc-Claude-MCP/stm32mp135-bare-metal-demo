/*
 * linker.ld - Linker script for STM32MP135 bare metal demo
 *
 * The STM32MP1 ROM bootloader will load our code into SYSRAM
 * at address 0x2FFC0000. We use this internal RAM to avoid
 * needing to initialize external DDR.
 */

MEMORY
{
    /* 256KB of internal SYSRAM */
    SYSRAM (rwx) : ORIGIN = 0x2FFC0000, LENGTH = 256K
}

/* Entry point */
ENTRY(_start)

/* Stack size */
__stack_size = 0x1000;  /* 4KB */

SECTIONS
{
    /* Start at SYSRAM base address */
    . = 0x2FFC0000;
    
    /* STM32 header required by ROM bootloader */
    .header : {
        LONG(0x00000001);           /* Magic number: STM32 header v1 */
        LONG(_start);               /* Entry point address */
        LONG(0x00000000);           /* Reserved */
        LONG(__image_end - _start); /* Image length in bytes */
        . = 0x100;                  /* Header must be 256 bytes */
    } > SYSRAM
    
    /* Code sections */
    .text : {
        *(.vectors)                 /* Exception vectors first */
        *(.text .text.*)           /* Code */
        *(.rodata .rodata.*)       /* Read-only data */
        . = ALIGN(4);
    } > SYSRAM
    
    /* Initialized data (not used in SYSRAM-only design) */
    .data : {
        __data_start = .;
        *(.data .data.*)
        . = ALIGN(4);
        __data_end = .;
    } > SYSRAM
    __data_load = LOADADDR(.data);
    
    /* Uninitialized data */
    .bss : {
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > SYSRAM
    
    /* Stack */
    .stack : {
        . = ALIGN(8);
        __stack_start = .;
        . += __stack_size;
        __stack_top = .;
    } > SYSRAM
    
    /* End of image marker for header */
    __image_end = .;
    
    /* Debug sections */
    .ARM.attributes 0 : { *(.ARM.attributes) }
}
