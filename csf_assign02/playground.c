#include <stdint.h>
#include <stdio.h>

int main() {
    uint32_t num = 0x71234567; // Example number
    uint32_t first4Bits = (num >> 28) & 0xF;
    printf("First 4 bits: 0x%X\n", first4Bits);
    return 0;
}