module alu (
    input [3:0] opcode,
    input [63:0] A,
    input [63:0] B,
    output [63:0] result,
    output cout
);
    wire [62:0] carry_chain; 
    wire [63:0] slice_result;
    wire [63:0] shift_result;

    // Instance of the LSB slice of ALU    
    alu_lsb u_lsb (
        .opcode(opcode),
        .A(A[0]),
        .B(B[0]),
        .result(slice_result[0]),
        .cout(carry_chain[0])
    );

    // Instances of the middle slice of ALU
    genvar i;
    generate
        for (i = 1; i < 63; i = i + 1) begin : mid_slice
            alu_mid u_mid (
                .opcode(opcode),
                .A(A[i]),
                .B(B[i]),
                .cin(carry_chain[i-1]),
                .result(slice_result[i]),
                .cout(carry_chain[i])
            );
        end    
    endgenerate

    // Instances of the MSB slice of ALU
    alu_msb u_msb (
        .opcode(opcode),
        .A(A[63]),
        .B(B[63]),
        .cin(carry_chain[62]),
        .result(slice_result[63]),
        .cout(cout)
    );
     
    // Shift operations
    assign shift_result = (opcode == 4'b1101) ? (A << B[5:0]) : // SLL
                          (opcode == 4'b1110) ? (A >> B[5:0]) : // SRL
                          (opcode == 4'b1111) ? ($signed(A) >>> B[5:0]) : 0; // SRA

    // Final ALU MUX
    assign result = (opcode == 4'b1101 || opcode == 4'b1110 || opcode == 4'b1111) ? shift_result :           // Shift output
                    (opcode == 4'b1011 || opcode == 4'b1100) ? ({63'b0, slice_result[63]}) : slice_result;    // SLT(SLTU) output or usual output
    
endmodule