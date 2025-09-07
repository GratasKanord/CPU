    .section .text
    .globl _start
_start:

    # Test Machine CSRs (M-mode)
    # Write to mstatus
    li      x1, 0xB000
    csrrw   x2, mstatus, x1       

    # Read mstatus
    csrr    x3, mstatus           

    # Set bits in mstatus
    li      x4, 0x000F
    csrrs   x5, mstatus, x4       
    csrr    x6, mstatus           

    # Clear bits in mstatus 
    li      x7, 0x000F
    csrrc   x8, mstatus, x7       
    csrr    x9, mstatus

    # Write immediate to mstatus 
    csrrwi  x10, mstatus, 0x00F   # max 31
    csrr    x11, mstatus


    # Test Supervisor CSRs (S-mode)
    # Write to sstatus
    li      x12, 0x1234
    csrrw   x13, sstatus, x12     
    csrr    x14, sstatus          

    # Set bits in sstatus
    li      x15, 0x00F0
    csrrs   x16, sstatus, x15     
    csrr    x17, sstatus

    # Clear bits in sstatus
    li      x18, 0x0F00
    csrrc   x19, sstatus, x18    
    csrr    x20, sstatus    
    # Write immediate to sstatus
    csrrwi  x21, sstatus, 0x0A   
    csrr    x22, sstatus    


    # Test User CSRs (U-mode)
    # Write to ustatus
    li      x23, 0x111
    csrrw   x24, ustatus, x23    
    csrr    x25, ustatus         
    
    # CSRRCI
    csrrci  x26, ustatus, 0x01    
    csrr    x27, ustatus          

    nop

