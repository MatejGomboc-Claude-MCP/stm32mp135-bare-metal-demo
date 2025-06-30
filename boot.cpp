/**
 * boot.cpp - Pure C++ startup code for STM32MP135 Cortex-A7
 * 
 * Uses inline assembly only where absolutely necessary.
 * The vector table and initial boot code are implemented in C++.
 */

#include <cstdint>

// Stack configuration
constexpr uint32_t STACK_SIZE = 0x1000;  // 4KB
alignas(8) static uint8_t stack[STACK_SIZE];

// Get stack top address at compile time
static constexpr uint32_t* stack_top = reinterpret_cast<uint32_t*>(&stack[STACK_SIZE]);

// External functions
extern "C" void __startup();
extern "C" void infinite_loop();

// Reset handler - where execution begins
[[gnu::naked, gnu::section(".text.reset_handler")]]
extern "C" void reset_handler() {
    asm volatile(
        // Set stack pointer
        "ldr sp, =%0\n"
        // Jump to C++ startup
        "b __startup\n"
        :
        : "i"(stack_top)
        : "memory"
    );
}

// Default handler for unused exceptions
[[gnu::used, gnu::section(".text.default_handler")]]
static void default_handler() {
    infinite_loop();
}

// ARM exception vector table
// Must be placed at the beginning of the code section
[[gnu::used, gnu::section(".vectors")]]
const void* vector_table[8] = {
    reinterpret_cast<void*>(reset_handler),     // 0x00: Reset
    reinterpret_cast<void*>(default_handler),   // 0x04: Undefined instruction
    reinterpret_cast<void*>(default_handler),   // 0x08: Software interrupt (SWI/SVC)
    reinterpret_cast<void*>(default_handler),   // 0x0C: Prefetch abort
    reinterpret_cast<void*>(default_handler),   // 0x10: Data abort
    reinterpret_cast<void*>(default_handler),   // 0x14: Reserved
    reinterpret_cast<void*>(default_handler),   // 0x18: IRQ interrupt
    reinterpret_cast<void*>(default_handler),   // 0x1C: FIQ interrupt
};

// Infinite loop function (used by default handler and as fallback)
extern "C" void infinite_loop() {
    while (true) {
        asm volatile("nop");
    }
}

// Ensure the vector table is referenced so it's not optimized out
[[gnu::used]]
static const void* keep_vectors = &vector_table[0];
