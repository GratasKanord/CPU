module decoder (
    input [31:0] instr,
    input [63:0] rd1, rd2,   // registers' values
    input [63:0] pc_addr,
    output reg [3:0] alu_op,
    output reg [4:0] rs1,    // 1st register's address
    output reg [4:0] rs2,    // 2nd register's address
    output reg [4:0] rd,     // destination register (address)
    output reg we_regs,      // write enable signal for registers
    output reg we_mem,       // write enable signal for memory
    output reg [7:0] be,     // byte enable signal for store/load instructions
    output [63:0] alu_B,
    output reg is_JALR,
    output reg is_LOAD,
    output reg [63:0] imm,
    output reg branch_taken,
    output [63:0] branch_target

);
    reg [2:0] func3;
    reg [6:0] func7;
    reg alu_B_src;

    assign branch_target = (is_JALR) ? ((rd1 + imm) & ~1) : pc_addr + imm;

    assign alu_B = (alu_B_src) ? imm : rd2;

    

    always @(*) begin
        func3 = 0;
        func7 = 0;
        rs1 = 0;
        rs2 = 0;
        rd= 0;
        imm = 0;
        we_regs = 0;
        we_mem = 0;
        alu_B_src = 0;
        branch_taken = 0;
        is_JALR = 0;
        is_LOAD = 0;
        
        //Decoding instruction & exctracting it's parts
        case (instr[6:0])               
            7'b0110011 : begin          //R-type
                func3 = instr[14:12];
                func7 = instr[31:25];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                rd = instr[11:7];
                we_regs = 1;
            end
            7'b0010011 : begin          //I-type immediate
                func3 = instr[14:12];
                func7 = instr[31:25];
                rs1 = instr[19:15];
                rd = instr[11:7];
                imm = {{52{instr[31]}}, instr[31:20]};
                we_regs = 1;
                alu_B_src = 1;
            end
            7'b0000011 : begin          //I-type load
                func3 = instr[14:12];
                rs1 = instr[19:15];
                rd = instr[11:7];
                imm = {{52{instr[31]}}, instr[31:20]};
                we_regs = 1;
                we_mem = 0;
                alu_B_src = 1;
                is_LOAD = 1;
            end
            7'b1100111 : begin          //I-type jump
                func3 = instr[14:12];
                rs1 = instr[19:15];
                rd = instr[11:7];
                imm = {{52{instr[31]}}, instr[31:20]};
                we_regs = 1;
                alu_B_src = 1;
                branch_taken = 1;
                is_JALR = 1;
            end
            7'b0100011 : begin          //S-type store
                func3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm = {{52{instr[31]}}, instr[31:25], instr[11:7]};
                we_regs = 0;
                we_mem = 1;
                alu_B_src = 1;
            end
            7'b1100011 : begin          //B-type
                func3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm = {{51{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};  
                we_regs = 0; 
                alu_B_src = 1;
            end
            7'b0110111 : begin          //U-type LUI
                rd = instr[11:7];
                imm = {{32{instr[31]}}, instr[31:12], 12'b0};    
                we_regs = 1;
                alu_B_src = 1;
            end
            7'b0010111 : begin          //U-type AUIPC
                rd = instr[11:7];
                imm = {{32{instr[31]}}, instr[31:12], 12'b0};
                we_regs = 1;
                alu_B_src = 1;
            end
            7'b1101111 : begin          //J-type JAL
                rd = instr[11:7];
                imm = {{43{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                we_regs = 1; 
                alu_B_src = 1;
                branch_taken = 1;
            end
            default: begin
                func3 = 0;
                func7 = 0;
                rs1 = 0;
                rs2 = 0;
                rd= 0;
                imm = 0;
                we_regs = 0;
                we_mem = 0;
                alu_B_src = 0;
                is_JALR = 0;
                is_LOAD = 0;
            end
        endcase
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
                default: alu_op = 4'b1010;        // NOP
            endcase
        end                           
    end

    // Decoding ALU opcode for I-type immediate instructions
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

    //ALU opcode for I-type jump, U-type and J-type instructions
    always @(*) begin
        if (instr[6:0] == 7'b0110111 ||
            instr[6:0] == 7'b1100111 ||
            instr[6:0] == 7'b0010111 ||
            instr[6:0] == 7'b1101111) begin
            alu_op = 4'b0000; //Add operation 
        end
    end

    //ALU opcode for B-type instructions
    always @(*) begin
        if (instr[6:0] == 7'b1100011) begin
            case (func3)
                3'b000: branch_taken = (rd1 == rd2); // BEQ
                3'b001: branch_taken = (rd1 != rd2); // BNE
                3'b100: branch_taken = ($signed(rd1) < $signed(rd2)); // BLT
                3'b101: branch_taken = ($signed(rd1) >= $signed(rd2)); // BGE
                3'b110: branch_taken = (rd1 < rd2); // BLTU
                3'b111: branch_taken = (rd1 >= rd2); // BGEU
                default: branch_taken = 0;
            endcase
        end
    end

    //ALU opcode for I-type load and S-type
    always @(*) begin
        be = 8'b0000_0000;  // default: no bytes enabled
        if (instr[6:0] == 7'b0100011) begin
            alu_op = 4'b0000;
            case (func3)
                3'b000: be = 8'b0000_0001; // SB
                3'b001: be = 8'b0000_0011; // SH
                3'b010: be = 8'b0000_1111; // SW
                3'b011: be = 8'b1111_1111; // SD
                default: be = 8'b0000_0000;
            endcase
        end else if (instr[6:0] == 7'b0000011) begin
            alu_op = 4'b0000;
            be = 8'b0000_0000;
        end
    end
endmodule