    .section .text
    .globl _start
_start:
    # ===============================
    # RV64 CPU Test Program
    # Tests R, I, Load, Jump, Branch, LUI, AUIPC
    # ===============================

    # -------------------------------
    # LUI and AUIPC
    # -------------------------------
    lui x1, 0x12345          # x1 = 0x12345000
    auipc x2, 0x10           # x2 = PC + 0x1000 (relative)
    
    # -------------------------------
    # R-type instructions
    # -------------------------------
    li x3, 10                 # load immediate 10
    li x4, 20                 # load immediate 20
    
    add x5, x3, x4            # x5 = x3 + x4 = 30
    sub x6, x4, x3            # x6 = x4 - x3 = 10
    and x7, x3, x4            # x7 = x3 & x4 = 0
    or  x8, x3, x4            # x8 = x3 | x4 = 30
    xor x9, x3, x4            # x9 = x3 ^ x4 = 30
    slt x10, x3, x4           # x10 = (10 < 20)?1:0 = 1
    sltu x11, x4, x3          # x11 = (20 < 10)?1:0 = 0
    sll x12, x3, x4           # x12 = x3 << (x4[5:0])
    srl x13, x4, x3           # x13 = x4 >> x3
    sra x14, x4, x3           # x14 = x4 >> x3 arithmetic
    
    # -------------------------------
    # I-type immediate instructions
    # -------------------------------
    addi x15, x3, 5           # x15 = x3 + 5 = 15
    andi x16, x3, 7           # x16 = x3 & 7 = 2
    ori  x17, x3, 8           # x17 = x3 | 8 = 10
    xori x18, x3, 12          # x18 = x3 ^ 12 = 6
    slti x19, x3, 15          # x19 = (10<15)?1:0 = 1
    sltiu x20, x3, 5          # x20 = (10<5)?1:0 = 0
    slli x21, x3, 2           # x21 = x3 << 2 = 40
    srli x22, x4, 1           # x22 = x4 >> 1 = 10
    srai x23, x4, 1           # x23 = x4 >> 1 arithmetic = 10
    
    # -------------------------------
    # B-type branch instructions
    # -------------------------------
    li x24, 5
    li x25, 5
    beq x24, x25, branch_taken   # should branch
    addi x31, x0, 999             # mark branch not taken

branch_taken:
    addi x26, x0, 1             # mark branch taken
    nop
    
    #-------------------------------
    #J-type jump instruction
    #-------------------------------
    jal x3, jump_label
    addi x31, x0, 999           # skipped
jump_label:
    addi x30, x0, 10           # jumped here

    nop

