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
