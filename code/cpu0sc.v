`define PC   R[15]   // 程式計數器
`define LR   R[14]   // 連結暫存器
`define SP   R[13]   // 堆疊暫存器
`define SW   R[12]   // 狀態暫存器
// 狀態暫存器旗標位元
`define N    `SW[31] // 負號旗標
`define Z    `SW[30] // 零旗標
`define C    `SW[29] // 進位旗標
`define V    `SW[28] // 溢位旗標
`define I    `SW[7]  // 硬體中斷許可
`define T    `SW[6]  // 軟體中斷許可
`define M    `SW[0]  // 模式位元

module cpu0c(input clock); // CPU0-Mini 的快取版：cpu0mc 模組
  parameter [7:0] LD=8'h00,ST=8'h01,LDB=8'h02,STB=8'h03,LDR=8'h04,STR=8'h05,
    LBR=8'h06,SBR=8'h07,ADDI=8'h08,CMP=8'h10,MOV=8'h12,ADD=8'h13,SUB=8'h14,
    MUL=8'h15,DIV=8'h16,AND=8'h18,OR=8'h19,XOR=8'h1A,ROL=8'h1C,ROR=8'h1D,
    SHL=8'h1E,SHR=8'h1F,JEQ=8'h20,JNE=8'h21,JLT=8'h22,JGT=8'h23,JLE=8'h24,
    JGE=8'h25,JMP=8'h26,SWI=8'h2A,CALL=8'h2B,RET=8'h2C,IRET=8'h2D,
    PUSH=8'h30,POP=8'h31,PUSHB=8'h32,POPB=8'h33;
  reg signed [31:0] R [0:15];   // 宣告暫存器 R[0..15] 等 16 個 32 位元暫存器
  reg signed [31:0] IR;         // 指令暫存器 IR
  reg [7:0] m [0:256];          // 內部的快取記憶體
  reg [7:0] op;                 // 變數：運算代碼 op
  reg [3:0] ra, rb, rc;         // 變數：暫存器代號 ra, rb, rc
  reg [4:0] c5;                 // 變數：5 位元常數 c5
  reg signed [11:0] c12;        // 變數：12 位元常數 c12
  reg signed [15:0] c16;        // 變數：16 位元常數 c16
  reg signed [23:0] c24;        // 變數：24 位元常數 c24
  reg signed [31:0] sp, jaddr, laddr, raddr;
  reg signed [31:0] temp;
  reg signed [31:0] pc;

  integer i;  
  initial  // 初始化
  begin
    `PC = 0;                    // 將 PC 設為起動位址 0
    `SW = 0;
    R[0] = 0;                   // 將 R[0] 暫存器強制設定為 0
    $readmemh("cpu0s.hex", m);
    for (i=0; i < 255; i=i+4) begin
       $display("%8x: %8x", i, {m[i], m[i+1], m[i+2], m[i+3]});
    end
  end
  
  always @(posedge clock) begin // 在 clock 時脈的正邊緣時觸發
      pc = `PC;
      IR = {m[`PC], m[`PC+1], m[`PC+2], m[`PC+3]};  // 指令擷取階段：IR=m[PC], 4 個 Byte 的記憶體
      `PC = `PC+4;                                  // 擷取完成，PC 前進到下一個指令位址
      {op,ra,rb,rc,c12} = IR;                      // 解碼階段：將 IR 解為 {op, ra, rb, rc, c12}
      c5  = IR[4:0];
      c24 = IR[23:0];
      c16 = IR[15:0];
      jaddr = `PC+c16;
      laddr = R[rb]+c16;
      raddr = R[rb]+R[rc];
      case (op) // 根據 OP 執行對應的動作
        LD: begin   // 載入指令： R[ra] = m[addr]
          R[ra] = {m[laddr], m[laddr+1], m[laddr+2], m[laddr+3]};
          $display("%4dns %8x : LD    R%-d R%-d 0x%x ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, c16, ra, R[ra], R[ra]);
          end
        ST: begin   // 儲存指令： m[addr] = R[ra]
          {m[laddr], m[laddr+1], m[laddr+2], m[laddr+3]} = R[ra];
          $display("%4dns %8x : ST    R%-d R%-d 0x%x ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, c16, ra, R[ra], R[ra]);
          end
        LDB:begin   // 載入byte;     LDB Ra, [Rb+ Cx];   Ra<=(byte)[Rb+ Cx]
          R[ra] = { 24'b0, m[laddr] };
          $display("%4dns %8x : LDB   R%-d R%-d 0x%x ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, c16, ra, R[ra], R[ra]);
          end
        STB:begin   // 儲存byte;     STB Ra, [Rb+ Cx];   Ra=>(byte)[Rb+ Cx]
          m[laddr] = R[ra][7:0];
          $display("%4dns %8x : STB   R%-d R%-d 0x%x ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, c16, ra, R[ra], R[ra]);
          end
        LDR:begin   // LD 的 Rc 版;  LDR Ra, [Rb+Rc];    Ra<=[Rb+ Rc]
          R[ra] = {m[raddr], m[raddr+1], m[raddr+2], m[raddr+3]};
          $display("%4dns %8x : LDR   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        STR:begin   // ST 的 Rc 版;  STR Ra, [Rb+Rc];    Ra=>[Rb+ Rc]
          {m[raddr], m[raddr+1], m[raddr+2], m[raddr+3]} = R[ra];
          $display("%4dns %8x : STR   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        LBR:begin   // LDB 的 Rc 版; LBR Ra, [Rb+Rc];    Ra<=(byte)[Rb+ Rc]
          R[ra] = { 24'b0, m[raddr] };
          $display("%4dns %8x : LBR   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        SBR:begin   // STB 的 Rc 版; SBR Ra, [Rb+Rc];    Ra=>(byte)[Rb+ Rc]
          m[raddr] = R[ra][7:0];
          $display("%4dns %8x : SBR   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        MOV:begin   // 移動;        MOV Ra, Rb;         Ra<=Rb
          R[ra] = R[rb];
          $display("%4dns %8x : MOV   R%-d R%-d        ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, ra, R[ra], R[ra]);
          end
        CMP:begin   // 比較;        CMP Ra, Rb;         SW=(Ra >=< Rb)
          temp = R[ra]-R[rb];
          `N=(temp<0);`Z=(temp==0);
          $display("%4dns %8x : CMP   R%-d R%-d        ; SW=0x%x", $stime, pc, ra, rb, `SW);
          end
        ADDI:begin  // R[a] = Rb+c16;  // 立即值加法;   LDI Ra, Rb+Cx; Ra<=Rb + Cx
          R[ra] = R[rb]+c16;
          $display("%4dns %8x : ADDI  R%-d R%-d %-d ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, c16, ra, R[ra], R[ra]);
          end
        ADD: begin  // 加法指令： R[ra] = R[rb]+R[rc]
          R[ra] = R[rb]+R[rc];
          $display("%4dns %8x : ADD   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        SUB:begin   // 減法;        SUB Ra, Rb, Rc;     Ra<=Rb-Rc
          R[ra] = R[rb]-R[rc];
          $display("%4dns %8x : SUB   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        MUL:begin   // 乘法;        MUL Ra, Rb, Rc;     Ra<=Rb*Rc
          R[ra] = R[rb]*R[rc];
          $display("%4dns %8x : MUL   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        DIV:begin   // 除法;        DIV Ra, Rb, Rc;     Ra<=Rb/Rc
          R[ra] = R[rb]/R[rc];
          $display("%4dns %8x : DIV   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        AND:begin   // 位元 AND;    AND Ra, Rb, Rc;     Ra<=Rb and Rc
          R[ra] = R[rb]&R[rc];
          $display("%4dns %8x : AND   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        OR:begin    // 位元 OR;     OR Ra, Rb, Rc;         Ra<=Rb or Rc
          R[ra] = R[rb]|R[rc];
          $display("%4dns %8x : OR    R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        XOR:begin   // 位元 XOR;    XOR Ra, Rb, Rc;     Ra<=Rb xor Rc
          R[ra] = R[rb]^R[rc];
          $display("%4dns %8x : XOR   R%-d R%-d R%-d    ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, rc, ra, R[ra], R[ra]);
          end
        SHL:begin   // 向左移位;    SHL Ra, Rb, Cx;     Ra<=Rb << Cx
          R[ra] = R[rb]<<c5;
          $display("%4dns %8x : SHL   R%-d R%-d %-d     ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, c5, ra, R[ra], R[ra]);
          end
        SHR:begin   // 向右移位;        SHR Ra, Rb, Cx;     Ra<=Rb >> Cx
          R[ra] = R[rb]>>c5;
          $display("%4dns %8x : SHR   R%-d R%-d %-d     ; R%-2d=0x%8x=%-d", $stime, pc, ra, rb, c5, ra, R[ra], R[ra]);
          end          
        JMP:begin   // 跳躍指令： PC = PC + cx24
          `PC = `PC + c24;
          $display("%4dns %8x : JMP   0x%x       ; PC=0x%x", $stime, pc, c24, `PC);
          end
        JEQ:begin   // 跳躍 (相等);        JEQ Cx;        if SW(=) PC  PC+Cx
          if (`Z) `PC=`PC+c24;
          $display("%4dns %8x : JEQ   0x%08x     ; PC=0x%x", $stime, pc, c24, `PC);
          end
        JNE:begin   // 跳躍 (不相等);    JNE Cx;     if SW(!=) PC  PC+Cx
          if (!`Z) `PC=`PC+c24;
          $display("%4dns %8x : JNE   0x%08x     ; PC=0x%x", $stime, pc, c24, `PC);
          end
        JLT:begin   // 跳躍 ( < );        JLT Cx;     if SW(<) PC  PC+Cx
          if (`N) `PC=`PC+c24;
          $display("%4dns %8x : JLT   0x%08x     ; PC=0x%x", $stime, pc, c24, `PC);
          end
        JGT:begin   // 跳躍 ( > );        JGT Cx;     if SW(>) PC  PC+Cx
          if (!`N&&!`Z) `PC=`PC+c24;
          $display("%4dns %8x : JGT   0x%08x     ; PC=0x%x", $stime, pc, c24, `PC);
          end
        JLE:begin   // 跳躍 ( <= );        JLE Cx;     if SW(<=) PC  PC+Cx  
          if (`N || `Z) `PC=`PC+c24;
          $display("%4dns %8x : JLE   0x%08x     ; PC=0x%x", $stime, pc, c24, `PC);
          end
        JGE:begin   // 跳躍 ( >= );        JGE Cx;     if SW(>=) PC  PC+Cx
          if (!`N || `Z) `PC=`PC+c24;
          $display("%4dns %8x : JGE   0x%08x     ; PC=0x%x", $stime, pc, c24, `PC);
          end
        SWI:begin   // 軟中斷;    SWI Cx;         LR <= PC; PC <= Cx; INT<=1
          `LR=`PC;`PC= c24; `I = 1'b1;
          $display("%4dns %8x : SWI   0x%08x     ; PC=0x%x", $stime, pc, c24, `PC);
          end
        CALL:begin  // 跳到副程式;    CALL Cx;     LR<=PC; PC<=PC+Cx
          `LR=`PC;`PC=`PC + c24;
          $display("%4dns %8x : CALL  0x%08x     ; PC=0x%x", $stime, pc, c24, `PC);
          end
        RET:begin   // 返回;            RET;         PC <= LR
          `PC=`LR;
          $display("%4dns %8x : RET                  ; PC=0x%x", $stime, pc, `PC);
          if (`PC<0) $finish;
          end
        IRET:begin  // 中斷返回;        IRET;         PC <= LR; INT<=0
          `PC=`LR;`I = 1'b0;
          $display("%4dns %8x : IRET             ; PC=0x%x", $stime, pc, `PC);
          end
        PUSH:begin  // 推入 word;    PUSH Ra;    SP-=4;[SP]<=Ra;
          sp = `SP-4; `SP = sp; {m[sp], m[sp+1], m[sp+2], m[sp+3]} = R[ra];
          $display("%4dns %8x : PUSH  R%-d            ; R%-2d=0x%8x, SP=0x%x", $stime, pc, ra, ra, R[ra], `SP);
          end
        POP:begin   // 彈出 word;    POP Ra;     Ra=[SP];SP+=4;
          sp = `SP; R[ra]={m[sp], m[sp+1], m[sp+2], m[sp+3]}; `SP = sp+4; 
          $display("%4dns %8x : POP   R%-d            ; R%-2d=0x%8x, SP=0x%x", $stime, pc, ra, ra, R[ra], `SP);
          end
        PUSHB:begin // 推入 byte;    PUSHB Ra;   SP--;[SP]<=Ra;(byte)
          sp = `SP-1; `SP = sp; m[sp] = R[ra];
          $display("%4dns %8x : PUSHB R%-d            ; R[%-d]=0x%8x, SP=0x%x", $stime, pc, ra, ra, R[ra], `SP);
          end
        POPB:begin  // 彈出 byte;    POPB Ra;  Ra<=[SP];SP++;(byte)
          sp = `SP+1; `SP = sp; R[ra]=m[sp];
          $display("%4dns %8x : POPB  R%-d            ; R[%-d]=0x%8x, SP=0x%x", $stime, pc, ra, ra, R[ra], `SP);
          end
      endcase
  end
endmodule

module main;                // 測試程式開始
reg clock;                  // 時脈 clock 變數

cpu0c cpu(clock);           // 宣告 cpu0mc 處理器

initial clock = 0;          // 一開始 clock 設定為 0
always #10 clock=~clock;    // 每隔 10 奈秒將 clock 反相，產生週期為 20 奈秒的時脈
initial #2000 $finish;      // 在 640 奈秒的時候停止測試。(因為這時的 R[1] 恰好是 1+2+...+10=55 的結果)
endmodule
