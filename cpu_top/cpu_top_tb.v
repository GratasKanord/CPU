`timescale 1ns/1ps

module cpu_top_tb;

    reg clk;
    reg rst;

    // Wires from CPU
    wire [63:0] pc_addr;
    wire [31:0] instruction;
    wire branch_taken;

    // Instantiate CPU
    cpu_top uut (
        .clk(clk),
        .rst(rst),
        .pc_addr(pc_addr),
        .instruction(instruction),
        .branch_taken(branch_taken)
    );

    integer i;
    integer cycle_count;

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Simulation control
    localparam MAX_CYCLES = 50;  // stops simulation after 50 instructions

    // Preload memory and registers
    initial begin
        rst = 1;
        #20;
        rst = 0;
        #10

        // Preload registers
        uut.u_regfile.regs[1] = 5;   // x1
        uut.u_regfile.regs[2] = 5;   // x2
        uut.u_regfile.regs[3] = 10;  // x3
        uut.u_regfile.regs[4] = 0;   // x4
        uut.u_regfile.regs[5] = 7;   // x5
        uut.u_regfile.regs[6] = 7;   // x6
        uut.u_regfile.regs[7] = 3;   // x7

        // Preload instructions
        uut.u_imem.mem[0] = 32'h002081b3; // ADD x3, x1, x2
        uut.u_imem.mem[1] = 32'h00530663; // ADD x2, x2, x3
        uut.u_imem.mem[2] = 32'h00628663; // BEQ x5, x6 → taken
        uut.u_imem.mem[3] = 32'h00728663; // BNE x5, x7 → taken
        uut.u_imem.mem[4] = 32'h00430663; // BLT x6, x4 → not taken
        uut.u_imem.mem[5] = 32'h00530663; // BGE x6, x5 → taken
        uut.u_imem.mem[6] = 32'h00000013; // NOP
        uut.u_imem.mem[7] = 32'hFFFFFFFF; // HALT instruction
        for (i = 8; i < 32; i = i + 1) uut.u_imem.mem[i] = 32'h00000013;
    end

    // Monitor PC, instruction, and branch_taken
    initial begin
        $display("Time(ns)\tPC\t\tInstruction\tbranch_taken");
        $monitor("%0dns\t%h\t%h\t%b", $time, pc_addr, instruction, branch_taken);
    end

    // Stop simulation safely on HALT or max cycles
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;

        // Stop if HALT instruction reached
        if (instruction == 32'hFFFFFFFF) begin
            $display("HALT reached at PC=%h, stopping simulation.", pc_addr);
            $finish;
        end

        // Stop if max cycles reached
        if (cycle_count >= MAX_CYCLES) begin
            $display("Max cycles reached (%0d), stopping simulation.", MAX_CYCLES);
            $finish;
        end
    end

    // Initialize cycle count
    initial cycle_count = 0;

endmodule
