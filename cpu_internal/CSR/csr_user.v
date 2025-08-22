module csr_user (
    input  wire        clk,
    input  wire        reset,
    input  wire        csr_we,        // write enable from CPU
    input  wire [11:0] csr_addr,      // 12-bit CSR address
    input  wire [63:0] csr_wdata,     // data to write
    input  wire [63:0] pc,            // current PC, for trap if needed
    output reg  [63:0] csr_rdata
);

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
        case(csr_addr)
            `CSR_USTATUS:   csr_rdata = ustatus;
            `CSR_UIE:       csr_rdata = uie;
            `CSR_UTVEC:     csr_rdata = utvec;
            `CSR_USCRATCH:  csr_rdata = uscratch;
            `CSR_UEPC:      csr_rdata = uepc;
            `CSR_UCAUSE:    csr_rdata = ucause;
            `CSR_UTVAL:     csr_rdata = utval;
            `CSR_UIP:       csr_rdata = uip;
            default:        csr_rdata = 64'b0;
        endcase
    end

    // CSR Write
    always @(posedge clk) begin
        if (reset) begin
            ustatus  <= 64'b0;
            uie      <= 64'b0;
            utvec    <= 64'b0;
            uscratch <= 64'b0;
            uepc     <= 64'b0;
            ucause   <= 64'b0;
            utval    <= 64'b0;
            uip      <= 64'b0;
        end else if (csr_we) begin
            case(csr_addr)
                `CSR_USTATUS:   ustatus  <= csr_wdata;
                `CSR_UIE:       uie      <= csr_wdata;
                `CSR_UTVEC:     utvec    <= csr_wdata;
                `CSR_USCRATCH:  uscratch <= csr_wdata;
                `CSR_UEPC:      uepc     <= csr_wdata;
                `CSR_UCAUSE:    ucause   <= csr_wdata;
                `CSR_UTVAL:     utval    <= csr_wdata;
                `CSR_UIP:       uip      <= csr_wdata;
            endcase
        end
    end

endmodule
