    .section .text
    .globl _start
_start:
    # Testing 4 exception : Load address misaligned
    li x1, 8       
    jr x1      # jump to the address stored in x1    

    sw x1, 0(x1)
    ld x2, 1(x1) # also can try lh, lw          
    li x10, 999  # must never be executed
    li x11, 999  # must never be executed 
    li x12, 999  # must never be executed
    li x5, 9 # this line simulates OS trap handler instructions
    mret     # return from OS trap handler
    li x6, 8 # continues further execution
    li x7, 7
    li x8, 6  
    nop                   
