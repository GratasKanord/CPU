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

  // Monitor TOHOST for test result
  always @(posedge clk) begin
      if (uut.u_dmem.we_dmem && uut.u_dmem.r_dmem_addr == 64'h00001000) begin
          $display("TOHOST write detected: %h", uut.u_dmem.w_dmem_data);
          if (uut.u_dmem.w_dmem_data == 64'd1) begin
              $display("TEST PASSED");
              $finish;
          end else begin
              $display("TEST FAILED: value = %h", uut.u_dmem.w_dmem_data);
              $finish;
          end
      end
  end

  initial begin
    //#150; for simulating ASM programs
    #50000; // for compliance tests
    
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
