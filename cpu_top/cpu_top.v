module cpu_top (
    input clk,
    input rst,
    output [63:0] pc_addr,
    output [31:0] instruction,
    output branch_taken
);
    // wire [63:0] pc_addr;
    // wire [31:0] instruction;
    wire [3:0] alu_op;
    wire [4:0] rs1, rs2, rd;
    wire [63:0] rd1, rd2, alu_result;
    wire we;
    wire alu_B_src; // 0 -> B = rd2; 1 -> B = imm 
    wire [63:0] imm;
    wire [63:0] alu_B;
    // wire branch_taken;
    wire [63:0] branch_target;

    pc u_pc(
        .clk(clk),
        .reset(rst),
        .enable(1'b1),
        .sel({1'b0, branch_taken}),
        .pc_branch(branch_target),
        .pc_interrupt(64'b0),
        .pc_debug_addr(64'b0),
        .pc_addr(pc_addr)
    );

    imem u_imem(
        .pc(pc_addr),
        .instruction(instruction)
    );

    decoder u_decoder(
        .instr(instruction),
        .rd1(rd1),
        .rd2(rd2),
        .pc_addr(pc_addr),
        .alu_op(alu_op),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .we(we),
        .alu_B(alu_B),
        .imm(imm),
        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );

    regfile u_regfile(
        .clk(clk),
        .we(we),
        .wd(alu_result),
        .wa(rd),
        .ra1(rs1),
        .ra2(rs2),
        .rd1(rd1),
        .rd2(rd2)
    );

    alu u_alu(
        .opcode(alu_op),
        .A(rd1),
        .B(alu_B),
        .result(alu_result),
        .cout()
    );

endmodule