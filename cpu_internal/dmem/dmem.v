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

    localparam DMEM_SIZE = 1024;         // Bytes in data memory
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
