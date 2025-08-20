    .section .text
    .globl _start
_start:
    # Test program for store/load
    # x1 = base address for memory
    # x2 = value to store
    # x3 = value loaded from memory

    LUI     x1, 0x0          # x1 = 0x0000_0000_0000_0000 base address
    ADDI    x2, x0, 123      # x2 = 123, value to store

    # Store x2 into memory at address x1 + 0
    SD      x2, 0(x1)        # memory[0] = x2

    # Load back from memory into x3
    LD      x3, 0(x1)        # x3 = memory[0]

    # Store another value to test
    ADDI    x4, x0, 456      # x4 = 456
    SD      x4, 8(x1)        # memory[8] = x4

    # Load it back
    LD      x5, 8(x1)        # x5 = memory[8]

    # Additional test: write/load multiple registers
    ADDI    x6, x0, 789
    SD      x6, 16(x1)
    LD      x7, 16(x1)
    nop
