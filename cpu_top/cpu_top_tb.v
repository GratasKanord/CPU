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

  initial begin
    #150; 
    
    $display("\nREGS");
    uut.u_regfile.dump_regs();

    $display("\nMEM");
    uut.u_dmem.dump_mem();

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
