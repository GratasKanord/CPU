    .section .text
    .globl _start
_start:
    # Testing 5 exception : Load access fault
    li x1, 8
    li x2, 1024     

    sw x1, 0(x1)
    lb x3, 0(x2)          
    li x10, 999  # must never be executed
    li x11, 999  # must never be executed 
    li x12, 999  # must never be executed
    li x5, 9 # this line simulates OS trap handler instructions
    mret     # return from OS trap handler
    li x6, 8 # continues further execution
    li x7, 7
    li x8, 6  
    nop                   
