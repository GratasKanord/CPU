module decoder (input [31:0] instr,
                input [63:0] regs_data1,
                regs_data2,                     // registers' values
                input [63:0] csr_data,
                input [63:0] pc_addr,
                input [1:0]  priv_lvl,
                input        trap_taken,
                input        trap_done,
                output reg [3:0] alu_op,
                output reg [4:0] r_regs_addr1,  // 1st register's address
                output reg [4:0] r_regs_addr2,  // 2nd register's address
                output reg [4:0] w_regs_addr,   // destination register (address)
                output reg we_regs,             // write enable signal for registers
                output reg we_dmem,             // write enable signal for memory
                output reg [7:0] dmem_word_sel, // byte enable signal for store/load instructions
                output [63:0] input_alu_B,
                output reg is_JALR,
                output reg is_LOAD,
                output reg is_CSR,
                output reg is_32bit,
                output reg is_auipc,
                output reg [63:0] imm,
                output reg pc_branch_taken,
                output [63:0] pc_branch_target,
                output reg [11:0] r_csr_addr,
                output reg we_csr,
                output reg [63:0] w_csr_data,
                output reg exc_en,
                output reg [3:0] exc_code,
                output reg [63:0] exc_val,
                output reg mret);
    reg [2:0] func3;
    reg [6:0] func7;
    reg alu_B_src;
    reg [11:0] sys_instr;
    
    assign pc_branch_target = (is_JALR) ? ((regs_data1 + imm) & ~1) : pc_addr + imm;
    
    assign input_alu_B = (alu_B_src) ? imm : regs_data2;
    
    always @(*) begin
        func3           = 0;
        func7           = 0;
        r_regs_addr1    = 0;
        r_regs_addr2    = 0;
        w_regs_addr     = 0;
        imm             = 0;
        we_regs         = 0;
        we_dmem         = 0;
        alu_B_src       = 0;
        pc_branch_taken = 0;
        is_JALR         = 0;
        is_LOAD         = 0;
        is_CSR          = 0;
        is_32bit        = 0;
        is_auipc        = 0;
        we_csr          = 0;
        exc_en     = 0;
        exc_code   = 0;  
        exc_val    = 0;
        
        if (!trap_taken && !trap_done) begin    // don't decode instruction during entering/exiting trap
            //Decoding instruction & exctracting it's parts
            case (instr[6:0])
                7'b0110011 : begin          //R-type
                    func3        = instr[14:12];
                    func7        = instr[31:25];
                    r_regs_addr1 = instr[19:15];
                    r_regs_addr2 = instr[24:20];
                    w_regs_addr  = instr[11:7];
                    we_regs      = 1;
                end
                7'b0010011 : begin          //I-type immediate
                    func3        = instr[14:12];
                    func7        = instr[31:25];
                    r_regs_addr1 = instr[19:15];
                    w_regs_addr  = instr[11:7];
                    imm          = {{52{instr[31]}}, instr[31:20]};
                    we_regs      = 1;
                    alu_B_src    = 1;
                end
                7'b0011011 : begin          //I-type immediate 32-bit
                    func3        = instr[14:12];
                    func7        = instr[31:25];
                    r_regs_addr1 = instr[19:15];
                    w_regs_addr  = instr[11:7];
                    imm          = {{52{instr[31]}}, instr[31:20]};
                    we_regs      = 1;
                    alu_B_src    = 1;
                    is_32bit     = 1;
                end
                7'b0000011 : begin          //I-type load
                    func3        = instr[14:12];
                    r_regs_addr1 = instr[19:15];
                    w_regs_addr  = instr[11:7];
                    imm          = {{52{instr[31]}}, instr[31:20]};
                    we_regs      = 1;
                    we_dmem      = 0;
                    alu_B_src    = 1;
                    is_LOAD      = 1;
                end
                7'b1100111 : begin          //I-type jump
                    func3           = instr[14:12];
                    r_regs_addr1    = instr[19:15];
                    w_regs_addr     = instr[11:7];
                    imm             = {{52{instr[31]}}, instr[31:20]};
                    we_regs         = 1;
                    alu_B_src       = 1;
                    pc_branch_taken = 1;
                    is_JALR         = 1;
                end
                7'b0100011 : begin          //S-type store
                    func3        = instr[14:12];
                    r_regs_addr1 = instr[19:15];
                    r_regs_addr2 = instr[24:20];
                    imm          = {{52{instr[31]}}, instr[31:25], instr[11:7]};
                    we_regs      = 0;
                    we_dmem      = 1;
                    alu_B_src    = 1;
                end
                7'b1100011 : begin          //B-type
                    func3        = instr[14:12];
                    r_regs_addr1 = instr[19:15];
                    r_regs_addr2 = instr[24:20];
                    imm          = {{51{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
                    we_regs      = 0;
                    alu_B_src    = 1;
                end
                7'b0110111 : begin          //U-type LUI
                    w_regs_addr = instr[11:7];
                    imm         = {{32{instr[31]}}, instr[31:12], 12'b0};
                    we_regs     = 1;
                    alu_B_src   = 1;
                end
                7'b0010111 : begin          //U-type AUIPC
                    w_regs_addr = instr[11:7];
                    imm         = {{32{instr[31]}}, instr[31:12], 12'b0};
                    we_regs     = 1;
                    is_auipc    = 1;
                    alu_B_src   = 1;
                end
                7'b1101111 : begin          //J-type JAL
                    w_regs_addr     = instr[11:7];
                    imm             = {{43{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                    we_regs         = 1;
                    alu_B_src       = 1;
                    pc_branch_taken = 1;
                end
                7'b1110011 : begin          // System/SCR
                    sys_instr = instr[31:20];
                    if (sys_instr != 12'b0 &&
                        sys_instr != 12'b1 &&
                        sys_instr != 12'b001100000010) begin
                        r_csr_addr = instr[31:20];
                    end                 
                    w_regs_addr  = instr[11:7];
                    r_regs_addr1 = instr[19:15];
                    func3        = instr[14:12];
                    imm          = {59'b0, instr[19:15]}; // for immediate versions (zimm)
                    is_CSR       = 1;
                    we_dmem      = 0;
                    we_regs      = (w_regs_addr != 0);
                end
                7'b0001111: begin          // FENCE instruction
                    // Treat as NOP
                    we_regs = 0;
                    we_dmem = 0;
                    we_csr = 0;
                    exc_en = 0;
                    alu_op = 4'b1010; // NOP
                    pc_branch_taken = 0;
                    is_JALR = 0;
                    is_LOAD = 0;
                    is_CSR = 0;
                    is_32bit = 0;
                    mret = 0;
                end
                default: begin
                    exc_en   = 1'b1;
                    exc_code = 4'd2;       // Illegal instruction
                    exc_val  = instr;
                    func3        = 0;
                    func7        = 0;
                    r_regs_addr1 = 0;
                    r_regs_addr2 = 0;
                    w_regs_addr  = 0;
                    imm          = 0;
                    we_regs      = 0;
                    we_dmem      = 0;
                    alu_B_src    = 0;
                    is_JALR      = 0;
                    is_LOAD      = 0;
                    is_CSR       = 0;
                    is_32bit     = 0;
                    is_auipc     = 0;
                    we_csr       = 0;
                end
            endcase
        end
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
                default: alu_op        = 4'b1010;        // NOP
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

    // Decoding ALU opcode for I-type instructions 32 bit
    always @(*) begin
        if (instr[6:0] == 7'b0011011) begin
            case (func3)
                3'b000: alu_op = 4'b0000; // ADDIW
                3'b001: alu_op = 4'b1101; // SLLIW
                3'b101: begin              // SRLIW / SRAIW
                    if (func7 == 7'b0000000)
                        alu_op = 4'b1110; // SRLIW
                    else if (func7 == 7'b0100000)
                        alu_op = 4'b1111; // SRAIW
                    else
                        alu_op = 4'b1010; // NOP/default
                end
                default: alu_op = 4'b1010; // NOP/default
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
    
    //Decoding B-type instructions
    always @(*) begin
        if (instr[6:0] == 7'b1100011) begin
            case (func3)
                3'b000: pc_branch_taken  = (regs_data1 == regs_data2); // BEQ
                3'b001: pc_branch_taken  = (regs_data1 != regs_data2); // BNE
                3'b100: pc_branch_taken  = ($signed(regs_data1) < $signed(regs_data2)); // BLT
                3'b101: pc_branch_taken  = ($signed(regs_data1) >= $signed(regs_data2)); // BGE
                3'b110: pc_branch_taken  = (regs_data1 < regs_data2); // BLTU
                3'b111: pc_branch_taken  = (regs_data1 >= regs_data2); // BGEU
                default: pc_branch_taken = 0;
            endcase
        end
    end
    
    //Decoding I-type load and S-type
    always @(*) begin
        dmem_word_sel = 8'b0000_0000;  // default: no bytes enabled
        if (instr[6:0] == 7'b0100011) begin
            alu_op = 4'b0000;
            case (func3)
                3'b000: dmem_word_sel  = 8'b0000_0001; // SB
                3'b001: dmem_word_sel  = 8'b0000_0011; // SH
                3'b010: dmem_word_sel  = 8'b0000_1111; // SW
                3'b011: dmem_word_sel  = 8'b1111_1111; // SD
                default: dmem_word_sel = 8'b0000_0000;
            endcase
        end else if (instr[6:0] == 7'b0000011) begin
            alu_op = 4'b0000;
            case (func3)
                3'b000: dmem_word_sel = 8'b0000_0001; // LB
                3'b001: dmem_word_sel = 8'b0000_0011; // LH
                3'b010: dmem_word_sel = 8'b0000_1111; // LW
                3'b011: dmem_word_sel = 8'b1111_1111; // LD
                default: dmem_word_sel = 8'b0000_0000;
            endcase
        end
    end
    
    // Decoding System/CSR instruction
    always @(*) begin
        we_csr     = 0;
        w_csr_data = 64'b0;
        mret = 0;
        if (instr[6:0] == 7'b1110011) begin
            case (func3)
                3'b0: begin  // Exceptions and system instructions
                    if (sys_instr == 12'b0) begin // ECALL
                        exc_en   = 1'b1;
                        exc_code = (priv_lvl == 2'b11) ? 4'd11 : 
                                   (priv_lvl == 2'b01) ? 4'd9  : 4'd8; 
                        exc_val  = 64'b0;
                    end else if (sys_instr == 12'b1) begin // EBREAK
                        exc_en   = 1'b1;
                        exc_code = 4'd3;
                        exc_val  = 64'b0;
                    end else if (sys_instr == 12'b001100000010) begin // MRET
                        mret = 1'b1;
                    end
                end
                3'b001: begin  // CSRRW
                    we_csr     = 1;
                    w_csr_data = regs_data1;            // write full value
                end
                3'b010: begin  // CSRRS
                    we_csr     = (r_regs_addr1 != 0);
                    w_csr_data = csr_data | regs_data1; // OR old value with regs_data1
                end
                3'b011: begin  // CSRRC
                    we_csr     = (r_regs_addr1 != 0);
                    w_csr_data = csr_data & ~regs_data1; // AND NOT old value with regs_data1
                end
                3'b101: begin  // CSRRWI
                    we_csr     = 1;
                    w_csr_data = imm;             // zimm
                end
                3'b110: begin  // CSRRSI
                    we_csr     = (r_regs_addr1 != 0);
                    w_csr_data = csr_data | imm; // OR old value with zimm
                end
                3'b111: begin  // CSRRCI
                    we_csr     = (r_regs_addr1 != 0);
                    w_csr_data = csr_data & ~imm; // AND NOT old value with zimm
                end
                default: begin
                    we_csr     = 0;
                    w_csr_data = 64'b0;
                    exc_en     = 0;
                    exc_code   = 0;  
                    exc_val    = 0;
                    mret = 0;
                end
            endcase
        end
    end 
endmodule
