module pc (input wire clk,
           input wire rst,
           input wire pc_en,
           input wire pc_branch_taken,
           input wire pc_trap_taken,
           input wire trap_done,
           input wire [63:0] pc_branch,
           input wire [63:0] pc_trap,
           input wire [63:0] mepc_out,
           output reg [63:0] pc_addr,
           output reg exc_en,               
           output reg [3:0] exc_code,       
           output reg [63:0] exc_val);      
    
    //wire addr_misaligned;
    wire [1:0] pc_mode_sel;
    //assign addr_misaligned = |pc_addr[1:0]; 
    assign pc_mode_sel = pc_trap_taken   ? 2'b10 :          // 00: normal, 01: branch, 10: trap, 11: debug
                         pc_branch_taken ? 2'b01 :
                         trap_done       ? 2'b11 : 2'b0;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            //pc_addr  <= 64'b0;  // boot address
            pc_addr <= 64'b0;
        end else if (pc_en) begin
            case (pc_mode_sel)
                2'b00 : pc_addr <= pc_addr + 4;
                2'b01 : pc_addr <= pc_branch;
                2'b10 : pc_addr <= pc_trap;
                2'b11 : pc_addr <= mepc_out;
            endcase
        end else pc_addr <= pc_addr;
    end

    always @(*) begin
        if (|pc_addr[1:0]) begin
            exc_en = 1'b1;
            exc_code = 4'd0;     // cause = 0 - instrucion misalignment code
            exc_val = pc_addr;
        end else begin
            exc_en = 1'b0;
            exc_code = 4'd0;     
            exc_val = 64'b0;    // save misaligned PC (for trap handler)
        end
    end
endmodule
module regfile (input clk,
                input rst,
                input we_regs,
                input [63:0] w_regs_data,
                input [4:0] w_regs_addr,
                input [4:0] r_regs_addr1,
                input [4:0] r_regs_addr2,
                output [63:0] regs_data1,
                output [63:0] regs_data2);
    
    // 32 registers, each 64b width
    reg [63:0] regs [31:0];
    
    // For simulator (making all registers' values 0)
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) regs[i] = 0;
    end
    
    task dump_regs;
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%d = %d", i, regs[i]);
        end
    endtask
    
    // Reading
    assign regs_data1 = (r_regs_addr1 == 0) ? 0 : regs[r_regs_addr1];
    assign regs_data2 = (r_regs_addr2 == 0) ? 0 : regs[r_regs_addr2];
    
    // Writing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) regs[i] <= 64'b0;
            end else if (we_regs && (w_regs_addr != 0)) begin
            regs[w_regs_addr] <= w_regs_data;
        end
    end
    
endmodule
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
module csr_user (input wire clk,
                 input wire rst,
                 input wire we_csr,            // write enable from CPU
                 input wire [11:0] r_csr_addr, // 12-bit CSR address
                 input wire [63:0] w_csr_data, // data to write
                 output reg [63:0] csr_data,
                 output reg exc_en,            // exceptions handling
                 output reg [3:0] exc_code,
                 output reg [63:0] exc_val);
    
    // User CSRs
    reg [63:0] ustatus;
    reg [63:0] uie;
    reg [63:0] utvec;
    reg [63:0] uscratch;
    reg [63:0] uepc;
    reg [63:0] ucause;
    reg [63:0] utval;
    reg [63:0] uip;
    
    // CSR Addresses
    `define CSR_USTATUS   12'h000
    `define CSR_UIE       12'h004
    `define CSR_UTVEC     12'h005
    `define CSR_USCRATCH  12'h040
    `define CSR_UEPC      12'h041
    `define CSR_UCAUSE    12'h042
    `define CSR_UTVAL     12'h043
    `define CSR_UIP       12'h044
    
    // CSR Read
    always @(*) begin
        csr_data     = 64'b0;
        exc_en   = 1'b0;
        exc_code = 4'd0;
        exc_val  = 64'd0;
        case(r_csr_addr)
            `CSR_USTATUS:   csr_data = ustatus;
            `CSR_UIE:       csr_data = uie;
            `CSR_UTVEC:     csr_data = utvec;
            `CSR_USCRATCH:  csr_data = uscratch;
            `CSR_UEPC:      csr_data = uepc;
            `CSR_UCAUSE:    csr_data = ucause;
            `CSR_UTVAL:     csr_data = utval;
            `CSR_UIP:       csr_data = uip;
            default: begin
                exc_en       = 1;
                exc_val      = {52'b0, r_csr_addr}; // store CSR address for handler
                exc_code     = 4'd2;  // Illegal instruction cause
            end
        endcase
    end
    
    // CSR Write
    always @(posedge clk) begin
        if (rst) begin
            ustatus  <= 64'b0;
            uie      <= 64'b0;
            utvec    <= 64'b0;
            uscratch <= 64'b0;
            uepc     <= 64'b0;
            ucause   <= 64'b0;
            utval    <= 64'b0;
            uip      <= 64'b0;
            exc_en   <= 1'b0;
            exc_code <= 4'd0;
            exc_val  <= 64'd0;
        end else if (we_csr) begin
            exc_en   <= 1'b0;
            exc_code <= 4'd0;
            exc_val  <= 64'd0;
            case(r_csr_addr)
                `CSR_USTATUS:   ustatus  <= w_csr_data;
                `CSR_UIE:       uie      <= w_csr_data;
                `CSR_UTVEC:     utvec    <= w_csr_data;
                `CSR_USCRATCH:  uscratch <= w_csr_data;
                `CSR_UEPC:      uepc     <= w_csr_data;
                `CSR_UCAUSE:    ucause   <= w_csr_data;
                `CSR_UTVAL:     utval    <= w_csr_data;
                `CSR_UIP:       uip      <= w_csr_data;
                default: begin
                    exc_en       <= 1;
                    exc_val      <= {52'b0, r_csr_addr}; // store CSR address for handler
                    exc_code     <= 4'd2;  // Illegal instruction cause
                end
            endcase
        end
    end
    
endmodule
module csr_machine (input wire clk,
                    input wire rst,
                    input wire we_csr,            // write enable from CPU
                    input wire [11:0] r_csr_addr, // 12-bit CSR address
                    input wire [63:0] w_csr_data, // data to write
                    input wire [63:0] pc_addr,    // current PC (for trap)
                    input wire instr_retired,     // instruction retired signal
                    input wire [1:0] priv_lvl,   // current CPU privilege: 0 = U, 1 = S, 3 = M
                    input wire       trap_taken,
                    input wire       trap_done,
                    input wire [63:0] mepc_next,
                    input wire [63:0] mcause_next,
                    input wire [63:0] mtval_next,
                    input wire [63:0] mstatus_next,
                    input wire        mret,
                    output reg [63:0] csr_data,
                    output reg exc_en,            // exceptions handling
                    output reg [3:0] exc_code,
                    output reg [63:0] exc_val,
                    output reg [63:0] mstatus_current,
                    output reg [63:0] mtvec_trap,
                    output wire [63:0] mepc_out);      
    // Machine CSRs
    reg [63:0] mstatus;
    reg [63:0] mepc;    
    reg [63:0] misa;  // read-only
    reg [63:0] mie;
    reg [63:0] mtvec;
    reg [63:0] mscratch;
    reg [63:0] mcause;
    reg [63:0] mtval;
    reg [63:0] mip;
    reg [63:0] mcycle;
    reg [63:0] minstret;
    reg [63:0] time_reg;  // read-only
    reg [63:0] mhartid;   // read-only
    reg [63:0] pmpaddr0;
    reg [63:0] pmpcfg0;
    reg [63:0] mideleg;
    
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
    `define CSR_MHARTID 12'hF14
    `define CSR_PMPADDR0 12'h3B0
    `define CSR_PMPCFG0 12'h3A0
    `define CSR_MIDELEG 12'h303
    
    // Hardwired intstruction set and number of threads
    initial misa = 64'h40000000;  // RV64I
    initial mhartid = 64'h0;

    // Address output for PC
    assign mepc_out = mepc;
    
    // Privilege requirement lookup : 0 = U,1 = S,3 = M
    function [1:0] csr_required_priv(input [11:0] addr);
        case (addr)
            `CSR_MSTATUS, `CSR_MISA, `CSR_MIE, `CSR_MTVEC,
            `CSR_MSCRATCH, `CSR_MEPC, `CSR_MCAUSE, `CSR_MTVAL,
            `CSR_MIP, `CSR_PMPADDR0, `CSR_PMPCFG0, `CSR_MIDELEG:
            csr_required_priv = 2'b11;  // M-mode
            `CSR_MCYCLE, `CSR_MINSTRET, `CSR_CYCLE, `CSR_INSTRET, `CSR_TIME, `CSR_MHARTID:
            csr_required_priv          = 2'b00;  // readable in any mode
            default: csr_required_priv = 2'b11;
        endcase
    endfunction
    
    // CSR Read logic with privilege check
    always @(*) begin
        exc_en       = 1'b0;
        exc_val      = 64'b0;
        exc_code     = 4'b0;
        csr_data     = 64'b0;
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
            `CSR_PMPADDR0: csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? pmpaddr0 : 64'b0;
            `CSR_PMPCFG0:  csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? pmpcfg0 : 64'b0;
            `CSR_MIDELEG:  csr_data = (priv_lvl >= csr_required_priv(r_csr_addr)) ? mideleg : 64'b0;
            `CSR_MCYCLE:   csr_data = mcycle;
            `CSR_MINSTRET: csr_data = minstret;
            `CSR_CYCLE:    csr_data = mcycle;
            `CSR_INSTRET:  csr_data = minstret;
            `CSR_TIME:     csr_data = time_reg;
            `CSR_MHARTID:  csr_data = mhartid;
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
    
    // CSR Write logic
    always @(posedge clk) begin
        if (rst) begin
            mstatus      <= 64'b0;
            mstatus_current <= 64'b0;
            mie          <= 64'b0;
            mtvec        <= 64'b0;
            mtvec_trap   <= 64'b0;
            mscratch     <= 64'b0;
            mepc         <= 64'b0;
            mcause       <= 64'b0;
            mtval        <= 64'b0;
            mip          <= 64'b0;
            mcycle       <= 64'b0;
            minstret     <= 64'b0;
            pmpaddr0     <= 64'b0;
            pmpcfg0      <= 64'b0;
            mideleg      <= 64'b0;
            exc_en       <= 1'b0;
            exc_val      <= 64'b0;
            exc_code     <= 4'b0;
            time_reg     <= 64'b0;
        end else if (trap_taken || trap_done) begin
                mepc    <= mepc_next;
                mcause  <= mcause_next;
                mtval   <= mtval_next;
                mstatus <= mstatus_next;
                mtvec_trap <= mtvec;
        end else begin 
            // Increment counters
            mcycle                      <= mcycle + 1;
            time_reg                    <= time_reg + 1;
            if (instr_retired) minstret <= minstret + 1;
            mstatus_current <= mstatus;
            exc_en       <= 1'b0;
            exc_val      <= 64'b0;
            exc_code     <= 4'b0;
            // CSR write
            if (we_csr) begin
                if (priv_lvl < csr_required_priv(r_csr_addr)) begin
                    exc_en       <= 1;
                    exc_val      <= {52'b0, r_csr_addr}; // store CSR address for handler
                    exc_code     <= 4'd2;     // Illegal Instruction code (2)
                end else begin
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
                        `CSR_PMPADDR0: pmpaddr0 <= w_csr_data;
                        `CSR_PMPCFG0:  pmpcfg0  <= w_csr_data;
                        `CSR_MIDELEG:  mideleg  <= w_csr_data;    
                        `CSR_MISA, `CSR_TIME, `CSR_INSTRET, `CSR_CYCLE, `CSR_MHARTID: begin  // they are read-only
                            exc_en       <= 1;
                            exc_val      <= {52'b0, r_csr_addr}; // store CSR address for handler
                            exc_code     <= 4'd2;                // Illegal Instruction code (2)
                        end
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
module imem (input rst,
             input wire [63:0] pc_addr,
             output reg [31:0] instruction,
             output reg        exc_en,
             output reg [3:0]  exc_code,
             output reg [63:0] exc_val);
// Number of instructions, 4 bytes each (256Kb)
localparam MEM_SIZE = 2048; 

// Memory array
reg [31:0] imem [0:MEM_SIZE - 1];

// Hardcoded instructions
integer i;
initial begin
    //$readmemh("./ASMcode/tests/instructions/auipc/test.hex", imem);
    $readmemh("./compl_tests/rv64ui-p-add.hex", imem);
    
    
end

always @(*) begin
    if (rst) begin
        instruction = 32'h00000013;
        exc_en      = 1'b0;
        exc_code    = 4'd0;
        exc_val     = 64'b0;
    end else if (pc_addr[17:2] >= MEM_SIZE && !exc_en) begin // (if out of bounds and we didn't proceed exception yet)
        instruction = 32'h00000013; // NOP
        exc_en      = 1'b1;
        exc_code    = 4'd1;        // cause=1 (Instruction access fault)
        exc_val     = pc_addr;     // MTVAL = bad PC
    end else if (pc_addr[17:2] >= MEM_SIZE && exc_en) begin  // (if out of bounds and we've proceeded exception already)
        instruction = 32'h00000013; // NOP
        exc_en      = 1'b0;
        exc_code    = 4'd0;
        exc_val     = 64'b0;
    end else begin
        instruction = imem[pc_addr[17:2]];
        exc_en      = 1'b0;
        exc_code    = 4'd0;
        exc_val     = 64'b0;
    end
end

endmodule
module dmem (
    input  wire        clk,
    input  wire        rst,
    input  wire        we_dmem,          // Write enable (store)
    input  wire        is_LOAD,          // Load operation
    input  wire [7:0]  dmem_word_sel,    // Selects operation size
    input  wire [63:0] r_dmem_addr,      // Effective address
    input  wire [63:0] w_dmem_data,      // Data to write
    output reg  [63:0] dmem_data,        // Data to read
    output reg         exc_en,           // Exception enable
    output reg  [3:0]  exc_code,         // Exception code
    output reg  [63:0] exc_val           // Exception value (faulting address)
);

    localparam DMEM_SIZE = 8192;         // Bytes in data memory
    reg [7:0] dmem [0:DMEM_SIZE-1];      // Byte-addressable memory

    // --------------------------------------------------------------
    // Function to determine number of bytes per operation
    // --------------------------------------------------------------
    function integer get_num_bytes(input [7:0] sel);
        begin
            case (sel)
                8'b0000_0001: get_num_bytes = 1; // LB / SB
                8'b0000_0011: get_num_bytes = 2; // LH / SH
                8'b0000_1111: get_num_bytes = 4; // LW / SW
                8'b1111_1111: get_num_bytes = 8; // LD / SD
                default:      get_num_bytes = 1;
            endcase
        end
    endfunction

    // --------------------------------------------------------------
    // Memory initialization (for simulation)
    // --------------------------------------------------------------
    integer i, b;
    initial begin
        for (i = 0; i < DMEM_SIZE; i = i + 1)
            dmem[i] = 8'b0;
    end

    // Optional helper for simulation output
    task dump_mem;
        integer i;
        for (i = 0; i < 16; i = i + 1) begin
            $display("x%d = %d", i, dmem[i]);
        end
    endtask

    // --------------------------------------------------------------
    // Combinational: exception detection + load data output
    // --------------------------------------------------------------
    reg [3:0] num_bytes;

    always @(*) begin
        // Defaults
        exc_en   = 0;
        exc_code = 0;
        exc_val  = 0;
        dmem_data = 64'b0;

        num_bytes = get_num_bytes(dmem_word_sel);

        // -----------------------------
        // STORE operation exceptions
        // -----------------------------
        if (we_dmem) begin
            if (r_dmem_addr + num_bytes - 1 >= DMEM_SIZE) begin
                exc_en   = 1;
                exc_code = 4'd7; // Store access fault
                exc_val  = r_dmem_addr;
            end
            else if ((num_bytes == 2 && r_dmem_addr[0] != 0) ||
                     (num_bytes == 4 && r_dmem_addr[1:0] != 0) ||
                     (num_bytes == 8 && r_dmem_addr[2:0] != 0)) begin
                exc_en   = 1;
                exc_code = 4'd6; // Store address misaligned
                exc_val  = r_dmem_addr;
            end
        end

        // -----------------------------
        // LOAD operation exceptions + read
        // -----------------------------
        else if (is_LOAD && !we_dmem) begin
            if (r_dmem_addr + num_bytes - 1 >= DMEM_SIZE) begin
                exc_en   = 1;
                exc_code = 4'd5; // Load access fault
                exc_val  = r_dmem_addr;
            end
            else if ((num_bytes == 2 && r_dmem_addr[0] != 0) ||
                     (num_bytes == 4 && r_dmem_addr[1:0] != 0) ||
                     (num_bytes == 8 && r_dmem_addr[2:0] != 0)) begin
                exc_en   = 1;
                exc_code = 4'd4; // Load address misaligned
                exc_val  = r_dmem_addr;
            end
            else begin
                dmem_data = 0;
                for (b = 0; b < num_bytes; b = b + 1)
                    dmem_data[b*8 +: 8] = dmem[r_dmem_addr + b];
            end
        end
    end

    // --------------------------------------------------------------
    // Sequential: perform store only if no exception
    // --------------------------------------------------------------
    always @(posedge clk) begin
        if (we_dmem && !exc_en) begin
            for (b = 0; b < num_bytes; b = b + 1)
                dmem[r_dmem_addr + b] <= w_dmem_data[b*8 +: 8];
        end
    end

endmodule
module decoder (input [31:0] instr,
                input [63:0] regs_data1,
                regs_data2,                     // registers' values
                input [63:0] csr_data,
                input [63:0] pc_addr,
                input [1:0]  priv_lvl,
                input        trap_taken,
                input        trap_done,
                output reg [3:0] alu_op,
                output reg [4:0] r_regs_addr1,  // 1st register's address
                output reg [4:0] r_regs_addr2,  // 2nd register's address
                output reg [4:0] w_regs_addr,   // destination register (address)
                output reg we_regs,             // write enable signal for registers
                output reg we_dmem,             // write enable signal for memory
                output reg [7:0] dmem_word_sel, // byte enable signal for store/load instructions
                output [63:0] input_alu_B,
                output reg is_JALR,
                output reg is_LOAD,
                output reg is_CSR,
                output reg is_32bit,
                output reg [63:0] imm,
                output reg pc_branch_taken,
                output [63:0] pc_branch_target,
                output reg [11:0] r_csr_addr,
                output reg we_csr,
                output reg [63:0] w_csr_data,
                output reg exc_en,
                output reg [3:0] exc_code,
                output reg [63:0] exc_val,
                output reg mret);
    reg [2:0] func3;
    reg [6:0] func7;
    reg alu_B_src;
    reg [11:0] sys_instr;
    
    assign pc_branch_target = (is_JALR) ? ((regs_data1 + imm) & ~1) : pc_addr + imm;
    
    assign input_alu_B = (alu_B_src) ? imm : regs_data2;
    
    always @(*) begin
        func3           = 0;
        func7           = 0;
        r_regs_addr1    = 0;
        r_regs_addr2    = 0;
        w_regs_addr     = 0;
        imm             = 0;
        we_regs         = 0;
        we_dmem         = 0;
        alu_B_src       = 0;
        pc_branch_taken = 0;
        is_JALR         = 0;
        is_LOAD         = 0;
        is_CSR          = 0;
        is_32bit        = 0;
        we_csr          = 0;
        exc_en     = 0;
        exc_code   = 0;  
        exc_val    = 0;
        
        if (!trap_taken && !trap_done) begin    // don't decode instruction during entering/exiting trap
            //Decoding instruction & exctracting it's parts
            case (instr[6:0])
                7'b0110011 : begin          //R-type
                    func3        = instr[14:12];
                    func7        = instr[31:25];
                    r_regs_addr1 = instr[19:15];
                    r_regs_addr2 = instr[24:20];
                    w_regs_addr  = instr[11:7];
                    we_regs      = 1;
                end
                7'b0010011 : begin          //I-type immediate
                    func3        = instr[14:12];
                    func7        = instr[31:25];
                    r_regs_addr1 = instr[19:15];
                    w_regs_addr  = instr[11:7];
                    imm          = {{52{instr[31]}}, instr[31:20]};
                    we_regs      = 1;
                    alu_B_src    = 1;
                end
                7'b0011011 : begin          //I-type immediate 32-bit
                    func3        = instr[14:12];
                    func7        = instr[31:25];
                    r_regs_addr1 = instr[19:15];
                    w_regs_addr  = instr[11:7];
                    imm          = {{52{instr[31]}}, instr[31:20]};
                    we_regs      = 1;
                    alu_B_src    = 1;
                    is_32bit     = 1;
                end
                7'b0000011 : begin          //I-type load
                    func3        = instr[14:12];
                    r_regs_addr1 = instr[19:15];
                    w_regs_addr  = instr[11:7];
                    imm          = {{52{instr[31]}}, instr[31:20]};
                    we_regs      = 1;
                    we_dmem      = 0;
                    alu_B_src    = 1;
                    is_LOAD      = 1;
                end
                7'b1100111 : begin          //I-type jump
                    func3           = instr[14:12];
                    r_regs_addr1    = instr[19:15];
                    w_regs_addr     = instr[11:7];
                    imm             = {{52{instr[31]}}, instr[31:20]};
                    we_regs         = 1;
                    alu_B_src       = 1;
                    pc_branch_taken = 1;
                    is_JALR         = 1;
                end
                7'b0100011 : begin          //S-type store
                    func3        = instr[14:12];
                    r_regs_addr1 = instr[19:15];
                    r_regs_addr2 = instr[24:20];
                    imm          = {{52{instr[31]}}, instr[31:25], instr[11:7]};
                    we_regs      = 0;
                    we_dmem      = 1;
                    alu_B_src    = 1;
                end
                7'b1100011 : begin          //B-type
                    func3        = instr[14:12];
                    r_regs_addr1 = instr[19:15];
                    r_regs_addr2 = instr[24:20];
                    imm          = {{51{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
                    we_regs      = 0;
                    alu_B_src    = 1;
                end
                7'b0110111 : begin          //U-type LUI
                    w_regs_addr = instr[11:7];
                    imm         = {{32{instr[31]}}, instr[31:12], 12'b0};
                    we_regs     = 1;
                    alu_B_src   = 1;
                end
                7'b0010111 : begin          //U-type AUIPC
                    w_regs_addr = instr[11:7];
                    imm         = {{32{instr[31]}}, instr[31:12], 12'b0};
                    we_regs     = 1;
                    alu_B_src   = 1;
                end
                7'b1101111 : begin          //J-type JAL
                    w_regs_addr     = instr[11:7];
                    imm             = {{43{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                    we_regs         = 1;
                    alu_B_src       = 1;
                    pc_branch_taken = 1;
                end
                7'b1110011 : begin          // System/SCR
                    sys_instr = instr[31:20];
                    if (sys_instr != 12'b0 &&
                        sys_instr != 12'b1 &&
                        sys_instr != 12'b001100000010) begin
                        r_csr_addr = instr[31:20];
                    end                 
                    w_regs_addr  = instr[11:7];
                    r_regs_addr1 = instr[19:15];
                    func3        = instr[14:12];
                    imm          = {59'b0, instr[19:15]}; // for immediate versions (zimm)
                    is_CSR       = 1;
                    we_dmem      = 0;
                    we_regs      = (w_regs_addr != 0);
                end
                default: begin
                    exc_en   = 1'b1;
                    exc_code = 4'd2;       // Illegal instruction
                    exc_val  = instr;
                    func3        = 0;
                    func7        = 0;
                    r_regs_addr1 = 0;
                    r_regs_addr2 = 0;
                    w_regs_addr  = 0;
                    imm          = 0;
                    we_regs      = 0;
                    we_dmem      = 0;
                    alu_B_src    = 0;
                    is_JALR      = 0;
                    is_LOAD      = 0;
                    is_CSR       = 0;
                    is_32bit     = 0;
                    we_csr       = 0;
                end
            endcase
        end
    end
    
    // Decoding ALU opcode for R-type instructions
    always @(*) begin
        if (instr[6:0] == 7'b0110011) begin
            case ({func7, func3})
                10'b0000000000: alu_op = 4'b0000; // ADD
                10'b0100000000: alu_op = 4'b0001; // SUB
                10'b0000000001: alu_op = 4'b1101; // SLL
                10'b0000000010: alu_op = 4'b1011; // SLT
                10'b0000000011: alu_op = 4'b1100; // SLTU
                10'b0000000100: alu_op = 4'b0101; // XOR
                10'b0000000101: alu_op = 4'b1110; // SRL
                10'b0100000101: alu_op = 4'b1111; // SRA
                10'b0000000110: alu_op = 4'b0011; // OR
                10'b0000000111: alu_op = 4'b0010; // AND
                default: alu_op        = 4'b1010;        // NOP
            endcase
        end
    end
    
    // Decoding ALU opcode for I-type instructions
    always @(*) begin
        if (instr[6:0] == 7'b0010011) begin
            case (func3)
                3'b000: alu_op = 4'b0000; // ADDI = ADD
                3'b010: alu_op = 4'b1011; // SLTI = SLT
                3'b011: alu_op = 4'b1100; // SLTIU = SLTU
                3'b100: alu_op = 4'b0101; // XORI = XOR
                3'b110: alu_op = 4'b0011; // ORI = OR
                3'b111: alu_op = 4'b0010; // ANDI = AND
                3'b001: alu_op = 4'b1101; // SLLI = SLL
                3'b101: begin              // SRLI / SRAI
                    if (func7 == 7'b0000000)
                        alu_op = 4'b1110; // SRLI = SRL
                    else if (func7 == 7'b0100000)
                        alu_op = 4'b1111; // SRAI = SRA
                    else
                        alu_op = 4'b1010; // default NOP
                end
                default: alu_op = 4'b1010;   // default NOP
            endcase
        end
    end

    // Decoding ALU opcode for I-type instructions 32 bit
    always @(*) begin
        if (instr[6:0] == 7'b0011011) begin
            case (func3)
                3'b000: alu_op = 4'b0000; // ADDIW
                3'b001: alu_op = 4'b1101; // SLLIW
                3'b101: begin              // SRLIW / SRAIW
                    if (func7 == 7'b0000000)
                        alu_op = 4'b1110; // SRLIW
                    else if (func7 == 7'b0100000)
                        alu_op = 4'b1111; // SRAIW
                    else
                        alu_op = 4'b1010; // NOP/default
                end
                default: alu_op = 4'b1010; // NOP/default
            endcase
        end
    end

    
    //ALU opcode for I-type jump, U-type and J-type instructions
    always @(*) begin
        if (instr[6:0] == 7'b0110111 ||
        instr[6:0] == 7'b1100111 ||
        instr[6:0] == 7'b0010111 ||
        instr[6:0] == 7'b1101111) begin
        alu_op = 4'b0000; //Add operation
    end
    end
    
    //Decoding B-type instructions
    always @(*) begin
        if (instr[6:0] == 7'b1100011) begin
            case (func3)
                3'b000: pc_branch_taken  = (regs_data1 == regs_data2); // BEQ
                3'b001: pc_branch_taken  = (regs_data1 != regs_data2); // BNE
                3'b100: pc_branch_taken  = ($signed(regs_data1) < $signed(regs_data2)); // BLT
                3'b101: pc_branch_taken  = ($signed(regs_data1) >= $signed(regs_data2)); // BGE
                3'b110: pc_branch_taken  = (regs_data1 < regs_data2); // BLTU
                3'b111: pc_branch_taken  = (regs_data1 >= regs_data2); // BGEU
                default: pc_branch_taken = 0;
            endcase
        end
    end
    
    //Decoding I-type load and S-type
    always @(*) begin
        dmem_word_sel = 8'b0000_0000;  // default: no bytes enabled
        if (instr[6:0] == 7'b0100011) begin
            alu_op = 4'b0000;
            case (func3)
                3'b000: dmem_word_sel  = 8'b0000_0001; // SB
                3'b001: dmem_word_sel  = 8'b0000_0011; // SH
                3'b010: dmem_word_sel  = 8'b0000_1111; // SW
                3'b011: dmem_word_sel  = 8'b1111_1111; // SD
                default: dmem_word_sel = 8'b0000_0000;
            endcase
        end else if (instr[6:0] == 7'b0000011) begin
            alu_op = 4'b0000;
            case (func3)
                3'b000: dmem_word_sel = 8'b0000_0001; // LB
                3'b001: dmem_word_sel = 8'b0000_0011; // LH
                3'b010: dmem_word_sel = 8'b0000_1111; // LW
                3'b011: dmem_word_sel = 8'b1111_1111; // LD
                default: dmem_word_sel = 8'b0000_0000;
            endcase
        end
    end
    
    // Decoding System/CSR instruction
    always @(*) begin
        we_csr     = 0;
        w_csr_data = 64'b0;
        
        mret = 0;

        if (instr[6:0] == 7'b1110011) begin
            case (func3)
                3'b0: begin  // Exceptions and system instructions
                    if (sys_instr == 12'b0) begin // ECALL
                        exc_en   = 1'b1;
                        exc_code = (priv_lvl == 2'b11) ? 4'd11 : 
                                   (priv_lvl == 2'b01) ? 4'd9  : 4'd8; 
                        exc_val  = 64'b0;
                    end else if (sys_instr == 12'b1) begin // EBREAK
                        exc_en   = 1'b1;
                        exc_code = 4'd3;
                        exc_val  = 64'b0;
                    end else if (sys_instr == 12'b001100000010) begin // MRET
                        mret = 1'b1;
                    end
                end
                3'b001: begin  // CSRRW
                    we_csr     = 1;
                    w_csr_data = regs_data1;            // write full value
                end
                3'b010: begin  // CSRRS
                    we_csr     = (r_regs_addr1 != 0);
                    w_csr_data = csr_data | regs_data1; // OR old value with regs_data1
                end
                3'b011: begin  // CSRRC
                    we_csr     = (r_regs_addr1 != 0);
                    w_csr_data = csr_data & ~regs_data1; // AND NOT old value with regs_data1
                end
                3'b101: begin  // CSRRWI
                    we_csr     = 1;
                    w_csr_data = imm;             // zimm
                end
                3'b110: begin  // CSRRSI
                    we_csr     = (r_regs_addr1 != 0);
                    w_csr_data = csr_data | imm; // OR old value with zimm
                end
                3'b111: begin  // CSRRCI
                    we_csr     = (r_regs_addr1 != 0);
                    w_csr_data = csr_data & ~imm; // AND NOT old value with zimm
                end
                default: begin
                    we_csr     = 0;
                    w_csr_data = 64'b0;
                    exc_en     = 0;
                    exc_code   = 0;  
                    exc_val    = 0;
                    mret = 0;
                end
            endcase
        end
    end 
endmodule
module trap_handler (
    input  wire        clk,
    input  wire        rst,

    // Exception and interrupt inputs
    input  wire        exc_en,
    input  wire [3:0]  exc_code,
    input  wire [63:0] exc_val,
    input  wire        irq_en,
    input  wire [3:0]  irq_code,
    input  wire [63:0] irq_val,

    // Return instruction
    input  wire        mret,

    // Current pipeline state
    input  wire [63:0] pc_addr,     // faulting PC
    input  wire [63:0] mtvec,       // trap vector base
    input  wire [1:0]  priv_lvl,    // current privilege
    input  wire [63:0] mstatus_current,  // current mstatus from CSR file

    // Outputs to PC / control
    output reg  [63:0] pc_trap_next,
    output reg         trap_taken,
    output reg         trap_done,
    output reg  [63:0] pc_ret,

    // Outputs to CSR file
    output reg [63:0]  mepc_next,
    output reg [63:0]  mcause_next,
    output reg [63:0]  mtval_next,
    output reg [63:0]  mstatus_next,
    output reg  [1:0]  priv_lvl_next
);

    // cause selection
    wire [3:0] cause_code = irq_en ? irq_code : exc_code;
    wire [63:0] cause_val = irq_en ? irq_val  : exc_val;
    wire        is_irq    = irq_en;

    // trap trigger for the system
    
    always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all outputs and internal state
        trap_done      <= 1'b0;
        trap_taken     <= 1'b0;
        pc_trap_next   <= 64'b0;
        mepc_next      <= 64'b0;
        mcause_next    <= 64'b0;
        mtval_next     <= 64'b0;
        mstatus_next   <= 64'b0;
        priv_lvl_next  <= 2'b11;  // default M-mode
    end
    else begin
        trap_done      <= 1'b0;
        trap_taken     <= 1'b0;
        pc_trap_next   <= pc_trap_next;  // hold value by default
        mcause_next    <= mcause_next;    
        mepc_next      <= mepc_next;        
        mtval_next     <= mtval_next;     
        mstatus_next   <= mstatus_next;   
        priv_lvl_next  <= priv_lvl_next;  

        if (exc_en || irq_en) begin
            if (trap_taken) begin
                trap_taken <= 1'b0;
            end else trap_taken <= 1'b1;
            // --- Trap entry ---
            mepc_next      <= pc_addr;
            mcause_next    <= {irq_en, 59'b0, cause_code};
            mtval_next     <= cause_val;

            // Update mstatus
            mstatus_next         <= mstatus_current;
            mstatus_next[7]      <= mstatus_current[3];   // MPIE <- MIE
            mstatus_next[3]      <= 1'b0;                 // MIE <- 0
            mstatus_next[12:11]  <= priv_lvl;            // MPP <- current priv
            pc_trap_next     <= mtvec;
            //pc_trap_next   <= 64'd24;  // simulation: jump to trap handler (used for 0 amd 1 exc test)
            //pc_trap_next   <= 64'd32;  // simulation: jump to trap handler (used for 2, 3 exc test)
            //pc_trap_next   <= 64'd28;  // simulation: jump to trap handler (used for 4, 5, 6, 7 exc test)
            priv_lvl_next  <= 2'b11;   // enter M-mode
        end
        else if (mret) begin
            // --- Trap exit ---
            trap_done <= 1'b1;
            priv_lvl_next  <= mstatus_current[12:11];       // restore priv_lvl

            // Update mstatus on mret
            mstatus_next         <= mstatus_current;
            mstatus_next[3]      <= mstatus_current[7];   // MIE <- MPIE
            mstatus_next[7]      <= 1'b1;                 // MPIE <- 1
            mstatus_next[12:11]  <= 2'b0;        // clear MPP
        end
    end
end


endmodule
module alu_mid (input wire [3:0] alu_op,
                input wire input_alu_A,
                input wire input_alu_B,
                input wire cin,
                output reg alu_result,
                output alu_cout);
// Internal signals
wire B_inverted;
wire sum;
wire and_out, or_out, nor_out, xor_out, xnor_out, nand_out, pass_a, pass_b, zero_out;

// Invert input_alu_B for SUB operation
assign B_inverted = (alu_op == 4'b0001 || alu_op == 4'b1011 || alu_op == 4'b1100) ? ~input_alu_B : input_alu_B;

// Full adder logic for sum and carry out
assign sum      = (input_alu_A ^ B_inverted) ^ cin;
assign alu_cout = (input_alu_A & B_inverted) | (cin & (input_alu_A ^ B_inverted));

// Other ALU operations
assign and_out  = input_alu_A & input_alu_B;
assign or_out   = input_alu_A | input_alu_B;
assign nor_out  = ~(input_alu_A | input_alu_B);
assign xor_out  = input_alu_A ^ input_alu_B;
assign xnor_out = ~(input_alu_A ^ input_alu_B);
assign nand_out = ~(input_alu_A & input_alu_B);
assign pass_a   = input_alu_A;
assign pass_b   = input_alu_B;
assign zero_out = 0;

// Output selection based on alu_op
always @(*) begin
    case (alu_op)
        4'b0000 : alu_result = sum;
        4'b0001 : alu_result = sum;
        4'b0010 : alu_result = and_out;
        4'b0011 : alu_result = or_out;
        4'b0100 : alu_result = nor_out;
        4'b0101 : alu_result = xor_out;
        4'b0110 : alu_result = xnor_out;
        4'b0111 : alu_result = nand_out;
        4'b1000 : alu_result = pass_a;
        4'b1001 : alu_result = pass_b;
        4'b1010 : alu_result = zero_out;
        default: alu_result  = zero_out;
    endcase
end
endmodule
module alu_msb (input wire [3:0] alu_op,
                input wire input_alu_A,
                input wire input_alu_B,
                input wire cin,
                output reg alu_result,
                output alu_cout);
// Internal signals
wire B_inverted;
wire sum;
wire and_out, or_out, nor_out, xor_out, xnor_out, nand_out, pass_a, pass_b, zero_out, slt_out, sltu_out;
wire overflow;

// Invert input_alu_B for SUB operation
assign B_inverted = (alu_op == 4'b0001 || alu_op == 4'b1011 || alu_op == 4'b1100) ? ~input_alu_B : input_alu_B;

// Full adder logic for sum and carry out
assign sum      = (input_alu_A ^ B_inverted) ^ cin;
assign alu_cout = (input_alu_A & B_inverted) | (cin & (input_alu_A ^ B_inverted));

// SLT operation
assign overflow = cin ^ alu_cout;
assign slt_out  = overflow ^ sum;

// SLTU operation
assign sltu_out = ~alu_cout;

// Other ALU operations
assign and_out  = input_alu_A & input_alu_B;
assign or_out   = input_alu_A | input_alu_B;
assign nor_out  = ~(input_alu_A | input_alu_B);
assign xor_out  = input_alu_A ^ input_alu_B;
assign xnor_out = ~(input_alu_A ^ input_alu_B);
assign nand_out = ~(input_alu_A & input_alu_B);
assign pass_a   = input_alu_A;
assign pass_b   = input_alu_B;
assign zero_out = 0;

// Output selection based on alu_op
always @(*) begin
    case (alu_op)
        4'b0000 : alu_result = sum;
        4'b0001 : alu_result = sum;
        4'b0010 : alu_result = and_out;
        4'b0011 : alu_result = or_out;
        4'b0100 : alu_result = nor_out;
        4'b0101 : alu_result = xor_out;
        4'b0110 : alu_result = xnor_out;
        4'b0111 : alu_result = nand_out;
        4'b1000 : alu_result = pass_a;
        4'b1001 : alu_result = pass_b;
        4'b1010 : alu_result = zero_out;
        4'b1011 : alu_result = slt_out;
        4'b1100 : alu_result = sltu_out;
        default: alu_result  = zero_out;
    endcase
end
endmodule
module alu (
    input  [3:0]  alu_op,
    input  [63:0] input_alu_A,
    input  [63:0] input_alu_B,
    input         is_32bit,
    output [63:0] alu_result,
    output        alu_cout
);
    wire [62:0] carry_chain; 
    wire [63:0] slice_result;
    wire [63:0] shift_result;

    // For 32b operations
    wire [31:0] alu_in_A_32  = input_alu_A[31:0];
    wire [31:0] alu_in_B_32  = input_alu_B[31:0];
    wire [31:0] addiw_result_32  = alu_in_A_32 + alu_in_B_32;
    wire [31:0] slliw_result_32  = alu_in_A_32 << input_alu_B[4:0];
    wire [31:0] srliw_result_32  = alu_in_A_32 >> input_alu_B[4:0];
    wire [31:0] sraiw_result_32  = $signed(alu_in_A_32) >>> input_alu_B[4:0];

    // Sign-extend to 64-bit
    wire [63:0] addiw_result = {{32{addiw_result_32[31]}}, addiw_result_32};
    wire [63:0] slliw_result = {{32{slliw_result_32[31]}}, slliw_result_32};
    wire [63:0] srliw_result = {{32{srliw_result_32[31]}}, srliw_result_32};
    wire [63:0] sraiw_result = {{32{sraiw_result_32[31]}}, sraiw_result_32};


    // Instance of the LSB slice of ALU    
    alu_lsb u_lsb (
        .alu_op(alu_op),
        .input_alu_A(input_alu_A[0]),
        .input_alu_B(input_alu_B[0]),
        .alu_result(slice_result[0]),
        .alu_cout(carry_chain[0])
    );

    // Instances of the middle slice of ALU
    genvar i;
    generate
        for (i = 1; i < 63; i = i + 1) begin : mid_slice
            alu_mid u_mid (
                .alu_op(alu_op),
                .input_alu_A(input_alu_A[i]),
                .input_alu_B(input_alu_B[i]),
                .cin(carry_chain[i-1]),
                .alu_result(slice_result[i]),
                .alu_cout(carry_chain[i])
            );
        end    
    endgenerate

    // Instances of the MSB slice of ALU
    alu_msb u_msb (
        .alu_op(alu_op),
        .input_alu_A(input_alu_A[63]),
        .input_alu_B(input_alu_B[63]),
        .cin(carry_chain[62]),
        .alu_result(slice_result[63]),
        .alu_cout(alu_cout)
    );
     
    // Shift operations
    assign shift_result = (alu_op == 4'b1101) ? (input_alu_A << input_alu_B[5:0]) : // SLL
                          (alu_op == 4'b1110) ? (input_alu_A >> input_alu_B[5:0]) : // SRL
                          (alu_op == 4'b1111) ? ($signed(input_alu_A) >>> input_alu_B[5:0]) : 0; // SRA

    // Final ALU MUX
    assign alu_result = (is_32bit && alu_op == 4'b0000) ? addiw_result :
                    (is_32bit && alu_op == 4'b1101) ? slliw_result :
                    (is_32bit && alu_op == 4'b1110) ? srliw_result :
                    (is_32bit && alu_op == 4'b1111) ? sraiw_result :
                    (alu_op == 4'b1101 || alu_op == 4'b1110 || alu_op == 4'b1111) ? shift_result :           
                    (alu_op == 4'b1011 || alu_op == 4'b1100) ? ({63'b0, slice_result[63]}) : slice_result;

endmodulemodule alu_lsb (input wire [3:0] alu_op,
                input wire input_alu_A,
                input wire input_alu_B,
                output reg alu_result,
                output alu_cout);
// Internal signals
wire B_inverted;
wire cin;
wire sum;
wire and_out, or_out, nor_out, xor_out, xnor_out, nand_out, pass_a, pass_b, zero_out;

// Invert input_alu_B and set cin for SUB operation
assign B_inverted = (alu_op == 4'b0001 || alu_op == 4'b1011 || alu_op == 4'b1100) ? ~input_alu_B : input_alu_B;
assign cin        = (alu_op == 4'b0001 || alu_op == 4'b1011 || alu_op == 4'b1100) ? 1 : 0;

// Full adder logic for sum and carry out
assign sum      = (input_alu_A ^ B_inverted) ^ cin;
assign alu_cout = (input_alu_A & B_inverted) | (cin & (input_alu_A ^ B_inverted));

// Other alu computations
assign and_out  = input_alu_A & input_alu_B;
assign or_out   = input_alu_A | input_alu_B;
assign nor_out  = ~(input_alu_A | input_alu_B);
assign xor_out  = input_alu_A ^ input_alu_B;
assign xnor_out = ~(input_alu_A ^ input_alu_B);
assign nand_out = ~(input_alu_A & input_alu_B);
assign pass_a   = input_alu_A;
assign pass_b   = input_alu_B;
assign zero_out = 0;

// Output selection based on alu_op
always @(*) begin
    case (alu_op)
        4'b0000 : alu_result = sum;
        4'b0001 : alu_result = sum;
        4'b0010 : alu_result = and_out;
        4'b0011 : alu_result = or_out;
        4'b0100 : alu_result = nor_out;
        4'b0101 : alu_result = xor_out;
        4'b0110 : alu_result = xnor_out;
        4'b0111 : alu_result = nand_out;
        4'b1000 : alu_result = pass_a;
        4'b1001 : alu_result = pass_b;
        4'b1010 : alu_result = zero_out;
        default: alu_result  = zero_out;
    endcase
end
endmodule
module priv_lvl (
    input wire clk,
    input wire rst,
    input wire [1:0] priv_lvl_next,
    output reg [1:0] priv_lvl
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            priv_lvl <= 2'b11; // M-mode
        end else priv_lvl <= priv_lvl_next; // for traps
    end
    
endmodule