module latch(input Sbar, Rbar, output Q, Qbar);
  nand LS(Q, Sbar, Qbar);
  nand LR(Qbar, Rbar, Q);
endmodule

module enLatch(input en, S, R, output Q, Qbar);
  nand ES(Senbar, en, S);
  nand ER(Renbar, en, R);
  latch L1(Senbar, Renbar, Q, Qbar);
endmodule

module ptd(input clk, output ppulse);
  not  #2 P1(nclkd, clk);
  nand #2 P2(npulse, nclkd, clk);
  not  #2 P3(ppulse, npulse);
endmodule

module ptdLatch(input clk, S, R, output Q, Qbar);
  ptd PTD(clk, ppulse);
  enLatch EL(ppulse, S, R, Q, Qbar);
endmodule

module main;
reg clk, S;
wire R, Q, Qbar;

ptdLatch PL(clk, S, R, Q, Qbar);
not N1(R, S);

initial
begin
  clk = 0;
  S = 0;
  $monitor("%4dns monitor: clk=%d S=%d R=%d Q=%d Qbar=%d", $stime, clk, S, R, Q, Qbar);
  $dumpfile("ptdLatch.vcd"); // 輸出給 GTK wave 顯示波型
  $dumpvars;  
end

always #20 begin
  clk = clk + 1;
end

always #50 begin
  S = S + 1;
end

initial #500 $finish;

endmodule
