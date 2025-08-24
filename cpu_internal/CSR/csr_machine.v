module csr_machine (input wire clk,
                    input wire rst,
                    input wire we_csr,            // write enable from CPU
                    input wire [11:0] r_csr_addr, // 12-bit CSR address
                    input wire [63:0] w_csr_data, // data to write
                    input wire [63:0] pc_addr,    // current PC (for trap)
                    input wire instr_retired,     // instruction retired signal
                    input wire [1:0] priv_lvl,   // current CPU privilege: 0 = U, 1 = S, 3 = M
                    output reg [63:0] csr_data,
                    output reg illegal_trap,      // pulse for illegal CSR access
                    output reg [63:0] trap_pc);   // PC saved for trap
    // Machine CSRs
    reg [63:0] mstatus;
    reg [63:0] misa;  // read-only
    reg [63:0] mie;
    reg [63:0] mtvec;
    reg [63:0] mscratch;
    reg [63:0] mepc;
    reg [63:0] mcause;
    reg [63:0] mtval;
    reg [63:0] mip;
    reg [63:0] mcycle;
    reg [63:0] minstret;
    reg [63:0] time_reg;  // read-only
    
    
    // CSR Addresses
    `define CSR_MSTATUS 12'h300
    `define CSR_MISA 12'h301
    `define CSR_MIE 12'h304
    `define CSR_MTVEC 12'h305
    `define CSR_MSCRATCH 12'h340
    `define CSR_MEPC 12'h341
    `define CSR_MCAUSE 12'h342
    `define CSR_MTVAL 12'h343
    `define CSR_MIP 12'h344
    `define CSR_MCYCLE 12'hB00
    `define CSR_MINSTRET 12'hB02
    `define CSR_CYCLE 12'hC00
    `define CSR_INSTRET 12'hC02
    `define CSR_TIME 12'hC01
    
    // Hardwired misa
    initial misa = 64'h40000000;  // RV64I
    
    // Privilege requirement lookup : 0 = U,1 = S,3 = M
    function [1:0] csr_required_priv(input [11:0] addr);
        case (addr)
            `CSR_MSTATUS, `CSR_MISA, `CSR_MIE, `CSR_MTVEC,
            `CSR_MSCRATCH, `CSR_MEPC, `CSR_MCAUSE, `CSR_MTVAL, `CSR_MIP:
            csr_required_priv = 2'b11;  // M-mode
            `CSR_MCYCLE, `CSR_MINSTRET, `CSR_CYCLE, `CSR_INSTRET, `CSR_TIME:
            csr_required_priv          = 2'b00;  // readable in any mode
            default: csr_required_priv = 2'b11;
        endcase
    endfunction
    
    // CSR Read logic with privilege check
    always @(*) begin
        illegal_trap = 0;
        case (r_csr_addr)
            `CSR_MSTATUS:  csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mstatus : 64'b0;
            `CSR_MISA:     csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? misa : 64'b0;
            `CSR_MIE:      csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mie : 64'b0;
            `CSR_MTVEC:    csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mtvec : 64'b0;
            `CSR_MSCRATCH: csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mscratch : 64'b0;
            `CSR_MEPC:     csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mepc : 64'b0;
            `CSR_MCAUSE:   csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mcause : 64'b0;
            `CSR_MTVAL:    csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mtval : 64'b0;
            `CSR_MIP:      csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mip : 64'b0;
            `CSR_MCYCLE:   csr_data = mcycle;
            `CSR_MINSTRET: csr_data = minstret;
            `CSR_CYCLE:    csr_data = mcycle;
            `CSR_INSTRET:  csr_data = minstret;
            `CSR_TIME:     csr_data = time_reg;
            default: begin
                csr_data     = 64'b0;
                illegal_trap = 1;
            end
        endcase
        if (csr_data == 64'b0 && priv_lvl < csr_required_priv(r_csr_addr)) illegal_trap = 1;
    end
    
    // CSR Write logic with privilege check and trap
    always @(posedge clk) begin
        if (rst) begin
            mstatus      <= 64'b0;
            mie          <= 64'b0;
            mtvec        <= 64'b0;
            mscratch     <= 64'b0;
            mepc         <= 64'b0;
            mcause       <= 64'b0;
            mtval        <= 64'b0;
            mip          <= 64'b0;
            mcycle       <= 64'b0;
            minstret     <= 64'b0;
            trap_pc      <= 64'b0;
            time_reg     <= 64'b0;
            illegal_trap <= 0;
            end else begin
            // Increment counters
            mcycle                      <= mcycle + 1;
            time_reg                    <= time_reg + 1;
            if (instr_retired) minstret <= minstret + 1;
            
            // CSR write
            if (we_csr) begin
                if (priv_lvl < csr_required_priv(r_csr_addr)) begin
                    // Illegal write trap
                    illegal_trap <= 1;
                    trap_pc      <= pc_addr;
                    mcause       <= 64'd2;     // Illegal Instruction code (2)
                    mtval        <= {52'b0, r_csr_addr}; // store CSR address for handler
                    end else begin
                    illegal_trap <= 0;
                    case (r_csr_addr)
                        `CSR_MSTATUS:  mstatus  <= w_csr_data;
                        `CSR_MIE:      mie      <= w_csr_data;
                        `CSR_MTVEC:    mtvec    <= w_csr_data;
                        `CSR_MSCRATCH: mscratch <= w_csr_data;
                        `CSR_MEPC:     mepc     <= w_csr_data;
                        `CSR_MCAUSE:   mcause   <= w_csr_data;
                        `CSR_MTVAL:    mtval    <= w_csr_data;
                        `CSR_MIP:      mip      <= w_csr_data;
                        `CSR_MCYCLE:   mcycle   <= w_csr_data;
                        `CSR_MINSTRET: minstret <= w_csr_data;
                        // misa and time_reg are read-only
                    endcase
                end
                end else begin
                illegal_trap <= 0;
            end
        end
    end
    
endmodule
