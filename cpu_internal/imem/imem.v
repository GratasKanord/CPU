module imem (input wire [63:0] pc_addr,
             output reg [31:0] instruction);
// Number of instructions, 4 bytes each (256Kb)
localparam MEM_SIZE = 64; //65536 must be in the final version to get 256Kb

// Memory array
reg [31:0] imem [0:MEM_SIZE - 1];

// Hardcoded instructions
integer i;
initial begin
    $readmemh("ASMcode/test.hex", imem);
end

always @(*) begin
    instruction = imem[pc_addr[17:2]]; // we use 16
end

endmodule
