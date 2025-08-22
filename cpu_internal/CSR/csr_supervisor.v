module csr_supervisor (
    input  wire        clk,
    input  wire        reset,
    input  wire        csr_we,          // write enable from CPU
    input  wire [11:0] csr_addr,        // 12-bit CSR address
    input  wire [63:0] csr_wdata,       // data to write
    input  wire [63:0] pc,              // current PC (for trap)
    input  wire [1:0]  priv_lvl,        // current CPU privilege: 0=U,1=S,3=M
    output reg  [63:0] csr_rdata,
    output reg         illegal_trap,    // pulse for illegal CSR access
    output reg  [63:0] trap_pc          // PC saved for trap
);

    // Supervisor CSRs
    reg [63:0] sstatus;
    reg [63:0] sie;
    reg [63:0] stvec;
    reg [63:0] sscratch;
    reg [63:0] sepc;
    reg [63:0] scause;
    reg [63:0] stval;
    reg [63:0] sip;
    reg [63:0] satp;

    // CSR Addresses
    `define CSR_SSTATUS  12'h100
    `define CSR_SIE      12'h104
    `define CSR_STVEC    12'h105
    `define CSR_SSCRATCH 12'h140
    `define CSR_SEPC     12'h141
    `define CSR_SCAUSE   12'h142
    `define CSR_STVAL    12'h143
    `define CSR_SIP      12'h144
    `define CSR_SATP     12'h180

    // Required privilege function
    function [1:0] csr_required_priv(input [11:0] addr);
        case(addr)
            `CSR_SSTATUS, `CSR_SIE, `CSR_STVEC, `CSR_SSCRATCH,
            `CSR_SEPC, `CSR_SCAUSE, `CSR_STVAL, `CSR_SIP, `CSR_SATP:
                csr_required_priv = 2'b01; // S-mode or higher
            default:
                csr_required_priv = 2'b11; // M-mode
        endcase
    endfunction

    // CSR Read with privilege check
    always @(*) begin
        illegal_trap = 0;
        case(csr_addr)
            `CSR_SSTATUS:  csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? sstatus  : 64'b0;
            `CSR_SIE:      csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? sie      : 64'b0;
            `CSR_STVEC:    csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? stvec    : 64'b0;
            `CSR_SSCRATCH: csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? sscratch : 64'b0;
            `CSR_SEPC:     csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? sepc     : 64'b0;
            `CSR_SCAUSE:   csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? scause   : 64'b0;
            `CSR_STVAL:    csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? stval    : 64'b0;
            `CSR_SIP:      csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? sip      : 64'b0;
            `CSR_SATP:     csr_rdata = (priv_lvl >= csr_required_priv(csr_addr)) ? satp     : 64'b0;
            default:       begin
                csr_rdata = 64'b0;
                illegal_trap = 1;
            end
        endcase
        if (csr_rdata==64'b0 && priv_lvl < csr_required_priv(csr_addr))
            illegal_trap = 1;
    end

    // CSR Write with privilege check
    always @(posedge clk) begin
        if (reset) begin
            sstatus <= 64'b0;
            sie     <= 64'b0;
            stvec   <= 64'b0;
            sscratch<= 64'b0;
            sepc    <= 64'b0;
            scause  <= 64'b0;
            stval   <= 64'b0;
            sip     <= 64'b0;
            satp    <= 64'b0;
            trap_pc <= 64'b0;
            illegal_trap <= 0;
        end else begin
            if (csr_we) begin
                if (priv_lvl < csr_required_priv(csr_addr)) begin
                    // Illegal write trap
                    illegal_trap <= 1;
                    trap_pc <= pc;
                    scause <= 64'd2;              // Illegal instruction code (2)
                    stval <= {52'b0, csr_addr};   // offending CSR address
                end else begin
                    illegal_trap <= 0;
                    case(csr_addr)
                        `CSR_SSTATUS:  sstatus  <= csr_wdata;
                        `CSR_SIE:      sie      <= csr_wdata;
                        `CSR_STVEC:    stvec    <= csr_wdata;
                        `CSR_SSCRATCH: sscratch <= csr_wdata;
                        `CSR_SEPC:     sepc     <= csr_wdata;
                        `CSR_SCAUSE:   scause   <= csr_wdata;
                        `CSR_STVAL:    stval    <= csr_wdata;
                        `CSR_SIP:      sip      <= csr_wdata;
                        `CSR_SATP:     satp     <= csr_wdata;
                    endcase
                end
            end else begin
                illegal_trap <= 0;
            end
        end
    end

endmodule
