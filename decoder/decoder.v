module decoder (
    input [31:0] instr,
    output reg [3:0] alu_op,
    output reg [4:0] rs1,   // 1st register's address
    output reg [4:0] rs2,   // 2nd register's address
    output reg [4:0] rd,    // destination register (address)
    output reg we,           // write enable signal
    output reg [63:0] imm
);
    reg [2:0]  func3;
    reg [6:0]  func7;

    always @(*) begin
        func3 = 0;
        func7 = 0;
        rs1 = 0;
        rs2 = 0;
        rd= 0;
        imm = 0;
        we = 0;
        
        //Decoding instruction & exctracting it's parts
        case (instr[6:0])               
            7'b0110011 : begin          //R-type
                func3 = instr[14:12];
                func7 = instr[31:25];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                rd = instr[11:7];
                we = 1;
            end
            7'b0010011 : begin          //I-type immediate
                func3 = instr[14:12];
                func7 = instr[31:25];
                rs1 = instr[19:15];
                rd = instr[11:7];
                imm = {{52{instr[31]}}, instr[31:20]};
                we = 1;
            end
            7'b0000011 : begin          //I-type load
                func3 = instr[14:12];
                rs1 = instr[19:15];
                rd = instr[11:7];
                imm = {{52{instr[31]}}, instr[31:20]};
                we = 1;

            end
            7'b1100111 : begin          //I-type jump
                func3 = instr[14:12];
                rs1 = instr[19:15];
                rd = instr[11:7];
                imm = {{52{instr[31]}}, instr[31:20]};
                we = 1;
            end
            7'b0100011 : begin          //S-type store
                func3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm = {{52{instr[31]}}, instr[31:25], instr[11:7]};
                we = 0;
            end
            7'b1100011 : begin          //B-type
                func3 = instr[14:12];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm = {{51{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};  
                we = 0; 
            end
            7'b0110111 : begin          //U-type LUI
                rd = instr[11:7];
                imm = {{32{instr[31]}}, instr[31:12], 12'b0};    
                we = 1;
            end
            7'b0010111 : begin          //U-type AUIPC
                rd = instr[11:7];
                imm = {{32{instr[31]}}, instr[31:12], 12'b0};
                we = 1;
            end
            7'b1101111 : begin          //J-type JAL
                rd = instr[11:7];
                imm = {{43{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                we = 1; 
            end
            default: begin
                func3 = 0;
                func7 = 0;
                rs1 = 0;
                rs2 = 0;
                rd= 0;
                imm = 0;
                we = 0;
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

    // Decoding ALU opcode for I-type instructions
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

    //ALU opcode for I-type load, S-type, U-type and J-type instructions
    always @(*) begin
        if (instr[6:0] == 7'b0000011 ||
            instr[6:0] == 7'b0100011 ||
            instr[6:0] == 7'b1100111 ||
            instr[6:0] == 7'b0010111 ||
            instr[6:0] == 7'b1101111) begin
            alu_op = 4'b0000; //Add operation 
        end
    end

    //ALU opcode for B-type isntructions
    always @(*) begin
        if (instr[6:0] == 7'b1100011) begin
            case (func3)
                3'b000: alu_op = 4'b0001; // BEQ  = SUB
                3'b001: alu_op = 4'b0001; // BNE  = SUB
                3'b100: alu_op = 4'b1011; // BLT  = SLT
                3'b101: alu_op = 4'b1011; // BGE  = SLT
                3'b110: alu_op = 4'b1100; // BLTU = SLTU
                3'b111: alu_op = 4'b1100; // BGEU = SLTU
                default: alu_op = 4'b1010; // NOP
            endcase
        end
    end
endmodule