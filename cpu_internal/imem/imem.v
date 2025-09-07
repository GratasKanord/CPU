module imem (input rst,
             input wire [63:0] pc_addr,
             output reg [31:0] instruction,
             output reg        exc_en,
             output reg [3:0]  exc_code,
             output reg [63:0] exc_val);
// Number of instructions, 4 bytes each (256Kb)
localparam MEM_SIZE = 2048; 

// Memory array
reg [31:0] imem [0:MEM_SIZE - 1];

// Hardcoded instructions
integer i;
initial begin
    //$readmemh("/home/gratas/riscv-tests/isa/rv64ui/add.mem", imem);
    $readmemh("./ASMcode/tests/exceptions/exc_test.hex", imem);

    
end

always @(*) begin
    if (rst) begin
        instruction = 32'h00000013;
        exc_en      = 1'b0;
        exc_code    = 4'd0;
        exc_val     = 64'b0;
    end else if (pc_addr[17:2] >= MEM_SIZE) begin // (if out of bounds)
        //$display("TRAP!");
        instruction = 32'h00000013; // NOP, so decoder doesn’t explode
        exc_en      = 1'b1;
        exc_code    = 4'd1;        // cause=1 (Instruction access fault)
        exc_val     = pc_addr;     // MTVAL = bad PC
    end else begin
        instruction = imem[pc_addr[17:2]];
        exc_en      = 1'b0;
        exc_code    = 4'd0;
        exc_val     = 64'b0;
    end
end

endmodule
