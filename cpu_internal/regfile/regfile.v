module regfile (input clk,
                input rst,
                input we_regs,
                input [63:0] w_regs_data,
                input [4:0] w_regs_addr,
                input [4:0] r_regs_addr1,
                input [4:0] r_regs_addr2,
                output [63:0] regs_data1,
                output [63:0] regs_data2);
    
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
    assign regs_data1 = (r_regs_addr1 == 0) ? 0 : regs[r_regs_addr1];
    assign regs_data2 = (r_regs_addr2 == 0) ? 0 : regs[r_regs_addr2];
    
    // Writing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) regs[i] <= 64'b0;
        end else if (we_regs && (w_regs_addr != 0)) begin
            regs[w_regs_addr] <= w_regs_data;
        end
    end
    
endmodule
