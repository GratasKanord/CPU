module alu_msb (input wire [3:0] alu_op,
                input wire input_alu_A,
                input wire input_alu_B,
                input wire cin,
                output reg alu_result,
                output alu_cout);
// Internal signals
wire B_inverted;
wire sum;
wire and_out, or_out, nor_out, xor_out, xnor_out, nand_out, pass_a, pass_b, zero_out, slt_out, sltu_out;
wire overflow;

// Invert input_alu_B for SUB operation
assign B_inverted = (alu_op == 4'b0001 || alu_op == 4'b1011 || alu_op == 4'b1100) ? ~input_alu_B : input_alu_B;

// Full adder logic for sum and carry out
assign sum      = (input_alu_A ^ B_inverted) ^ cin;
assign alu_cout = (input_alu_A & B_inverted) | (cin & (input_alu_A ^ B_inverted));

// SLT operation
assign overflow = cin ^ alu_cout;
assign slt_out  = overflow ^ sum;

// SLTU operation
assign sltu_out = ~alu_cout;

// Other ALU operations
assign and_out  = input_alu_A & input_alu_B;
assign or_out   = input_alu_A | input_alu_B;
assign nor_out  = ~(input_alu_A | input_alu_B);
assign xor_out  = input_alu_A ^ input_alu_B;
assign xnor_out = ~(input_alu_A ^ input_alu_B);
assign nand_out = ~(input_alu_A & input_alu_B);
assign pass_a   = input_alu_A;
assign pass_b   = input_alu_B;
assign zero_out = 0;

// Output selection based on alu_op
always @(*) begin
    case (alu_op)
        4'b0000 : alu_result = sum;
        4'b0001 : alu_result = sum;
        4'b0010 : alu_result = and_out;
        4'b0011 : alu_result = or_out;
        4'b0100 : alu_result = nor_out;
        4'b0101 : alu_result = xor_out;
        4'b0110 : alu_result = xnor_out;
        4'b0111 : alu_result = nand_out;
        4'b1000 : alu_result = pass_a;
        4'b1001 : alu_result = pass_b;
        4'b1010 : alu_result = zero_out;
        4'b1011 : alu_result = slt_out;
        4'b1100 : alu_result = sltu_out;
        default: alu_result  = zero_out;
    endcase
end
endmodule
