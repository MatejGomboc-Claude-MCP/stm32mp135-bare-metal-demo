@
@ boot.S - STM32MP135 Cortex-A7 startup code
@ 
@ This code is loaded by the ROM bootloader and provides
@ the initial entry point and exception vectors.
@

.syntax unified
.cpu cortex-a7
.fpu neon-vfpv4

.section .vectors, "ax"
.global _start

@ ARM Exception Vector Table
@ The Cortex-A7 expects these at the base of the code
_start:
    b reset_handler    @ 0x00: Reset vector
    b .               @ 0x04: Undefined instruction
    b .               @ 0x08: Software interrupt (SWI/SVC)
    b .               @ 0x0C: Prefetch abort
    b .               @ 0x10: Data abort
    b .               @ 0x14: Reserved
    b .               @ 0x18: IRQ interrupt
    b .               @ 0x1C: FIQ interrupt

.section .text
.global reset_handler
.global infinite_loop

@ Reset handler - this is where execution begins
reset_handler:
    @ Set stack pointer for SVC mode
    ldr sp, =__stack_top
    
    @ TODO: Initialize other stacks (IRQ, FIQ, etc.) when needed
    
    @ Call C++ startup code
    bl __startup
    
    @ Should never get here, but just in case
    b infinite_loop

@ Infinite loop function (can be called from C++)
infinite_loop:
    nop
    b infinite_loop

@ Stack reservation (defined by linker script)
.section .stack, "aw", %nobits
.align 3
__stack_start:
    .space 0x1000  @ 4KB stack
__stack_top:
