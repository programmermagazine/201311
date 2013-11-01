module ptd(input clk, output ppulse);
  not #2 P1(nclkd, clk);
  nand #2 P2(npulse, nclkd, clk);
  not #2 P3(ppulse, npulse);
endmodule

module main;
 reg clk;
 wire p;

 ptd ptd1(clk, p);

 initial begin
   clk = 0;
   $monitor("%dns monitor: clk=%b p=%d", $stime, clk, p);
   $dumpfile("ptd.vcd"); // ��X�� GTK wave ��ܪi��
   $dumpvars;
 end

 always #50 begin
   clk = clk + 1;
 end

initial #500 $finish;

endmodule
