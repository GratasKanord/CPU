`timescale 1ns/1ps

module alu_tb;
    reg [3:0] opcode;
    reg [63:0] A;
    reg [63:0] B;
    wire [63:0] result;
    wire cout;

    alu uut (
        .opcode(opcode),
        .A(A),
        .B(B),
        .result(result),
        .cout(cout)
    );

    initial begin
        $monitor("opcode=%b A=%h B=%h -> result=%h", 
                 opcode, A, B, result);
        //A = 64'h0000_0000_0000_00FF;
        //B = 64'h0000_0000_0000_000F;
        A = 64'h7FFF_FFFF_FFFF_FFFF; //h7FFF_FFFF_FFFF_FFFF
        B = 64'h0000_0000_0000_0020; //h0000_0000_0000_0020
        // ADD (0000)
        opcode = 4'b0000; #10;

        // SUB (0001)
        opcode = 4'b0001; #10;

        // AND (0010)
        opcode = 4'b0010; #10;

        // OR (0011)
        opcode = 4'b0011; #10;

        // NOR (0100)
        opcode = 4'b0100; #10;

        // XOR (0101)
        opcode = 4'b0101; #10;

        // XNOR (0110)
        opcode = 4'b0110; #10;

        // NAND (0111)
        opcode = 4'b0111; #10;

        // PASS A (1000)
        opcode = 4'b1000; #10;

        // PASS B (1001)
        opcode = 4'b1001; #10;

        // ZERO/NOP (1010)
        opcode = 4'b1010; #10;

        // SLT (1011)
        opcode = 4'b1011; #10;

        // SLTU (1100)
        opcode = 4'b1100; #10;

        // SLL (1101)
        opcode = 4'b1101; #10;

        // SRL (1110)
        opcode = 4'b1110; #10;

        // SRA (1111)
        opcode = 4'b1111; #10;
    
        $finish;
    end

endmodule
