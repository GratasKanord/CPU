module cpu_top (
    input clk,
    input rst
);
    wire [63:0] pc_addr;
    wire [31:0] instruction;
    wire [3:0] alu_op;
    wire [4:0] rs1, rs2, rd;
    wire [63:0] rd1, rd2, alu_result;
    wire we_regs;
    wire we_mem;
    wire [7:0] be;
    wire [63:0] imm;
    wire [63:0] alu_B;
    wire branch_taken;
    wire [63:0] branch_target;
    wire is_JALR;
    wire is_LOAD;
    wire [63:0] w_result;
    wire [63:0] mem_data;

    assign w_result = (is_JALR) ? pc_addr + 4 : (is_LOAD ? mem_data : alu_result);

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
    
    dmem u_dmem(
        .clk(clk),
        .reset(rst),
        .we_mem(we_mem),
        .be(be),
        .addr(alu_result),
        .wdata(rd2),
        .rdata(mem_data)
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
        .we_regs(we_regs),
        .we_mem(we_mem),
        .be(be),
        .alu_B(alu_B),
        .imm(imm),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .is_JALR(is_JALR),
        .is_LOAD(is_LOAD)
    );

    regfile u_regfile(
        .clk(clk),
        .rst(rst),
        .we(we_regs),
        .wd(w_result),
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