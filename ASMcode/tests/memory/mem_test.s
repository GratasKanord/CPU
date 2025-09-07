    .section .text
    .globl _start
_start:
    # Initialize base address for memory
    li      x1, 0x0        # x1 = base address

    # Initialize registers with some test data
    li      x2, 123           
    li      x3, 456           

    # Store data into memory
    sd      x2, 0(x1)         
    sd      x3, 8(x1)         

    # Load data back from memory
    ld      x4, 0(x1)         # load from x1 + 0 into x28
    ld      x5, 8(x1)         # load from x1 + 8 into x30


   nop

   