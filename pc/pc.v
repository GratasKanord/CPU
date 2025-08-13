module pc (
    input clk,
    input reset,
    input enable,
    input [1:0] sel,  // sel = 00 : normal behavior (increment by 4)
                      // sel = 01 : branch/jump
                      // sel = 10 : interrupt/trap handling
                      // sel = 11 : custom address (for debugging)
    input [63:0] pc_branch,
    input [63:0] pc_interrupt,
    input [63:0] pc_debug_addr,
    output reg [63:0] pc_addr
);
    always @(posedge clk) begin
        if (reset) begin
         pc_addr <= 0;  // boot address
        end else if (enable) begin
            case (sel)
                2'b00 : pc_addr <= pc_addr + 4;
                2'b01 : pc_addr <= pc_branch;
                2'b10 : pc_addr <= pc_interrupt;
                2'b11 : pc_addr <= pc_debug_addr;
            endcase
        end
    end
endmodule