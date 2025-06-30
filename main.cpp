/**
 * main.cpp - C++ entry point for STM32MP135 bare metal demo
 * 
 * This demonstrates how to use C++ in a bare metal environment.
 * Note: No standard library, exceptions, or RTTI available.
 */

#include <cstdint>

// Hardware register definitions
namespace stm32mp1 {
    // RCC base address
    constexpr uint32_t RCC_BASE = 0x50000000;
    
    // Simple register access
    template<typename T>
    class Register {
        volatile T* addr;
    public:
        explicit Register(uint32_t address) : addr(reinterpret_cast<volatile T*>(address)) {}
        T read() const { return *addr; }
        void write(T value) { *addr = value; }
        void setBits(T mask) { *addr |= mask; }
        void clearBits(T mask) { *addr &= ~mask; }
    };
}

// External assembly functions
extern "C" {
    void infinite_loop();
}

// Simple delay function
void delay(uint32_t count) {
    for (volatile uint32_t i = 0; i < count; ++i) {
        asm volatile("nop");
    }
}

// C++ main function
extern "C" int main() {
    // Example: You could initialize hardware here
    // For now, just demonstrate C++ is working
    
    // Create a variable to prove C++ code is running
    volatile uint32_t counter = 0;
    
    // Do some work before entering the infinite loop
    for (int i = 0; i < 10; ++i) {
        counter += i;
        delay(1000);
    }
    
    // Call the assembly infinite loop
    infinite_loop();
    
    // Never reached
    return 0;
}
