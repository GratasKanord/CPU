module pc (input wire clk,
           input wire rst,
           input wire pc_en,
           input wire pc_branch_taken,
           input wire pc_trap_taken,
           input wire trap_done,
           input wire [63:0] pc_branch,
           input wire [63:0] pc_trap,
           input wire [63:0] mepc_out,
           output reg [63:0] pc_addr,
           output reg exc_en,               
           output reg [3:0] exc_code,       
           output reg [63:0] exc_val);      
    
    wire [1:0] pc_mode_sel;
    assign pc_mode_sel = trap_done       ? 2'b11 :  // mret (HIGHEST priority)
                     pc_trap_taken   ? 2'b10 :  // trap entry  
                     pc_branch_taken ? 2'b01 :  // branch
                     2'b00;                    // normal
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            //pc_addr  <= 64'b0;  // boot address
            pc_addr <= 64'h80000000; // boot address for compliance tests
        end else if (pc_en) begin
            case (pc_mode_sel)
                2'b00 : pc_addr <= pc_addr + 4;
                2'b01 : pc_addr <= pc_branch;
                2'b10 : pc_addr <= pc_trap;
                2'b11 : pc_addr <= mepc_out;
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
