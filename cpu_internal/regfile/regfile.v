module regfile (
    input clk,
    input we,
    input [63:0] wd,
    input [4:0] wa,
    input [4:0] ra1,
    input [4:0] ra2,
    output [63:0] rd1,
    output [63:0] rd2
);

    // 32 registers, each 64b width
    reg [63:0] regs [31:0];

    // For simulator (making all registers' values 0)
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) regs[i] = 0;
    end

    task dump_regs;
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%d = %d", i, regs[i]);
        end
    endtask

    // Reading
    assign rd1 = (ra1 == 0) ? 0 : regs[ra1];                     
    assign rd2 = (ra2 == 0) ? 0 : regs[ra2];

    // Writing
    always @(posedge clk) begin
        if(we && (wa != 0)) 
            regs[wa] <= wd;
    end
    
endmodule