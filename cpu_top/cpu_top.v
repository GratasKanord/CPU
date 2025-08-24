module cpu_top (input clk,
                input rst);
    wire [63:0] pc_addr;
    wire [31:0] instruction;
    wire [3:0] alu_op;
    wire [4:0] r_regs_addr1, r_regs_addr2, w_regs_addr;
    wire [63:0] regs_data1, regs_data2, alu_result;
    wire we_regs;
    wire we_dmem;
    wire we_csr;
    wire [7:0] dmem_word_sel;
    wire [63:0] imm;
    wire [63:0] input_alu_B;
    wire pc_branch_taken;
    wire [63:0] pc_branch_target;
    wire is_JALR;
    wire is_LOAD;
    wire is_CSR;
    wire [63:0] w_result;
    wire [63:0] dmem_data;
    wire [11:0] r_csr_addr;
    wire [63:0] csr_data;
    wire [63:0] w_csr_data;
    wire illegal_trap;
    wire [63:0] trap_pc;
    
    assign w_result = (is_JALR) ? pc_addr + 4 :
                      (is_LOAD ? dmem_data :
                      (is_CSR ? csr_data : alu_result));
    
    csr_top u_csr_top(
    .clk(clk),
    .rst(rst),
    .we_csr(we_csr),
    .r_csr_addr(r_csr_addr),
    .w_csr_data(w_csr_data),
    .pc_addr(pc_addr),
    .instr_retired(1'b1),
    .priv_lvl(2'b11),
    .csr_data(csr_data),
    .illegal_trap(illegal_trap),
    .trap_pc(trap_pc)
    );
    
    decoder u_decoder(
    .instr(instruction),
    .regs_data1(regs_data1),
    .regs_data2(regs_data2),
    .pc_addr(pc_addr),
    .alu_op(alu_op),
    .r_regs_addr1(r_regs_addr1),
    .r_regs_addr2(r_regs_addr2),
    .w_regs_addr(w_regs_addr),
    .we_regs(we_regs),
    .we_dmem(we_dmem),
    .dmem_word_sel(dmem_word_sel),
    .input_alu_B(input_alu_B),
    .imm(imm),
    .pc_branch_taken(pc_branch_taken),
    .pc_branch_target(pc_branch_target),
    .is_JALR(is_JALR),
    .is_LOAD(is_LOAD),
    .is_CSR(is_CSR),
    .r_csr_addr(r_csr_addr),
    .we_csr(we_csr),
    .csr_data(csr_data),
    .w_csr_data(w_csr_data)
    );
    
    dmem u_dmem(
    .clk(clk),
    .rst(rst),
    .we_dmem(we_dmem),
    .dmem_word_sel(dmem_word_sel),
    .r_dmem_addr(alu_result),
    .w_dmem_data(regs_data2),
    .dmem_data(dmem_data)
    );
    
    
    imem u_imem(
    .pc_addr(pc_addr),
    .instruction(instruction)
    );
    
    regfile u_regfile(
    .clk(clk),
    .rst(rst),
    .we_regs(we_regs),
    .w_regs_data(w_result),
    .w_regs_addr(w_regs_addr),
    .r_regs_addr1(r_regs_addr1),
    .r_regs_addr2(r_regs_addr2),
    .regs_data1(regs_data1),
    .regs_data2(regs_data2)
    );
    
    pc u_pc(
    .clk(clk),
    .rst(rst),
    .pc_en(1'b1),
    .pc_mode_sel({1'b0, pc_branch_taken}),
    .pc_branch(pc_branch_target),
    .pc_interrupt(64'b0),
    .pc_debug_addr(64'b0),
    .pc_addr(pc_addr)
    );
    
    alu u_alu(
    .alu_op(alu_op),
    .input_alu_A(regs_data1),
    .input_alu_B(input_alu_B),
    .alu_result(alu_result),
    .alu_cout()
    );
    
endmodule
