module csr_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        we_csr,            // write enable
    input  wire [11:0] r_csr_addr,        // CSR address
    input  wire [63:0] w_csr_data,        // write data
    input  wire [63:0] pc_addr,           // current PC
    input  wire        instr_retired,     // instruction retired (for mcycle/minstret)
    input  wire [1:0]  priv_lvl,          // current privilege level (0 = U, 1 = S, 3 = M)
    input  wire        trap_taken,
    input  wire        trap_done,
    input  wire [63:0] mepc_next,
    input  wire [63:0] mcause_next,
    input  wire [63:0] mtval_next,
    input  wire [63:0] mstatus_next, 
    input  wire        mret,
    output reg  [63:0] csr_data,          // read data
    output reg         exc_en,            // exception enable
    output reg  [3:0]  exc_code,          // exception code
    output reg  [63:0] exc_val,            // exception value
    output wire [63:0] mepc_out,
    output wire  [63:0] mstatus_current,
    output wire  [63:0] mtvec_trap
);
    
    wire [63:0] rdata_m, rdata_s, rdata_u;
    wire        trap_m, trap_s, trap_u;
    wire [3:0]  code_m, code_s, code_u;
    wire [63:0] tpc_m,  tpc_s, tpc_u;
    
    // Machine CSRs
    csr_machine u_csr_machine (
        .clk(clk),
        .rst(rst),
        .we_csr(we_csr),
        .r_csr_addr(r_csr_addr),
        .w_csr_data(w_csr_data),
        .pc_addr(pc_addr),
        .instr_retired(instr_retired),
        .priv_lvl(priv_lvl),
        .trap_taken(trap_taken),
        .trap_done(trap_done),
        .mepc_next(mepc_next),
        .mepc_out(mepc_out),
        .mcause_next(mcause_next),
        .mtval_next(mtval_next),
        .mstatus_next(mstatus_next),
        .mret(mret),
        .csr_data(rdata_m),
        .exc_en(trap_m),
        .exc_code(code_m),   
        .exc_val(tpc_m),
        .mstatus_current(mstatus_current),
        .mtvec_trap(mtvec_trap)
    );

    // Supervisor CSRs
    csr_supervisor u_csr_supervisor (
        .clk(clk),
        .rst(rst),
        .we_csr(we_csr),
        .r_csr_addr(r_csr_addr),
        .w_csr_data(w_csr_data),
        .pc_addr(pc_addr),
        .priv_lvl(priv_lvl),
        .csr_data(rdata_s),
        .exc_en(trap_s),
        .exc_code(code_s),   
        .exc_val(tpc_s)
    );

    // User CSRs
    csr_user u_csr_user (
        .clk(clk),
        .rst(rst),
        .we_csr(we_csr),
        .r_csr_addr(r_csr_addr),
        .w_csr_data(w_csr_data),
        .csr_data(rdata_u),
        .exc_en(trap_u),
        .exc_code(code_u),   
        .exc_val(tpc_u)

    );
    
    always @(*) begin
        csr_data = 64'b0;
        exc_en   = 1'b0;
        exc_code = 4'b0;
        exc_val  = 64'b0;

        case (priv_lvl)
            2'b11: begin // M-mode
                if (r_csr_addr[11:10] == 2'b11 || r_csr_addr[11:8] == 4'h3) begin
                    csr_data = rdata_m;
                    exc_en   = trap_m;
                    exc_code = code_m;
                    exc_val  = tpc_m;
                end else if (r_csr_addr[11:8] == 4'h1) begin
                    csr_data = rdata_s;
                    exc_en   = trap_s;
                    exc_code = code_s;
                    exc_val  = tpc_s;
                end else begin
                    csr_data = rdata_u;
                end
            end

            2'b01: begin // S-mode
                if (r_csr_addr[11:8] == 4'h1) begin
                    csr_data = rdata_s;
                    exc_en   = trap_s;
                    exc_code = code_s;
                    exc_val  = tpc_s;
                end else begin
                    csr_data = rdata_u;
                end
            end

            2'b00: begin // U-mode
                if (r_csr_addr[11:8] == 4'h0) begin
                    csr_data = rdata_u;
                    exc_en   = trap_u;
                    exc_code = code_u;
                    exc_val  = tpc_u;
                end
            end 
        endcase
    end

    
endmodule
