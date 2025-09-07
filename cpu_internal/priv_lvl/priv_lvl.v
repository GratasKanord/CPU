module priv_lvl (
    input wire clk,
    input wire rst,
    input wire [1:0] priv_lvl_next,
    output reg [1:0] priv_lvl
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            priv_lvl <= 2'b11; // M-mode
        end else priv_lvl <= priv_lvl_next; // for traps
    end
    
endmodule