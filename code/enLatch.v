module latch(input Sbar, Rbar, output Q, Qbar);
  nand LS(Q, Sbar, Qbar);
  nand LR(Qbar, Rbar, Q);
endmodule

module enLatch(input en, S, R, output Q, Qbar);
  nand ES(Senbar, en, S);
  nand ER(Renbar, en, R);
  latch L1(Senbar, Renbar, Q, Qbar);
endmodule

module main;
reg S, en;
wire Q, Qbar, R;

enLatch enLatch1(en, S, R, Q, Qbar);
not N1(R, S);

initial
begin
  S  = 0;
  en = 0;
  $monitor("%4dns monitor: Sbar=%d Rbar=%d Q=%d Qbar=%d", $stime, S, R, Q, Qbar);
  $dumpfile("enLatch.vcd"); // 輸出給 GTK wave 顯示波型
  $dumpvars;    
end

always #50 begin
  S = S+1;
  #5 en=1;
  #5 en=0;
end

initial #500 $finish;

endmodule
