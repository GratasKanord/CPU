`timescale 1ns/1ps

module decoder_tb;

    reg [31:0] instr;
    wire [3:0] alu_op;
    wire [4:0] rs1, rs2, rd;
    wire we;
    wire [63:0] imm;

    // Instantiate the decoder
    decoder uut (
        .instr(instr),
        .alu_op(alu_op),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .we(we),
        .imm(imm)
    );

    initial begin
        // Initialize
        instr = 32'b0;

        // R-type ADD: opcode=0110011, funct3=000, funct7=0000000
        instr = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
        #10;
        $display("R-type ADD: alu_op=%b, rs1=%d, rs2=%d, rd=%d, we=%b, imm=%h", alu_op, rs1, rs2, rd, we, imm);

        // I-type ADDI: opcode=0010011, funct3=000
        instr = {7'b0000000, 5'd1, 5'd2, 3'b000, 5'd3, 7'b0010011};
        #10;
        $display("I-type ADDI: alu_op=%b, rs1=%d, rs2=%d, rd=%d, we=%b, imm=%h", alu_op, rs1, rs2, rd, we, imm);

        // Load (I-type): opcode=0000011, funct3=010 (LW)
        instr = {7'b0000000, 5'd1, 5'd2, 3'b010, 5'd3, 7'b0000011};
        #10;
        $display("Load LW: alu_op=%b, rs1=%d, rs2=%d, rd=%d, we=%b, imm=%h", alu_op, rs1, rs2, rd, we, imm);

        // S-type STORE: opcode=0100011, funct3=010 (SW)
        instr = {7'b0000000, 5'd2, 5'd1, 3'b010, 5'd3, 7'b0100011};
        #10;
        $display("S-type SW: alu_op=%b, rs1=%d, rs2=%d, rd=%d, we=%b, imm=%h", alu_op, rs1, rs2, rd, we, imm);

        // B-type BEQ: opcode=1100011, funct3=000
        instr = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1100011};
        #10;
        $display("B-type BEQ: alu_op=%b, rs1=%d, rs2=%d, rd=%d, we=%b, imm=%h", alu_op, rs1, rs2, rd, we, imm);

        // U-type LUI: opcode=0110111
        instr = {20'hABCDE, 5'd3, 7'b0110111};
        #10;
        $display("U-type LUI: alu_op=%b, rs1=%d, rs2=%d, rd=%d, we=%b, imm=%h", alu_op, rs1, rs2, rd, we, imm);

        // U-type AUIPC: opcode=0010111
        instr = {20'h12345, 5'd3, 7'b0010111};
        #10;
        $display("U-type AUIPC: alu_op=%b, rs1=%d, rs2=%d, rd=%d, we=%b, imm=%h", alu_op, rs1, rs2, rd, we, imm);

        // J-type JAL: opcode=1101111
        instr = {20'hABCDE, 5'd3, 7'b1101111};
        #10;
        $display("J-type JAL: alu_op=%b, rs1=%d, rs2=%d, rd=%d, we=%b, imm=%h", alu_op, rs1, rs2, rd, we, imm);

        $finish;
    end

endmodule
