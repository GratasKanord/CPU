module csr_top (
    input  wire        clk,
    input  wire        reset,
    input  wire        csr_we,           // write enable
    input  wire [11:0] csr_addr,         // CSR address
    input  wire [63:0] csr_wdata,        // write data
    input  wire [63:0] pc,               // current PC
    input  wire        inst_retired,     // instruction retired (for mcycle/minstret)
    input  wire [1:0]  priv_lvl,         // current privilege level (0=U,1=S,3=M)

    output reg  [63:0] csr_rdata,        // read data
    output reg         illegal_trap,     // signal illegal CSR access
    output reg  [63:0] trap_pc           // PC captured on trap
);

    wire [63:0] rdata_m, rdata_s, rdata_u;
    wire        trap_m, trap_s;
    wire [63:0] tpc_m,  tpc_s;

    csr_machine u_csr_machine (
        .clk(clk),
        .reset(reset),
        .csr_we(csr_we),
        .csr_addr(csr_addr),
        .csr_wdata(csr_wdata),
        .pc(pc),
        .inst_retired(inst_retired),
        .priv_lvl(priv_lvl),
        .csr_rdata(rdata_m),
        .illegal_trap(trap_m),
        .trap_pc(tpc_m)
    );

    csr_supervisor u_csr_supervisor (
        .clk(clk),
        .reset(reset),
        .csr_we(csr_we),
        .csr_addr(csr_addr),
        .csr_wdata(csr_wdata),
        .pc(pc),
        .priv_lvl(priv_lvl),
        .csr_rdata(rdata_s),
        .illegal_trap(trap_s),
        .trap_pc(tpc_s)
    );

    csr_user u_csr_user (
        .clk(clk),
        .reset(reset),
        .csr_we(csr_we),
        .csr_addr(csr_addr),
        .csr_wdata(csr_wdata),
        .pc(pc),
        .csr_rdata(rdata_u)
    );

    always @(*) begin
        csr_rdata = 64'b0;
        illegal_trap = 1'b0;
        trap_pc = 64'b0;

        case (priv_lvl)
            2'b11: begin
            // Try M first
            if (!trap_m && (rdata_m != 64'b0)) begin
                csr_rdata = rdata_m;
                illegal_trap = trap_m;  // 0
            end
            // Then S
            else if (!trap_s && (rdata_s != 64'b0)) begin
                csr_rdata = rdata_s;
                illegal_trap = trap_s;  // 0
            end
            // Finally U (may be zero legitimately, but that’s fine)
            else begin
                csr_rdata = rdata_u;
                illegal_trap = 1'b0;    // don’t OR in trap_m/trap_s
            end
            end

            2'b01: begin
            if (!trap_s && (rdata_s != 64'b0)) begin
                csr_rdata = rdata_s;
                illegal_trap = trap_s;
            end else begin
                csr_rdata = rdata_u;
                illegal_trap = 1'b0;
            end
            end

            default: begin // 2'b00
            csr_rdata = rdata_u;
            illegal_trap = 1'b0;
            end
        endcase
    end


endmodule
