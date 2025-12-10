module trap_handler (
    input  wire        clk,
    input  wire        rst,

    // Exception and interrupt inputs
    input  wire        exc_en,
    input  wire [3:0]  exc_code,
    input  wire [63:0] exc_val,
    input  wire        irq_en,
    input  wire [3:0]  irq_code,
    input  wire [63:0] irq_val,

    // Return from trap instruction
    input  wire        mret,

    // Current state
    input  wire [63:0] pc_addr,     // faulting PC
    input  wire [63:0] mtvec,       // trap vector base
    input  wire [1:0]  priv_lvl,    // current privilege
    input  wire [63:0] mstatus_current,  // current mstatus from CSR file

    // Outputs to PC / control
    output reg  [63:0] pc_trap_next,
    output reg         trap_taken,
    output reg         trap_done,
    output reg  [63:0] pc_ret,

    // Outputs to CSR file
    output reg [63:0]  mepc_next,
    output reg [63:0]  mcause_next,
    output reg [63:0]  mtval_next,
    output reg [63:0]  mstatus_next,
    output reg  [1:0]  priv_lvl_next
);

    // cause selection
    wire [3:0] cause_code = irq_en ? irq_code : exc_code;
    wire [63:0] cause_val = irq_en ? irq_val  : exc_val;
    wire        is_irq    = irq_en;

    // trap trigger for the system
    
    always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all outputs and internal state
        trap_done      <= 1'b0;
        trap_taken     <= 1'b0;
        pc_trap_next   <= 64'b0;
        mepc_next      <= 64'b0;
        mcause_next    <= 64'b0;
        mtval_next     <= 64'b0;
        mstatus_next   <= 64'b0;
        priv_lvl_next  <= 2'b11;  // default M-mode
    end
    else begin
        trap_done      <= 1'b0;
        trap_taken     <= 1'b0;
        pc_trap_next   <= pc_trap_next;  // hold value by default
        mcause_next    <= mcause_next;    
        mepc_next      <= mepc_next;        
        mtval_next     <= mtval_next;     
        mstatus_next   <= mstatus_next;   
        priv_lvl_next  <= priv_lvl_next;  

        if (exc_en || irq_en) begin
            if (trap_taken) begin
                trap_taken <= 1'b0;
            end else trap_taken <= 1'b1;
            // Trap entry
            mepc_next      <= pc_addr;
            mcause_next    <= {irq_en, 59'b0, cause_code};
            mtval_next     <= cause_val;

            // Update mstatus
            mstatus_next         <= mstatus_current;
            mstatus_next[7]      <= mstatus_current[3];   // MPIE <- MIE
            mstatus_next[3]      <= 1'b0;                 // MIE <- 0
            mstatus_next[12:11]  <= priv_lvl;            // MPP <- current priv
            pc_trap_next     <= mtvec;
            //pc_trap_next   <= 64'd24;  // simulation: jump to trap handler (used for 0 amd 1 exc test)
            //pc_trap_next   <= 64'd32;  // simulation: jump to trap handler (used for 2, 3 exc test)
            //pc_trap_next   <= 64'd28;  // simulation: jump to trap handler (used for 4, 5, 6, 7 exc test)
            priv_lvl_next  <= 2'b11;   // enter M-mode
        end
        else if (mret) begin
            // --- Trap exit ---
            trap_done <= 1'b1;
            priv_lvl_next  <= mstatus_current[12:11];       // restore priv_lvl

            // Update mstatus on mret
            mstatus_next         <= mstatus_current;
            mstatus_next[3]      <= mstatus_current[7];   // MIE <- MPIE
            mstatus_next[7]      <= 1'b1;                 // MPIE <- 1
            mstatus_next[12:11]  <= 2'b0;        // clear MPP
        end
    end
end


endmodule
