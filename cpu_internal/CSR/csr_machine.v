module csr_machine (
    input wire clk,
    input wire reset,
    input wire csr_we,                 // write enable from CPU
    input wire [11:0] csr_addr,        // 12-bit CSR address
    input wire [63:0] csr_wdata,       // data to write
    input wire [63:0] pc,              // current PC (for trap)
    input wire inst_retired,           // instruction retired signal
    input wire [1:0] priv_lvl,         // current CPU privilege: 0=U,1=S,3=M
    output reg [63:0] csr_rdata,
    output reg illegal_trap,           // pulse for illegal CSR access
    output reg [63:0] trap_pc          // PC saved for trap
);
    // Machine CSRs
    reg [63:0] mstatus;
    reg [63:0] misa;        // read-only
    reg [63:0] mie;
    reg [63:0] mtvec;
    reg [63:0] mscratch;
    reg [63:0] mepc;
    reg [63:0] mcause;
    reg [63:0] mtval;
    reg [63:0] mip;
    reg [63:0] mcycle;
    reg [63:0] minstret;
    reg [63:0] time_reg;        // read-only


    // CSR Addresses
    `define CSR_MSTATUS  12'h300
    `define CSR_MISA     12'h301
    `define CSR_MIE      12'h304
    `define CSR_MTVEC    12'h305
    `define CSR_MSCRATCH 12'h340
    `define CSR_MEPC     12'h341
    `define CSR_MCAUSE   12'h342
    `define CSR_MTVAL    12'h343
    `define CSR_MIP      12'h344
    `define CSR_MCYCLE   12'hB00
    `define CSR_MINSTRET 12'hB02
    `define CSR_CYCLE    12'hC00
    `define CSR_INSTRET  12'hC02
    `define CSR_TIME     12'hC01

    // Hardwired misa
    initial misa = 64'h40000000; // RV64I

    // Privilege requirement lookup : 0=U,1=S,3=M
    function [1:0] csr_required_priv(input [11:0] addr);
        case(addr)
            `CSR_MSTATUS, `CSR_MISA, `CSR_MIE, `CSR_MTVEC,
            `CSR_MSCRATCH, `CSR_MEPC, `CSR_MCAUSE, `CSR_MTVAL, `CSR_MIP:
                csr_required_priv = 2'b11; // M-mode
            `CSR_MCYCLE, `CSR_MINSTRET, `CSR_CYCLE, `CSR_INSTRET, `CSR_TIME:
                csr_required_priv = 2'b00; // readable in any mode
            default:
                csr_required_priv = 2'b11;
        endcase
    endfunction

    // CSR Read logic with privilege check
    always @(*) begin
        illegal_trap = 0;
        case(csr_addr)
            `CSR_MSTATUS:  csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? mstatus : 64'b0;
            `CSR_MISA:     csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? misa    : 64'b0;
            `CSR_MIE:      csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? mie     : 64'b0;
            `CSR_MTVEC:    csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? mtvec   : 64'b0;
            `CSR_MSCRATCH: csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? mscratch: 64'b0;
            `CSR_MEPC:     csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? mepc    : 64'b0;
            `CSR_MCAUSE:   csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? mcause  : 64'b0;
            `CSR_MTVAL:    csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? mtval   : 64'b0;
            `CSR_MIP:      csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? mip     : 64'b0;
            `CSR_MCYCLE:   csr_rdata = mcycle;
            `CSR_MINSTRET: csr_rdata = minstret;
            `CSR_CYCLE:    csr_rdata = mcycle;
            `CSR_INSTRET:  csr_rdata = minstret;
            `CSR_TIME:     csr_rdata = time_reg;
            default: begin
                csr_rdata = 64'b0;
                illegal_trap = 1;
            end
        endcase
        if (csr_rdata == 64'b0 && priv_lvl < csr_required_priv(csr_addr))
            illegal_trap = 1;
    end

    // CSR Write logic with privilege check and trap
    always @(posedge clk) begin
        if (reset) begin
            mstatus   <= 64'b0;
            mie       <= 64'b0;
            mtvec     <= 64'b0;
            mscratch  <= 64'b0;
            mepc      <= 64'b0;
            mcause    <= 64'b0;
            mtval     <= 64'b0;
            mip       <= 64'b0;
            mcycle    <= 64'b0;
            minstret  <= 64'b0;
            trap_pc   <= 64'b0;
            time_reg  <= 64'b0;
            illegal_trap <= 0;
        end else begin
            // Increment counters
            mcycle <= mcycle + 1;
            time_reg <= time_reg + 1;
            if (inst_retired)
                minstret <= minstret + 1;

            // CSR write
            if (csr_we) begin
                if (priv_lvl < csr_required_priv(csr_addr)) begin
                    // Illegal write trap
                    illegal_trap <= 1;
                    trap_pc <= pc;
                    mcause <= 64'd2;     // Illegal Instruction code (2)
                    mtval <= {52'b0, csr_addr}; // store CSR address for handler
                end else begin
                    illegal_trap <= 0;
                    case(csr_addr)
                        `CSR_MSTATUS:  mstatus   <= csr_wdata;
                        `CSR_MIE:      mie       <= csr_wdata;
                        `CSR_MTVEC:    mtvec     <= csr_wdata;
                        `CSR_MSCRATCH: mscratch  <= csr_wdata;
                        `CSR_MEPC:     mepc      <= csr_wdata;
                        `CSR_MCAUSE:   mcause    <= csr_wdata;
                        `CSR_MTVAL:    mtval     <= csr_wdata;
                        `CSR_MIP:      mip       <= csr_wdata;
                        `CSR_MCYCLE:   mcycle    <= csr_wdata;
                        `CSR_MINSTRET: minstret  <= csr_wdata;
                        // misa and time_reg are read-only
                    endcase
                end
            end else begin
                illegal_trap <= 0;
            end
        end
    end

endmodule
