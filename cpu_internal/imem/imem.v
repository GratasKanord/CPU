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
        mem[0] = 32'h002081b3; // ADD x3, x1, x2
        mem[1] = 32'h00310133; // ADD x2, x2, x3
        mem[2] = 32'h00628663; // BEQ x5, x6, +offset (branch taken)
        mem[3] = 32'h00728663; // BNE x5, x7, +offset (branch not taken)
        mem[4] = 32'h00430663; // BLT x6, x4, +offset (branch taken)
        mem[5] = 32'h00530663; // BGE x6, x5, +offset (branch not taken)
        for (i = 6; i < MEM_SIZE; i = i + 1) mem[i] = 32'h00000013;          
    end

    always @(*) begin
        instruction = mem[pc[17:2]]; // we use 16 
    end
    
endmodule