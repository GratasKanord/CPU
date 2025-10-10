module pc (input wire clk,
           input wire rst,
           input wire pc_en,
           input wire pc_branch_taken,
           input wire pc_trap_taken,
           input wire pc_ret_taken,
           input wire [63:0] pc_branch,
           input wire [63:0] pc_trap,
           input wire [63:0] pc_ret,
           output reg [63:0] pc_addr,
           output reg exc_en,               
           output reg [3:0] exc_code,       
           output reg [63:0] exc_val);      
    
    //wire addr_misaligned;
    wire [1:0] pc_mode_sel;
    //assign addr_misaligned = |pc_addr[1:0]; 
    assign pc_mode_sel = pc_trap_taken   ? 2'b10 :          // 00: normal, 01: branch, 10: trap, 11: debug
                         pc_branch_taken ? 2'b01 :
                         pc_ret_taken    ? 2'b11 : 2'b0;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_addr  <= 64'b0;  // boot address
        end else if (pc_en) begin
            case (pc_mode_sel)
                2'b00 : pc_addr <= pc_addr + 4;
                2'b01 : pc_addr <= pc_branch;
                2'b10 : pc_addr <= pc_trap;
                2'b11 : pc_addr <= pc_ret;
            endcase
        end else pc_addr <= pc_addr;
    end

    always @(*) begin
        if (|pc_addr[1:0]) begin
            exc_en = 1'b1;
            exc_code = 4'd0;     // cause = 0 - instrucion misalignment code
            exc_val = pc_addr;
        end else begin
            exc_en = 1'b0;
            exc_code = 4'd0;     
            exc_val = 64'b0;    // save misaligned PC (for trap handler)
        end
    end
endmodule
