    .section .text
    .globl _start
_start:
    # Testing 1 exception : Instruction access fault
    li x1, 8       
    jr x1      # jump to the address stored in x1    

    #li x2, 1     

    li x3, 820000  # address that points to non-existent instr
    jr x3      # attempt to jump to address that points to non-existent instr
    li x4, 999 # never executes

    li x5, 9 # this line simulates OS trap handler instructions
    mret     # return from OS trap handler
    li x6, 8 # continues further execution
    li x7, 7
    li x8, 6  
    nop                   
