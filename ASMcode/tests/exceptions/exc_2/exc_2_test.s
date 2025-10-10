    .section .text
    .globl _start
_start:
    # Testing 2 exception : Illegal instruction 
    li x1, 8       
    jr x1      # jump to the address stored in x1    

    li x2, 1     

    li x3, 1  
    li x10, 999 # never executes because in TB it is forced to 32'hF for testing exception (code 2)
    li x10, 999  # must never be executed
    li x11, 999
    li x12, 999
    li x5, 9 # this line simulates OS trap handler instructions
    mret     # return from OS trap handler
    li x6, 8 # continues further execution
    li x7, 7
    li x8, 6  
    nop                   
