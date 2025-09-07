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

    // $display("\nMEM");
    // uut.u_dmem.dump_mem();

    // #5;
    // mret = 1;
    // #10;
    // mret = 0;
    // #100;
    $finish;
  end

  initial begin
    $dumpfile("cpu_top_tb.vcd");   // output waveform file
    $dumpvars(0, cpu_top_tb);      // dump everything under cpu_top_tb
  end

  initial begin
    // Wait until trap occurs
    wait (uut.exc_en == 1);

    // Put mret instruction in imem
    //uut.u_imem.imem[6] = 32'h30200073;

    // Give some clock cycles for trap handler to take effect
    // @(posedge clk);
    // #5
    // mret = 1;
    // @(posedge clk);
    // #5
    // mret = 0;
end

endmodule
