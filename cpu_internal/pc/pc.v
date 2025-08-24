module pc (input wire clk,
           input wire rst,
           input wire pc_en,
           input wire [1:0] pc_mode_sel,    // pc_mode_sel = 00 : normal behavior (increment by 4)
           input wire [63:0] pc_branch,
           input wire [63:0] pc_interrupt,
           input wire [63:0] pc_debug_addr,
           output reg [63:0] pc_addr);
    always @(posedge clk) begin
        if (rst) begin
            pc_addr <= 0;  // boot address
            end else if (pc_en) begin
            case (pc_mode_sel)
                2'b00 : pc_addr <= pc_addr + 4;
                2'b01 : pc_addr <= pc_branch;
                2'b10 : pc_addr <= pc_interrupt;
                2'b11 : pc_addr <= pc_debug_addr;
            endcase
        end
    end
endmodule
