`timescale 1ns/1ps

module cpu_top_tb;

  reg clk;
  reg reset;

  // instantiate your CPU
  cpu_top uut (
      .clk(clk),
      .rst(reset)
      // add other ports if you have them
  );

  // clock generator
  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // 100 MHz clock
  end

  // reset sequence
  initial begin
    reset = 1;
    #20;
    reset = 0;
  end

  // stop after some time
  initial begin
    #500;  // run 500ns then stop
    
    uut.u_regfile.dump_regs();

    $finish;
  end

endmodule
