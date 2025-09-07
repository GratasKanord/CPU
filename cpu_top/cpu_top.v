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
    wire [1:0] priv_lvl;
    wire [1:0] priv_lvl_next;
    wire exc_en, exc_pc_en, exc_imem_en, exc_dmem_en, exc_decoder_en, exc_csr_en;
    wire [3:0] exc_code, exc_pc_code, exc_imem_code, exc_dmem_code, exc_decoder_code, exc_csr_code;
    wire [63:0] exc_val, exc_pc_val, exc_imem_val, exc_dmem_val, exc_decoder_val, exc_csr_val;
    wire trap_taken;
    wire trap_done;
    wire [63:0] mepc_next;
    wire [63:0] mcause_next;
    wire [63:0] mtval_next;
    wire [63:0] mstatus_next;
    wire [63:0] mstatus_current;
    wire [63:0] mtvec_trap;
    wire [63:0] pc_trap_next;
    wire pc_ret_taken;
    wire [63:0] pc_ret;
    wire mret;
    
    assign w_result = (is_JALR) ? pc_addr + 4 :
                      (is_LOAD ? dmem_data :
                      (is_CSR ? csr_data : alu_result));

    assign exc_en = exc_pc_en | exc_imem_en | exc_dmem_en | exc_decoder_en | exc_csr_en;
    assign exc_code = exc_pc_en ? exc_pc_code : 
                      exc_imem_en ? exc_imem_code :
                      exc_dmem_en ? exc_dmem_code :
                      exc_decoder_en ? exc_decoder_code :
                      exc_csr_en ? exc_csr_code : 4'd0;
    assign exc_val =     exc_pc_en ? exc_pc_val : 
                         exc_imem_en ? exc_imem_val :
                         exc_dmem_en ? exc_dmem_val :
                         exc_decoder_en ? exc_decoder_val :
                         exc_csr_en ? exc_csr_val : 64'd0;

    priv_lvl u_priv_lvl(
        .clk(clk),
        .rst(rst),
        .priv_lvl_next(priv_lvl_next),
        .priv_lvl(priv_lvl)
    );

    trap_handler u_trap_handler(
    .clk(clk),
    .rst(rst),
    .exc_en(exc_en),
    .exc_code(exc_code),
    .exc_val(exc_val),
    .irq_en(1'b0),
    .irq_code(4'b0),
    .irq_val(64'b0),
    .mret(mret),
    .pc_addr(pc_addr),
    .mtvec(mtvec_trap),
    .priv_lvl(priv_lvl),
    .mstatus_current(mstatus_current),
    .pc_trap_next(pc_trap_next),
    .trap_taken(trap_taken),
    .trap_done(trap_done),
    .pc_ret_taken(pc_ret_taken),
    .pc_ret(pc_ret),
    .mepc_next(mepc_next),
    .mcause_next(mcause_next),
    .mtval_next(mtval_next),
    .mstatus_next(mstatus_next),
    .priv_lvl_next(priv_lvl_next)
    );
    
    csr_top u_csr_top(
    .clk(clk),
    .rst(rst),
    .we_csr(we_csr),
    .r_csr_addr(r_csr_addr),
    .w_csr_data(w_csr_data),
    .pc_addr(pc_addr),
    .instr_retired(1'b1),
    .priv_lvl(priv_lvl),
    .trap_taken(trap_taken),
    .trap_done(trap_done),
    .mepc_next(mepc_next),
    .mcause_next(mcause_next),
    .mtval_next(mtval_next),
    .mstatus_next(mstatus_next),
    .csr_data(csr_data),
    .exc_en(exc_csr_en),
    .exc_code(exc_csr_code),
    .exc_val(exc_csr_val),
    .mstatus_current(mstatus_current),
    .mtvec_trap(mtvec_trap)
    );
    
    decoder u_decoder(
    .instr(instruction),
    .regs_data1(regs_data1),
    .regs_data2(regs_data2),
    .pc_addr(pc_addr),
    .priv_lvl(priv_lvl),
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
    .w_csr_data(w_csr_data),
    .exc_en(exc_decoder_en),
    .exc_code(exc_decoder_code),
    .exc_val(exc_decoder_val),
    .mret(mret)
    );
    
    dmem u_dmem(
    .clk(clk),
    .rst(rst),
    .we_dmem(we_dmem),
    .is_LOAD(is_LOAD),
    .dmem_word_sel(dmem_word_sel),
    .r_dmem_addr(alu_result),
    .w_dmem_data(regs_data2),
    .dmem_data(dmem_data),
    .exc_en(exc_dmem_en),
    .exc_code(exc_dmem_code),
    .exc_val(exc_dmem_val)
    );
    
    
    imem u_imem(
    .rst(rst),
    .pc_addr(pc_addr),
    .instruction(instruction),
    .exc_en(exc_imem_en),
    .exc_code(exc_imem_code),
    .exc_val(exc_imem_val)
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
    .pc_branch_taken(pc_branch_taken),
    .pc_trap_taken(trap_taken),
    .pc_ret_taken(pc_ret_taken),
    .pc_branch(pc_branch_target),
    .pc_trap(pc_trap_next),
    .pc_ret(pc_ret),
    .pc_addr(pc_addr),
    .exc_en(exc_pc_en),
    .exc_code(exc_pc_code),
    .exc_val(exc_pc_val)
    );
    
    alu u_alu(
    .alu_op(alu_op),
    .input_alu_A(regs_data1),
    .input_alu_B(input_alu_B),
    .alu_result(alu_result),
    .alu_cout()
    );
    
endmodule
