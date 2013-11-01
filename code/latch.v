module latch(input Sbar, Rbar, output Q, Qbar);
  nand LS(Q, Sbar, Qbar);
  nand LR(Qbar, Rbar, Q);
endmodule

module main;
reg Sbar;
wire Q, Qbar, Rbar;

latch latch1(Sbar, Rbar, Q, Qbar);
not N1(Rbar, Sbar);

initial
begin
  Sbar = 0;
  $monitor("%4dns monitor: Sbar=%d Rbar=%d Q=%d Qbar=%d", $stime, Sbar, Rbar, Q, Qbar);
  $dumpfile("latch.vcd"); // 輸出給 GTK wave 顯示波型
  $dumpvars;    
end

always #50 begin
  Sbar = Sbar+1;
end

initial #500 $finish;

endmodule
