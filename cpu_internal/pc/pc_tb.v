`timescale 1ps/1ps

module pc_tb;
    reg clk;
    reg reset;
    reg enable;
    reg [1:0] sel;
    reg [63:0] pc_branch;
    reg [63:0] pc_interrupt;
    reg [63:0] pc_debug_addr;
    wire [63:0] pc_addr;

    pc uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .sel(sel),
        .pc_branch(pc_branch),
        .pc_interrupt(pc_interrupt),
        .pc_debug_addr(pc_debug_addr),
        .pc_addr(pc_addr)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        enable = 0;
        sel = 2'b00;
        pc_branch = 64'h00000000_00000020;
        pc_interrupt = 64'h00000000_00001000;
        pc_debug_addr = 64'h00000000_DEADBEEF;

        #12 reset = 0;
        enable = 1;

        #20 sel = 2'b00;

        #20 sel = 2'b01;

        #20 sel = 2'b10;

        #20 sel = 2'b11;
        
        #50 $stop;
    end

    initial begin
        $monitor("Time: %0t | reset : %b | en : %b | sel : %b | PC : %h", $time, reset, enable, sel, pc_addr);
    end
    
endmodule