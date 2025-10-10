    .section .text
    .globl _start
_start:
    # Testing 0 exception : Instruction address misaligned
    li x1, 8       
    jr x1      # jump to the address stored in x1    

    li x2, 1     

    li x3, 19  # misaligned address
    jr x3      # attempt to jump to misaligned address
    li x4, 999 # never executes

    li x5, 9 # this line simulates OS trap handler instructions
    mret     # return from OS trap handler
    li x6, 7 # continues further execution
    li x7, 6  
    nop                   
