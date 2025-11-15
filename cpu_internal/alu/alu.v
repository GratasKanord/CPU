module alu (
    input  [3:0]  alu_op,
    input  [63:0] input_alu_A,
    input  [63:0] input_alu_B,
    input         is_32bit,
    output [63:0] alu_result,
    output        alu_cout
);
    wire [62:0] carry_chain; 
    wire [63:0] slice_result;
    wire [63:0] shift_result;

    // For 32b operations
    wire [31:0] alu_in_A_32  = input_alu_A[31:0];
    wire [31:0] alu_in_B_32  = input_alu_B[31:0];
    wire [31:0] addiw_result_32  = alu_in_A_32 + alu_in_B_32;
    wire [31:0] subw_result_32  = alu_in_A_32 - alu_in_B_32;
    wire [31:0] slliw_result_32  = alu_in_A_32 << input_alu_B[4:0];
    wire [31:0] srliw_result_32  = alu_in_A_32 >> input_alu_B[4:0];
    wire [31:0] sraiw_result_32  = $signed(alu_in_A_32) >>> input_alu_B[4:0];
    
    // Sign-extend to 64-bit
    wire [63:0] addiw_result = {{32{addiw_result_32[31]}}, addiw_result_32};
    wire [63:0] slliw_result = {{32{slliw_result_32[31]}}, slliw_result_32};
    wire [63:0] srliw_result = {{32{srliw_result_32[31]}}, srliw_result_32};
    wire [63:0] sraiw_result = {{32{sraiw_result_32[31]}}, sraiw_result_32};
    wire [63:0] subw_result  = {{32{subw_result_32[31]}}, subw_result_32};


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
                     (alu_op == 4'b1111) ? ((input_alu_A >> input_alu_B[5:0]) | 
                                           (input_alu_A[63] ? (~(64'b0) << (64 - input_alu_B[5:0])) : 0)) : 0;

    // Final ALU MUX
    assign alu_result = (is_32bit && alu_op == 4'b0000) ? addiw_result :
                    (is_32bit && alu_op == 4'b0001) ? subw_result : 
                    (is_32bit && alu_op == 4'b1101) ? slliw_result :
                    (is_32bit && alu_op == 4'b1110) ? srliw_result :
                    (is_32bit && alu_op == 4'b1111) ? sraiw_result :
                    (alu_op == 4'b1101 || alu_op == 4'b1110 || alu_op == 4'b1111) ? shift_result :           
                    (alu_op == 4'b1011 || alu_op == 4'b1100) ? ({63'b0, slice_result[63]}) : slice_result;

endmodule