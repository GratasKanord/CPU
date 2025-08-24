module alu (
    input  [3:0]  alu_op,
    input  [63:0] input_alu_A,
    input  [63:0] input_alu_B,
    output [63:0] alu_result,
    output        alu_cout
);
    wire [62:0] carry_chain; 
    wire [63:0] slice_result;
    wire [63:0] shift_result;

    // Instance of the LSB slice of ALU    
    alu_lsb u_lsb (
        .alu_op(alu_op),
        .input_alu_A(input_alu_A[0]),
        .input_alu_B(input_alu_B[0]),
        .alu_result(slice_result[0]),
        .alu_cout(carry_chain[0])
    );

    // Instances of the middle slice of ALU
    genvar i;
    generate
        for (i = 1; i < 63; i = i + 1) begin : mid_slice
            alu_mid u_mid (
                .alu_op(alu_op),
                .input_alu_A(input_alu_A[i]),
                .input_alu_B(input_alu_B[i]),
                .cin(carry_chain[i-1]),
                .alu_result(slice_result[i]),
                .alu_cout(carry_chain[i])
            );
        end    
    endgenerate

    // Instances of the MSB slice of ALU
    alu_msb u_msb (
        .alu_op(alu_op),
        .input_alu_A(input_alu_A[63]),
        .input_alu_B(input_alu_B[63]),
        .cin(carry_chain[62]),
        .alu_result(slice_result[63]),
        .alu_cout(alu_cout)
    );
     
    // Shift operations
    assign shift_result = (alu_op == 4'b1101) ? (input_alu_A << input_alu_B[5:0]) : // SLL
                          (alu_op == 4'b1110) ? (input_alu_A >> input_alu_B[5:0]) : // SRL
                          (alu_op == 4'b1111) ? ($signed(input_alu_A) >>> input_alu_B[5:0]) : 0; // SRA

    // Final ALU MUX
    assign alu_result = (alu_op == 4'b1101 || alu_op == 4'b1110 || alu_op == 4'b1111) ? shift_result :           // Shift output
                        (alu_op == 4'b1011 || alu_op == 4'b1100) ? ({63'b0, slice_result[63]}) : slice_result;   // SLT(SLTU) output or usual output
    
endmodule