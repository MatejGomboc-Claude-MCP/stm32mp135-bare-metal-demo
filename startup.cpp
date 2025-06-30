/**
 * startup.cpp - C++ runtime initialization
 * 
 * Minimal C++ runtime support for bare metal environment
 */

#include <cstdint>

// These symbols are defined by the linker script
extern uint32_t __data_start;
extern uint32_t __data_end;
extern uint32_t __data_load;
extern uint32_t __bss_start;
extern uint32_t __bss_end;

// C++ runtime support
extern "C" {
    // Called by boot.S after basic initialization
    void __startup() {
        // Copy initialized data from ROM to RAM (not needed for SYSRAM-only design)
        // uint32_t* src = &__data_load;
        // uint32_t* dst = &__data_start;
        // while (dst < &__data_end) {
        //     *dst++ = *src++;
        // }
        
        // Zero-initialize BSS section
        uint32_t* bss = &__bss_start;
        while (bss < &__bss_end) {
            *bss++ = 0;
        }
        
        // TODO: Call global constructors here if needed
        // For now, we avoid global constructors for simplicity
        
        // Call main
        extern int main();
        main();
        
        // Should never return, but just in case
        while (1) {
            asm volatile("nop");
        }
    }
    
    // Minimal C++ ABI support
    // Pure virtual function handler
    void __cxa_pure_virtual() {
        // Halt if pure virtual is called
        while (1) {
            asm volatile("nop");
        }
    }
    
    // Deleted function handler
    void __cxa_deleted_virtual() {
        // Halt if deleted virtual is called
        while (1) {
            asm volatile("nop");
        }
    }
}

// Placement new operators for C++
void* operator new(size_t, void* ptr) noexcept {
    return ptr;
}

void* operator new[](size_t, void* ptr) noexcept {
    return ptr;
}

// Delete operators (should never be called in bare metal)
void operator delete(void*) noexcept {}
void operator delete[](void*) noexcept {}
void operator delete(void*, size_t) noexcept {}
void operator delete[](void*, size_t) noexcept {}
