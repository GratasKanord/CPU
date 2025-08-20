module dmem (
    input wire clk,
    input wire reset,
    input wire we_mem,
    input wire [7:0] be,
    input [63:0] addr,
    input [63:0] wdata,
    output reg [63:0] rdata
);
    
    localparam MEM_SIZE = 1*1024; // 1Mb
    localparam WORDS = MEM_SIZE/8;
    localparam ADDR_BITS = $clog2(WORDS);
    reg [63:0] mem [0:WORDS - 1];
    reg [63:0] tmp;

    always @(*) begin
        rdata = mem[addr[ADDR_BITS+2:3]];
    end

    task dump_mem;
        integer i;
        for (i = 0; i < 10; i = i + 1) begin
            $display("x%d = %d", i, mem[i]);
        end
    endtask

    integer i;
    initial begin
        for(i=0;i<WORDS;i=i+1)
            mem[i] = 64'b0;
    end

    always @(posedge clk) begin
        if (we_mem) begin
            tmp = mem[addr[ADDR_BITS+2:3]];
            if (be[0]) tmp[7:0]   = wdata[7:0];
            if (be[1]) tmp[15:8]  = wdata[15:8];
            if (be[2]) tmp[23:16] = wdata[23:16];
            if (be[3]) tmp[31:24] = wdata[31:24];
            if (be[4]) tmp[39:32] = wdata[39:32];
            if (be[5]) tmp[47:40] = wdata[47:40];
            if (be[6]) tmp[55:48] = wdata[55:48];
            if (be[7]) tmp[63:56] = wdata[63:56];
            mem[addr[ADDR_BITS+2:3]] <= tmp;
        end
    end

endmodule