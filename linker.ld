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
        *(.text)                    /* Remaining code */
    } > SYSRAM
    
    /* End of image marker for header */
    __image_end = .;
}
