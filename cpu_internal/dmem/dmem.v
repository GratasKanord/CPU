module dmem (input wire clk,
             input wire rst,
             input wire we_dmem,
             input wire is_LOAD,
             input wire [7:0] dmem_word_sel,
             input wire [63:0] r_dmem_addr,
             input wire [63:0] w_dmem_data,
             output reg [63:0] dmem_data,
             output reg exc_en,
             output reg [3:0] exc_code,
             output reg [63:0] exc_val);
    
    localparam DMEM_SIZE = 1*1024;          // 1Kb
    localparam WORDS     = DMEM_SIZE/8;         // Get the number of words in the memory (each word     = 8 bytes)
    localparam ADDR_BITS = $clog2(WORDS);   // Get address for each word (or, memory slot) in the memory
    
    reg [63:0] dmem [0:WORDS - 1];
    reg [63:0] tmp;
    
    wire mem_valid;
    assign mem_valid = we_dmem | is_LOAD; // prevents using garbage in r_dmem_addr inside always block

    always @(*) begin
        exc_en   = 0;
        exc_code = 0;
        exc_val  = 0;

        if (mem_valid) begin
                // Load exceptions
            if (r_dmem_addr >= DMEM_SIZE) begin
                exc_en   = 1;
                exc_code = 4'd5; // 5 = load access fault
                exc_val  = r_dmem_addr;
                dmem_data = 64'b0;
            end

            if (!we_dmem) begin
                // Check alignment based on dmem_word_sel
                if ((dmem_word_sel[1] && r_dmem_addr[0] != 0) ||  // halfword misaligned
                    (dmem_word_sel[2] && r_dmem_addr[1:0] != 0) ||  // word misaligned
                    (dmem_word_sel[3] && r_dmem_addr[2:0] != 0) ||  // doubleword misaligned
                    (dmem_word_sel[7] && r_dmem_addr[2:0] != 0)) begin
                    exc_en   = 1;
                    exc_code = 4'd4; // Load address misaligned code
                    exc_val  = r_dmem_addr;
                    dmem_data = 64'b0; // Return zero on exception
                end else begin
                        dmem_data = dmem[r_dmem_addr[ADDR_BITS+2:3]]; // [ADDR_BITS+2:3] is for hiding the bit offset in the address,
                        // basically, we shift the address by 3 (since words are 8-byte aligned)
                end
            end
        end
        
    end
    
    // For simultaion
    task dump_mem;
        integer i;
        for (i = 0; i < 10; i = i + 1) begin
            $display("x%d = %d", i, dmem[i]);
        end
    endtask
    
    // Initializing memory
    integer i;
    initial begin
        for(i = 0;i<WORDS;i = i+1)
            dmem[i] = 64'b0;
    end
    
    always @(posedge clk) begin
        if (we_dmem) begin
            // Check store out-of-bounds exception
            if (r_dmem_addr >= DMEM_SIZE) begin
                exc_en   <= 1;
                exc_code <= 4'd7; // Store access fault
                exc_val  <= r_dmem_addr;
            end
            else if ((dmem_word_sel[1] && r_dmem_addr[0] != 0) || 
                (dmem_word_sel[2] && r_dmem_addr[1:0] != 0) || 
                (dmem_word_sel[3] && r_dmem_addr[2:0] != 0) ||
                (dmem_word_sel[7] && r_dmem_addr[2:0] != 0)) begin
                exc_en   <= 1;
                exc_code <= 4'd6;   // Store address misaligned
                exc_val  <= r_dmem_addr;
            end else begin
                tmp = dmem[r_dmem_addr[ADDR_BITS+2:3]];                 // Store old value to tmp immediately
                if (dmem_word_sel[0]) tmp[7:0]   = w_dmem_data[7:0];
                if (dmem_word_sel[1]) tmp[15:8]  = w_dmem_data[15:8];
                if (dmem_word_sel[2]) tmp[23:16] = w_dmem_data[23:16];
                if (dmem_word_sel[3]) tmp[31:24] = w_dmem_data[31:24];
                if (dmem_word_sel[4]) tmp[39:32] = w_dmem_data[39:32];
                if (dmem_word_sel[5]) tmp[47:40] = w_dmem_data[47:40];
                if (dmem_word_sel[6]) tmp[55:48] = w_dmem_data[55:48];
                if (dmem_word_sel[7]) tmp[63:56] = w_dmem_data[63:56];
                dmem[r_dmem_addr[ADDR_BITS+2:3]] <= tmp;                // Update memory with new value on the next cycle
            end
        end
    end
endmodule
