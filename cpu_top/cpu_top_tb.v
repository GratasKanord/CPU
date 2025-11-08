`timescale 1ns/1ps

module cpu_top_tb;

  reg clk;
  reg rst;

  cpu_top uut (
      .clk(clk),
      .rst(rst)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100 MHz clock
  end

  initial begin
    rst = 1;
    #20;
    rst = 0;
  end

  // always @(posedge clk) begin
  //   if (uut.u_regfile.we_regs) begin   // PC of sw x3, -60(x30)
  //       $display("x%0d <= %h @ PC=%h instr= %h", uut.u_regfile.w_regs_addr,
  //                                                uut.u_regfile.w_regs_data,
  //                                                uut.u_pc.pc_addr,
  //                                                uut.u_imem.instruction);                 
  //   end
  // end


  // always @(posedge clk) begin
  //   if (uut.u_pc.pc_addr == 64) begin   // PC of sw x3, -60(x30)
  //       $display(">>> Test result: x3 = %0d (decimal), 0x%h (hex)",
  //                uut.u_regfile.regs[3], uut.u_regfile.regs[3]);
                 
  //   end
  //   if (uut.u_pc.pc_addr == 72) begin  
  //     $finish;    
  //   end
  // end
  initial begin
    //#150; for simulating ASM programs
    #8500; // for compliance tests
    
    // $display("\nREGS");
    // uut.u_regfile.dump_regs();

    // $display("\nMEM");
    // uut.u_dmem.dump_mem();

    $finish;
  end

  initial begin
    $dumpfile("cpu_top_tb.vcd");   // output waveform file
    $dumpvars(0, cpu_top_tb);      // dump everything under cpu_top_tb
  end

  initial begin
    

    //uut.u_imem.imem[4] = 32'hF; // is used for exc_2 test

  end

endmodule
