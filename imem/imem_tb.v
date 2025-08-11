`timescale 1ns/1ps

module imem_tb();
    reg  [63:0] pc;
    wire [31:0] instruction;

    // Instantiate the IMEM module
    imem uut (
        .pc(pc),
        .instruction(instruction)
    );

    integer i;

    initial begin
        // Test first 8 instructions by increasing PC by 4 each time
        for (i = 0; i < 8; i = i + 1) begin
            pc = i * 4;   // PC increments by 4 bytes per instruction
            #10;          // wait 10 ns for instruction to update

            // Display PC and instruction in hex
            $display("PC = 0x%08h : Instruction = 0x%08h", pc, instruction);
        end

        $finish;
    end

endmodule
