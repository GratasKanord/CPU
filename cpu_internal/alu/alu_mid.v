module alu_mid (
    input wire [3:0] opcode,
    input wire A,
    input wire B,
    input wire cin,
    output reg result,
    output cout
);
    // Internal signals
    wire B_inverted;
    wire sum;
    wire and_out, or_out, nor_out, xor_out, xnor_out, nand_out, pass_a, pass_b, zero_out;

    // Invert B for SUB operation
    assign B_inverted = (opcode == 4'b0001 || opcode == 4'b1011 || opcode == 4'b1100) ? ~B : B;

    // Full adder logic for sum and carry out
    assign sum = (A ^ B_inverted) ^ cin;
    assign cout = (A & B_inverted) | (cin & (A ^ B_inverted));

    assign and_out = A & B;
    assign or_out = A | B;
    assign nor_out = ~(A | B);
    assign xor_out = A ^ B;
    assign xnor_out = ~(A ^ B);
    assign nand_out = ~(A & B);
    assign pass_a = A;
    assign pass_b = B;
    assign zero_out = 0;

    // Output selection based on opcode
    always @(*) begin
        case (opcode)
            4'b0000 : result = sum;
            4'b0001 : result = sum;
            4'b0010 : result = and_out;
            4'b0011 : result = or_out;
            4'b0100 : result = nor_out;
            4'b0101 : result = xor_out;
            4'b0110 : result = xnor_out;
            4'b0111 : result = nand_out;
            4'b1000 : result = pass_a;
            4'b1001 : result = pass_b;
            4'b1010 : result = zero_out;
            default: result = zero_out;
        endcase
    end
endmodule