module imem (
    input [63:0] pc,
    output reg [31:0] instruction
);
    // Number of instructions, 4 bytes each (256Kb)
    localparam MEM_SIZE = 64; //65536 must be in the final to get 256Kb

    // Memory array
    reg [31:0] mem [0:MEM_SIZE - 1];

    // Hardcoded instructions
    integer i;
    initial begin
        $readmemh("ASMcode/test.hex", mem);   
    end

    always @(*) begin
        instruction = mem[pc[17:2]]; // we use 16 
    end
    
endmodule