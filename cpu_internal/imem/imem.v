module imem (input rst,
             input wire [63:0] pc_addr,
             output reg [31:0] instruction,
             output reg        exc_en,
             output reg [3:0]  exc_code,
             output reg [63:0] exc_val);
// Number of instructions, 4 bytes each (256Kb)
localparam MEM_SIZE = 4096; 

// Memory array
reg [31:0] imem [0:MEM_SIZE - 1];

// Hardcoded instructions
integer i;
initial begin
    //$readmemh("./ASMcode/tests/instructions/auipc/test.hex", imem);
    $readmemh("./compl_tests/rv64ui-p-simple.hex", imem); 
end

always @(*) begin
    if (rst) begin
        instruction = 32'h00000013;
        exc_en      = 1'b0;
        exc_code    = 4'd0;
        exc_val     = 64'b0;
    end else if (pc_addr[17:2] >= MEM_SIZE && !exc_en) begin // (if out of bounds and we didn't proceed exception yet)
        instruction = 32'h00000013; // NOP
        exc_en      = 1'b1;
        exc_code    = 4'd1;        // cause=1 (Instruction access fault)
        exc_val     = pc_addr;     // MTVAL = bad PC
    end else if (pc_addr[17:2] >= MEM_SIZE && exc_en) begin  // (if out of bounds and we've proceeded exception already)
        instruction = 32'h00000013; // NOP
        exc_en      = 1'b0;
        exc_code    = 4'd0;
        exc_val     = 64'b0;
    end else begin
        instruction = imem[pc_addr[17:2]];
        exc_en      = 1'b0;
        exc_code    = 4'd0;
        exc_val     = 64'b0;
    end
end

endmodule
