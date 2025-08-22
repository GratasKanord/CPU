    .section .text
    .globl _start
_start:

    # -------------------------
    # Test Machine CSRs (M-mode)
    # -------------------------

    # Write to mstatus
    li      x1, 0xABCD
    csrrw   x2, mstatus, x1       

    # Read mstatus
    csrr    x3, mstatus           

    # Set bits in mstatus (CSRRS)
    li      x4, 0x000F
    csrrs   x5, mstatus, x4       
    csrr    x6, mstatus           

    # Clear bits in mstatus (CSRRC)
    li      x7, 0x000F
    csrrc   x8, mstatus, x7       
    csrr    x9, mstatus

    # Write immediate to mstatus (CSRRWI)
    csrrwi  x10, mstatus, 0x1F   # max 31
    csrr    x11, mstatus

    # # ----------------------------
    # # Test Supervisor CSRs (S-mode)
    # # ----------------------------

    # # Write to sstatus
    li      x12, 0x1234
    csrrw   x13, sstatus, x12     # x12 = old sstatus
    csrr    x14, sstatus           # x13 = current sstatus

    # # Set bits in sstatus
    li      x15, 0x00F0
    csrrs   x16, sstatus, x15     # x14 = old sstatus, sstatus |= 0x00F0
    csrr    x17, sstatus

    # Clear bits in sstatus
    li      x18, 0x0F00
    csrrc   x19, sstatus, x18     # x15 = old sstatus, sstatus &= ~0x0F00
    csrr    x20, sstatus    
    # Write immediate to sstatus
    csrrwi  x21, sstatus, 0x0A    # x16 = old sstatus, sstatus = 0x0A
    csrr    x22, sstatus    

    # --------------------------------------
    # Test User CSRs (U-mode)
    # --------------------------------------

    # Write to ustatus
    li      x23, 0xDEAD
    csrrw   x24, ustatus, x23     # x18 = old ustatus, ustatus = 0xDEAD
    csrr    x25, ustatus          # x19 = current ustatus

    # CSRRCI
    csrrci  x26, mstatus, 0x01    # x26 = old mstatus, mstatus &= ~0x01
    csrr    x27, mstatus          # x19 = current ustatus

    nop

