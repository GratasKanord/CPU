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
        mem[0]  = 32'h002081b3; // add x3, x1, x2
        mem[1]  = 32'h40210233; // sub x4, x3, x2
        mem[2]  = 32'h0020a2b3; // and x5, x1, x2
        mem[3]  = 32'h0020b333; // or  x6, x1, x2
        mem[4]  = 32'h0020c3b3; // xor x7, x1, x2
        mem[5]  = 32'h00000013; // nop

        for (i = 6; i < MEM_SIZE; i = i + 1) mem[i] = 32'h00000013;          
    end

    always @(*) begin
        instruction = mem[pc[17:2]]; // we use 16 
    end
    
endmodule