/**
 * startup.cpp - C++ runtime initialization
 * 
 * Minimal C++ runtime support for bare metal environment
 */

#include <cstdint>
#include <cstring>

// These symbols are defined by the linker script
extern uint32_t __bss_start;
extern uint32_t __bss_end;

// Init array for static constructors
extern void (*__init_array_start)();
extern void (*__init_array_end)();

// Main function
extern "C" int main();

// C++ runtime initialization
extern "C" [[gnu::used]] void __startup() {
    // Zero-initialize BSS section
    std::memset(&__bss_start, 0, 
                reinterpret_cast<uint8_t*>(&__bss_end) - 
                reinterpret_cast<uint8_t*>(&__bss_start));
    
    // Call static constructors
    for (void (**p)() = &__init_array_start; p < &__init_array_end; ++p) {
        (*p)();
    }
    
    // Call main
    main();
    
    // Should never return, but just in case
    while (true) {
        asm volatile("nop");
    }
}

// Minimal C++ ABI support
extern "C" {
    // Pure virtual function handler
    [[gnu::used, noreturn]]
    void __cxa_pure_virtual() {
        while (true) {
            asm volatile("nop");
        }
    }
    
    // Guard variables for static initialization (simplified version)
    [[gnu::used]]
    int __cxa_guard_acquire(uint64_t* guard_object) {
        // Simple implementation - assumes single-threaded
        if (*guard_object == 0) {
            return 1;  // Not initialized, proceed
        }
        return 0;  // Already initialized
    }
    
    [[gnu::used]]
    void __cxa_guard_release(uint64_t* guard_object) {
        *guard_object = 1;  // Mark as initialized
    }
    
    [[gnu::used]]
    void __cxa_guard_abort(uint64_t*) {
        // Nothing to do in our simple implementation
    }
}

// Placement new operators
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
