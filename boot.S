@
@ boot.S - Minimal STM32MP135 Cortex-A7 startup code
@ 
@ This code is loaded by the ROM bootloader and simply
@ initializes the processor and enters an infinite NOP loop.
@

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
@ Reset handler - this is where execution begins
reset_handler:
    @ The processor is now in SVC mode (Supervisor)
    @ No stack setup needed for this simple demo
    
infinite_loop:
    nop               @ No operation
    b infinite_loop   @ Branch back to the NOP
