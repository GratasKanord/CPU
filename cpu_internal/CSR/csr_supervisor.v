module csr_supervisor (input wire clk,
                       input wire rst,
                       input wire we_csr,            // write enable from CPU
                       input wire [11:0] r_csr_addr, // 12-bit CSR address
                       input wire [63:0] w_csr_data, // data to write
                       input wire [63:0] pc_addr,    // current PC (for trap)
                       input wire [1:0] priv_lvl,    // current CPU privilege: 0 = U, 1 = S, 3 = M
                       output reg [63:0] csr_data,
                       output reg exc_en,            // exceptions handling
                       output reg [3:0] exc_code,
                       output reg [63:0] exc_val);   // PC saved for trap
    
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
        exc_en       = 1'b0;
        exc_val      = 64'b0;
        exc_code     = 4'b0;
        csr_data     = 64'b0;
        case(r_csr_addr)
            `CSR_SSTATUS:  csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? sstatus  : 64'b0;
            `CSR_SIE:      csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? sie      : 64'b0;
            `CSR_STVEC:    csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? stvec    : 64'b0;
            `CSR_SSCRATCH: csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? sscratch : 64'b0;
            `CSR_SEPC:     csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? sepc     : 64'b0;
            `CSR_SCAUSE:   csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? scause   : 64'b0;
            `CSR_STVAL:    csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? stval    : 64'b0;
            `CSR_SIP:      csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? sip      : 64'b0;
            `CSR_SATP:     csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? satp     : 64'b0;
            default: begin
                exc_en       = 1;
                exc_val      = {52'b0, r_csr_addr}; // store CSR address for handler
                exc_code     = 4'd2;  // Illegal instruction cause
            end
        endcase
            if (priv_lvl < csr_required_priv(r_csr_addr)) begin
                exc_en       = 1;
                exc_val      = {52'b0, r_csr_addr}; // store CSR address for handler
                exc_code     = 4'd2;  // Illegal instruction cause
            end
    end
        
        // CSR Write with privilege check
    always @(posedge clk) begin
            if (rst) begin
                sstatus      <= 64'b0;
                sie          <= 64'b0;
                stvec        <= 64'b0;
                sscratch     <= 64'b0;
                sepc         <= 64'b0;
                scause       <= 64'b0;
                stval        <= 64'b0;
                sip          <= 64'b0;
                satp         <= 64'b0;
                exc_en       <= 1'b0;
                exc_val      <= 64'b0;
                exc_code     <= 4'b0;
            end else begin
                exc_en       <= 1'b0;
                exc_val      <= 64'b0;
                exc_code     <= 4'b0;
                if (we_csr) begin
                    if (priv_lvl < csr_required_priv(r_csr_addr)) begin
                        exc_en       <= 1;
                        exc_val      <= {52'b0, r_csr_addr}; // store CSR address for handler
                        exc_code     <= 4'd2;     // Illegal Instruction code (2)
                    end else begin
                        case(r_csr_addr)
                            `CSR_SSTATUS:  sstatus  <= w_csr_data;
                            `CSR_SIE:      sie      <= w_csr_data;
                            `CSR_STVEC:    stvec    <= w_csr_data;
                            `CSR_SSCRATCH: sscratch <= w_csr_data;
                            `CSR_SEPC:     sepc     <= w_csr_data;
                            `CSR_SCAUSE:   scause   <= w_csr_data;
                            `CSR_STVAL:    stval    <= w_csr_data;
                            `CSR_SIP:      sip      <= w_csr_data;
                            `CSR_SATP:     satp     <= w_csr_data;
                            default: begin
                            exc_en   <= 1;
                            exc_val  <= {52'b0, r_csr_addr};
                            exc_code <= 4'd2;
                        end   
                        endcase
                    end
                end 
            end
        end   
endmodule
