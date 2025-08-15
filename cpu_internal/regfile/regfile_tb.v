`timescale 1ns/1ps

module regfile_tb;

    reg clk;
    reg we;
    reg [63:0] wd;
    reg [4:0] wa;
    reg [4:0] ra1;
    reg [4:0] ra2;
    wire [63:0] rd1;
    wire [63:0] rd2;

    regfile uut (
        .clk(clk),
        .we(we),
        .wd(wd),
        .wa(wa),
        .ra1(ra1),
        .ra2(ra2),
        .rd1(rd1),
        .rd2(rd2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        we = 0; wd = 0; wa = 0; ra1 = 0; ra2 = 0;
        #10;

        // Write to register 5
        wa = 5'd5; wd = 64'hA5A5A5A5A5A5A5A5; we = 1;
        #10;
        we = 0;
        #10;

        ra1 = 5'd5; ra2 = 5'd0;
        #10;
        $display("Read reg5 = %h, reg0 = %h", rd1, rd2);

        // Write to register 10
        wa = 5'd10; wd = 64'h123456789ABCDEF0; we = 1;
        #10;
        we = 0;
        #10;

        ra1 = 5'd10; ra2 = 5'd5;
        #10;
        $display("Read reg10 = %h, reg5 = %h", rd1, rd2);

        // Write to reg7 with read-after-write test
        wa = 5'd7; wd = 64'hFFFFFFFFFFFFFFFF; we = 1;
        ra1 = 5'd7; ra2 = 5'd5;
        #10;
        $display("Read reg7 (write same cycle) = %h, reg5 = %h", rd1, rd2);

        we = 0;
        #10;

        $finish;
    end

endmodule
