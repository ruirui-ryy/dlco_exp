`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/04 14:29:25
// Design Name: 
// Module Name: rv32is
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module rv32is #(
  parameter PMEM_LEFT    = 32'h00000000,
  parameter RESET_VECTOR = 32'h00000000
)(
  input         clock,
  input         reset,
  output [31:0] imemaddr,
  input  [31:0] imemdataout,
  output        imemclk,
  output [31:0] dmemaddr,
  input  [31:0] dmemdataout,
  output [31:0] dmemdatain,
  output        dmemrdclk,
  output        dmemwrclk,
  output [2:0]  dmemop,
  output        dmemwe,
  output [31:0] dbgdata
);

  // ------------------------------------------------------------------
  // PC 与时序
  // ------------------------------------------------------------------
  reg [31:0] PC;
  wire [31:0] NextPC_comb;
  wire [31:0] NxtPC_wire;

  always @(negedge clock) begin
    if (reset)
      PC <= RESET_VECTOR;
    else
      PC <= NxtPC_wire;
  end

  assign dbgdata = PC;
  assign imemclk = ~clock;
  assign imemaddr = NxtPC_wire;
  assign NxtPC_wire = reset ? RESET_VECTOR : NextPC_comb;

  // ------------------------------------------------------------------
  // 指令解析
  // ------------------------------------------------------------------
  wire [31:0] instr = imemdataout;
  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [4:0] rd;
  wire [4:0] rs1;
  wire [4:0] rs2;

  instr_parse u_instr_parse(
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7),
    .instr(instr)
  );

  // ------------------------------------------------------------------
  // 控制单元
  // ------------------------------------------------------------------
  wire [2:0] ExtOp;
  wire       RegWr;
  wire       ALUASrc;
  wire [1:0] ALUBSrc;
  wire [3:0] ALUctr;
  wire [2:0] Branch;
  wire       MemtoReg;
  wire       MemWr;
  wire [2:0] MemOp;

  ctrl u_ctrl(
    .ExtOp(ExtOp),
    .RegWr(RegWr),
    .ALUASrc(ALUASrc),
    .ALUBSrc(ALUBSrc),
    .ALUctr(ALUctr),
    .Branch(Branch),
    .MemtoReg(MemtoReg),
    .MemWr(MemWr),
    .MemOp(MemOp),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .reset(reset)
  );

  // ------------------------------------------------------------------
  // 立即数生成
  // ------------------------------------------------------------------
  wire [31:0] Imm;
  instr_to_imm u_instr_to_imm(
    .instr(instr),
    .ExtOp(ExtOp),
    .imm(Imm)
  );

  // ------------------------------------------------------------------
  // 寄存器堆（myregfile）
  // ------------------------------------------------------------------
  wire [31:0] BusA;
  wire [31:0] BusB;
  wire [31:0] BusW;

  registerfile myregfile(
    .busa(BusA),
    .busb(BusB),
    .clock(clock),
    .ra(rs1),
    .rb(rs2),
    .rw(rd),
    .busw(BusW),
    .we(RegWr)
  );

  // ------------------------------------------------------------------
  // ALU 输入选择
  // ------------------------------------------------------------------
  wire [31:0] ALUAData = ALUASrc ? PC : BusA;
  wire [31:0] ALUBData =
    (ALUBSrc == 2'b00) ? BusB :
    (ALUBSrc == 2'b01) ? Imm  :
    (ALUBSrc == 2'b10) ? 32'd4 :
                         32'd0;

  wire [31:0] ALUResult;
  wire         ALUZero;

  ALU32 u_alu(
    .result(ALUResult),
    .zero(ALUZero),
    .dataa(ALUAData),
    .datab(ALUBData),
    .aluctr(ALUctr)
  );

  // ------------------------------------------------------------------
  // Branch 控制 & Next PC 组合逻辑
  // ------------------------------------------------------------------
  wire NxtASrc, NxtBSrc;
  branch_ctrl u_branch_ctrl(
    .NxtASrc(NxtASrc),
    .NxtBSrc(NxtBSrc),
    .zero(ALUZero),
    .result0(ALUResult[0]),
    .Branch(Branch)
  );

  next_PC u_next_pc(
    .nxtPC(NextPC_comb),
    .BusA(BusA),
    .curPC(PC),
    .Imm(Imm),
    .NxtASrc(NxtASrc),
    .NxtBSrc(NxtBSrc)
  );

  // ------------------------------------------------------------------
  // 数据存储器接口 - 简化：直接传递数据
  // ------------------------------------------------------------------
  assign dmemaddr  = ALUResult;
  assign dmemrdclk = clock;
  assign dmemwrclk = ~clock;
  assign dmemop    = MemOp;
  assign dmemwe    = MemWr;

  // 关键修复：对于store指令，直接传递BusB（rs2的值）给dmemdatain
  // 外部存储器会处理字节对齐和合并
  assign dmemdatain = BusB;

  // ------------------------------------------------------------------
  // 写回逻辑
  // ------------------------------------------------------------------
  wire is_lui  = (opcode == 7'b0110111);
  wire is_jal  = (Branch == 3'b001);
  wire is_jalr = (Branch == 3'b010);
  wire [31:0] link_addr = PC + 4;

  assign BusW =
    is_lui ? Imm :
    (is_jal || is_jalr) ? link_addr :
    (MemtoReg ? dmemdataout : ALUResult);

endmodule

// -----------------------------------------------------------------------------
// registerfile: myregfile (内部 regs)
// -----------------------------------------------------------------------------
module registerfile (
  output [31:0] busa,
  output [31:0] busb,
  input          clock,
  input  [4:0]   ra,
  input  [4:0]   rb,
  input  [4:0]   rw,
  input  [31:0]  busw,
  input          we
);
  reg [31:0] regs[0:31];

  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1)
      regs[i] = 32'b0;
  end

  always @(negedge clock) begin
    if (we && (rw != 5'b00000))
      regs[rw] <= busw;
  end

  assign busa = (ra == 5'b00000) ? 32'b0 : regs[ra];
  assign busb = (rb == 5'b00000) ? 32'b0 : regs[rb];
endmodule

// -----------------------------------------------------------------------------
// instr_parse
// -----------------------------------------------------------------------------
module instr_parse (
  output [6:0] opcode,
  output [4:0] rd,
  output [2:0] funct3,
  output [4:0] rs1,
  output [4:0] rs2,
  output [6:0] funct7,
  input  [31:0] instr
);
  assign opcode = instr[6:0];
  assign rd     = instr[11:7];
  assign funct3 = instr[14:12];
  assign rs1    = instr[19:15];
  assign rs2    = instr[24:20];
  assign funct7 = instr[31:25];
endmodule

// -----------------------------------------------------------------------------
// instr_to_imm
// -----------------------------------------------------------------------------
module instr_to_imm (
  input [31:0] instr,
  input [2:0] ExtOp,
  output reg [31:0] imm
);
  wire [31:0] immI = {{20{instr[31]}}, instr[31:20]};
  wire [31:0] immU = {instr[31:12], 12'b0};
  wire [31:0] immS = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  wire [31:0] immB = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  wire [31:0] immJ = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

  always @(*) begin
    case (ExtOp)
      3'b000: imm = immI;
      3'b001: imm = immU;
      3'b010: imm = immS;
      3'b011: imm = immB;
      3'b100: imm = immJ;
      default: imm = 32'b0;
    endcase
  end
endmodule

`define CTRL_VAL_DEFINE(extop, regwr, aluasrc, alubsrc, aluctr, branch, memtoreg, memwr, memop) \
  begin\
    ExtOp    = extop;\
    RegWr    = regwr;\
    ALUASrc  = aluasrc;\
    ALUBSrc  = alubsrc;\
    ALUctr   = aluctr;\
    Branch   = branch;\
    MemtoReg = memtoreg;\
    MemWr    = memwr;\
    MemOp    = memop;\
  end

module ctrl (
  output reg [2:0] ExtOp,
  output reg       RegWr,
  output reg       ALUASrc,
  output reg [1:0] ALUBSrc,
  output reg [3:0] ALUctr,
  output reg [2:0] Branch,
  output reg       MemtoReg,
  output reg       MemWr,
  output reg [2:0] MemOp,
  input      [6:0] opcode,
  input      [2:0] funct3,
  input      [6:0] funct7,
  input            reset
);
  localparam U_LUI   = 7'b0110111;
  localparam U_AUIPC = 7'b0010111;
  localparam I_arith = 7'b0010011;
  localparam R_arith = 7'b0110011;
  localparam J_JAL   = 7'b1101111;
  localparam I_JALR  = 7'b1100111;
  localparam B_instr = 7'b1100011;
  localparam I_load  = 7'b0000011;
  localparam S_instr = 7'b0100011;

  wire is_U_LUI   = (opcode == U_LUI);
  wire is_U_AUIPC = (opcode == U_AUIPC);
  wire is_I_arith = (opcode == I_arith);
  wire is_R_arith = (opcode == R_arith) && (funct7 == 7'b0000000 || funct7 == 7'b0100000);
  wire is_J_JAL   = (opcode == J_JAL);
  wire is_I_JALR  = (opcode == I_JALR);
  wire is_B_instr = (opcode == B_instr);
  wire is_I_load  = (opcode == I_load);
  wire is_S_instr = (opcode == S_instr);

  wire I_extALUctr = (is_I_arith & (funct3 == 3'b001 | funct3 == 3'b101)) ? funct7[5] : 1'b0;
  wire R_extALUctr = funct7[5];

  wire [3:0] B_ALUctr = (funct3 == 3'b110 || funct3 == 3'b111) ? 4'b0011 : 4'b0010;
  reg [2:0] B_Branch;

  always @(*) begin
    case (funct3)
      3'b000: B_Branch = 3'b100;
      3'b001: B_Branch = 3'b101;
      3'b100: B_Branch = 3'b110;
      3'b101: B_Branch = 3'b111;
      3'b110: B_Branch = 3'b110;
      3'b111: B_Branch = 3'b111;
      default: B_Branch = 3'b000;
    endcase
  end

  always @(*) begin
    if (reset)
      `CTRL_VAL_DEFINE(3'b000, 1'b0, 1'b0, 2'b00, 4'b0000, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (is_U_LUI)
      `CTRL_VAL_DEFINE(3'b001, 1'b1, 1'b0, 2'b01, 4'b1111, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (is_U_AUIPC)
      `CTRL_VAL_DEFINE(3'b001, 1'b1, 1'b1, 2'b01, 4'b0000, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (is_I_arith)
      `CTRL_VAL_DEFINE(3'b000, 1'b1, 1'b0, 2'b01, {I_extALUctr, funct3}, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (is_R_arith)
      `CTRL_VAL_DEFINE(3'b000, 1'b1, 1'b0, 2'b00, {R_extALUctr, funct3}, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (is_J_JAL)
      `CTRL_VAL_DEFINE(3'b100, 1'b1, 1'b1, 2'b10, 4'b0000, 3'b001, 1'b0, 1'b0, 3'b000)
    else if (is_I_JALR)
      `CTRL_VAL_DEFINE(3'b000, 1'b1, 1'b1, 2'b10, 4'b0000, 3'b010, 1'b0, 1'b0, 3'b000)
    else if (is_B_instr)
      `CTRL_VAL_DEFINE(3'b011, 1'b0, 1'b0, 2'b00, B_ALUctr, B_Branch, 1'b0, 1'b0, 3'b000)
    else if (is_I_load)
      `CTRL_VAL_DEFINE(3'b000, 1'b1, 1'b0, 2'b01, 4'b0000, 3'b000, 1'b1, 1'b0, funct3)
    else if (is_S_instr)
      `CTRL_VAL_DEFINE(3'b010, 1'b0, 1'b0, 2'b01, 4'b0000, 3'b000, 1'b0, 1'b1, funct3)
    else
      `CTRL_VAL_DEFINE(3'b000, 1'b0, 1'b0, 2'b00, 4'b0000, 3'b000, 1'b0, 1'b0, 3'b000)
  end
endmodule

module branch_ctrl (
  output reg NxtASrc, NxtBSrc,
  input zero, result0,
  input [2:0] Branch
);
  always @(*) begin
    case (Branch)
      3'b000: begin NxtASrc = 0; NxtBSrc = 0; end
      3'b001: begin NxtASrc = 0; NxtBSrc = 1; end
      3'b010: begin NxtASrc = 1; NxtBSrc = 1; end
      3'b100: begin NxtASrc = 0; NxtBSrc = zero; end
      3'b101: begin NxtASrc = 0; NxtBSrc = ~zero; end
      3'b110: begin NxtASrc = 0; NxtBSrc = result0; end
      3'b111: begin NxtASrc = 0; NxtBSrc = ~result0; end
      default: begin NxtASrc = 0; NxtBSrc = 0; end
    endcase
  end
endmodule

module next_PC (
  output [31:0] nxtPC,
  input  [31:0] BusA,
  input  [31:0] curPC,
  input  [31:0] Imm,
  input         NxtASrc,
  input         NxtBSrc
);
  wire [31:0] PC_plus_4 = curPC + 4;
  wire [31:0] branch_target = curPC + Imm;
  wire [31:0] jalr_target = (BusA + Imm) & 32'hFFFFFFFE;

  assign nxtPC =
    (NxtASrc == 1'b1) ? jalr_target :
    (NxtBSrc == 1'b1) ? branch_target :
                        PC_plus_4;
endmodule

module ALU32 (
  output reg [31:0] result,
  output wire zero,
  input  [31:0] dataa,
  input  [31:0] datab,
  input  [3:0]  aluctr
);
  wire SUBctr;
  wire SIGctr;
  wire ALctr;
  wire SFTctr;
  wire [2:0] OPctr;

  ALU32_ctr alu32_ctr(
    .SUBctr(SUBctr),
    .SIGctr(SIGctr),
    .ALctr(ALctr),
    .SFTctr(SFTctr),
    .OPctr(OPctr),
    .aluctr(aluctr)
  );

  wire [31:0] res_add;
  wire OF, SF, ZF, CF;
  Adder32 adder(
    .f(res_add),
    .OF(OF), .SF(SF), .ZF(ZF), .CF(CF),
    .cout(),
    .x(dataa), .y(datab),
    .sub(SUBctr)
  );
  assign zero = ZF;

  wire [31:0] res_and = dataa & datab;
  wire [31:0] res_or = dataa | datab;
  wire [31:0] res_xor = dataa ^ datab;

  wire [31:0] res_sft;
  barrelsft32 sft(
    .dout(res_sft),
    .din(dataa),
    .shamt(datab[4:0]),
    .LR(SFTctr),
    .AL(ALctr)
  );

  wire [31:0] res_slt = {{31{1'b0}}, SIGctr ? (OF ^ SF) : CF};

  always @(*) begin
    case (OPctr)
      3'b000: result = res_add;
      3'b001: result = res_and;
      3'b010: result = res_or;
      3'b011: result = res_xor;
      3'b100: result = res_sft;
      3'b101: result = datab;
      3'b110: result = res_slt;
      default: result = 32'b0;
    endcase
  end
endmodule

`define ALU32_SIGEXT(x, y, z, u, v) \
  begin SUBctr = 1'b``x; SIGctr = 1'b``y; ALctr = 1'b``z; SFTctr = 1'b``u; OPctr = 3'b``v; end

module ALU32_ctr (
  output reg SUBctr,
  output reg SIGctr,
  output reg ALctr,
  output reg SFTctr,
  output reg [2:0] OPctr,
  input [3:0] aluctr
);
  always @(*) begin
    case (aluctr)
      4'b0000: `ALU32_SIGEXT(0, 0, 0, 0, 000)
      4'b0001: `ALU32_SIGEXT(0, 0, 0, 1, 100)
      4'b0010: `ALU32_SIGEXT(1, 1, 0, 0, 110)
      4'b0011: `ALU32_SIGEXT(1, 0, 0, 0, 110)
      4'b0100: `ALU32_SIGEXT(0, 0, 0, 0, 011)
      4'b0101: `ALU32_SIGEXT(0, 0, 0, 0, 100)
      4'b0110: `ALU32_SIGEXT(0, 0, 0, 0, 010)
      4'b0111: `ALU32_SIGEXT(0, 0, 0, 0, 001)
      4'b1000: `ALU32_SIGEXT(1, 0, 0, 0, 000)
      4'b1101: `ALU32_SIGEXT(0, 0, 1, 0, 100)
      4'b1111: `ALU32_SIGEXT(0, 0, 0, 0, 101)
      default: `ALU32_SIGEXT(0, 0, 0, 0, 000)
    endcase
  end
endmodule

module Adder32 (
  output [31:0] f,
  output OF, SF, ZF, CF,
  output cout,
  input [31:0] x, y,
  input sub
);
  wire c16;
  wire [31:0] Y = sub ? ~y : y;

  CLA_16 cla_low(
    .f(f[15:0]),
    .cout(c16),
    .x(x[15:0]),
    .y(Y[15:0]),
    .cin(sub)
  );

  CLA_16 cla_hi(
    .f(f[31:16]),
    .cout(cout),
    .x(x[31:16]),
    .y(Y[31:16]),
    .cin(c16)
  );

  assign OF = (~x[31] & ~Y[31] & f[31]) | (x[31] & Y[31] & ~f[31]);
  assign SF = f[31];
  assign ZF = ~|f;
  assign CF = cout ^ sub;
endmodule

module CLA_16 (
  output [15:0] f,
  output cout,
  input [15:0] x, y,
  input cin
);
  wire [4:0] c;
  wire [4:1] Pi, Gi;
  assign c[0] = cin;

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : gen_subFA
      CLA_4PG cla_4pg(
        .f(f[4*i+3:4*i]),
        .pg(Pi[i+1]), .gg(Gi[i+1]),
        .x(x[4*i+3:4*i]),
        .y(y[4*i+3:4*i]),
        .cin(c[i])
      );
    end
  endgenerate

  CLU clu(.c(c[4:1]), .p(Pi), .g(Gi), .c0(c[0]));
  assign cout = c[4];
endmodule

module CLA_4PG (
  output [3:0] f,
  output pg, gg,
  input [3:0] x, y,
  input cin
);
  wire [4:0] c;
  wire [4:1] p, g;
  assign c[0] = cin;

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : gen_subFA
      FA_PG fa(
        .f(f[i]), .p(p[i+1]), .g(g[i+1]),
        .x(x[i]), .y(y[i]), .cin(c[i])
      );
    end
  endgenerate

  CLU clu(.c(c[4:1]), .p(p), .g(g), .c0(c[0]));
  assign pg = &p;
  assign gg = g[4] | (p[4] & g[3]) | (&p[4:3] & g[2]) | (&p[4:2] & g[1]);
endmodule

module CLU (
  output [4:1] c,
  input [4:1] p, g,
  input c0
);
  assign c[1] = g[1] | (p[1] & c0);
  assign c[2] = g[2] | (p[2] & g[1]) | (&p[2:1] & c0);
  assign c[3] = g[3] | (p[3] & g[2]) | (&p[3:2] & g[1]) | (&p[3:1] & c0);
  assign c[4] = g[4] | (p[4] & g[3]) | (&p[4:3] & g[2]) | (&p[4:2] & g[1]) | (&p[4:1] & c0);
endmodule

module FA_PG (
  output f, p, g,
  input x, y, cin
);
  assign f = x ^ y ^ cin;
  assign p = x | y;
  assign g = x & y;
endmodule

module barrelsft32 (
  output reg [31:0] dout,
  input [31:0] din,
  input [4:0] shamt,
  input LR,
  input AL
);
  wire in = (LR == 0 && AL == 1) ? din[31] : 1'b0;

  always @(*) begin
    dout = din;
    if (shamt[0])
      dout = LR ? {dout[30:0], in} : {in, dout[31:1]};
    if (shamt[1])
      dout = LR ? {dout[29:0], {2{in}}} : {{2{in}}, dout[31:2]};
    if (shamt[2])
      dout = LR ? {dout[27:0], {4{in}}} : {{4{in}}, dout[31:4]};
    if (shamt[3])
      dout = LR ? {dout[23:0], {8{in}}} : {{8{in}}, dout[31:8]};
    if (shamt[4])
      dout = LR ? {dout[15:0], {16{in}}} : {{16{in}}, dout[31:16]};
  end
endmodule
