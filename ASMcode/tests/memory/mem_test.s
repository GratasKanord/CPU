    .section .text
    .globl _start
_start:
    # Initialize base address for memory
    li      x1, 8        # x1 = base address

    # Initialize registers with some test data
    li      x2, 123           
    li      x3, 456           

    # Store data into memory
    sd      x2, 0(x1)  #should be x8 = 123       
    sw      x3, 4(x1)  #should be x12 = 200 and x13 = 1       

    # Load data back from memory
    lw      x4, 0(x1)  # should be 123       
    lb      x5, 4(x1)  # should be 200       

    li      x6, 8
    li      x7, 9
   nop

   