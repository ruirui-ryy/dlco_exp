`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/09 20:25:31
// Design Name: 
// Module Name: rv32ip
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


module rv32ip(
    input 	clock,
	input 	reset,
	output [31:0] imemaddr,
	input  [31:0] imemdataout,
	output 	imemclk,
	output [31:0] dmemaddr,
	input  [31:0] dmemdataout,
	output [31:0] dmemdatain,
	output 	dmemrdclk,
	output	dmemwrclk,
	output [2:0] dmemop,
	output	dmemwe,
	output [31:0] dbgdata);

    // 陓瘍 
	wire [31:0] IF_PC;
	assign dbgdata = IF_PC;
	assign imemclk   = ~clock;
    assign dmemrdclk = clock;
    assign dmemwrclk = ~clock;
    
    // IF 論僇
    wire [31:0] Target;
    wire Jump, PCWr;
    IFU myifu (.clk(~clock), .reset(reset), .Target(Target), .PCMUX(Jump), .PCWr(PCWr), .nextPC_wire(imemaddr), .PC(IF_PC));
    
    wire IFIDWr;
    wire [31:0] ID_PC, ID_IR;
    pipeline_reg IFID (.clk(~clock), .clr(Jump), .en(IFIDWr), .wire32_1(IF_PC), .wire32_2(imemdataout), 
                       .wire32_1o(ID_PC), .wire32_2o(ID_IR));
                       
    
    // ID 論僇 
    wire [3:0] ID_ALUctr;
    wire [2:0] ID_ExtOp, ID_Branch, ID_MemOP;
    wire [1:0] ID_ALUBsrc;
    wire ID_RegWr, ID_MemtoReg, ID_MemWr, ID_ALUAsrc;
    wire ctrMUX;
    control myctr (ID_IR ,ctrMUX ,ID_ExtOp ,ID_RegWr ,ID_Branch ,ID_MemtoReg ,ID_MemWr ,ID_MemOP ,ID_ALUAsrc ,ID_ALUBsrc ,ID_ALUctr );
    
    wire [4:0] ID_rs1, ID_rs2, ID_rd;
    wire [31:0] ID_imm;
    IDU myidu (ID_IR ,ID_ExtOp ,ID_rs1 ,ID_rs2 ,ID_rd ,ID_imm);
    
    wire [31:0] WB_DW;
    wire WB_RegWr;
    wire [31:0] rda, rdb;
    regfile myregfile (ID_rs1 ,ID_rs2 ,ID_rd ,WB_DW ,WB_RegWr ,clock ,rda ,rdb);
    
    wire [31:0] EX_PC, EX_imm, EX_rda, EX_rdb;
    wire [4:0] EX_rd, EX_rs1, EX_rs2;
    wire [3:0] EX_ALUctr;
    wire [2:0] EX_ExtOp, EX_Branch, EX_MemOP;
    wire [1:0] EX_ALUBsrc;
    wire EX_RegWr, EX_MemtoReg, EX_MemWr, EX_ALUAsrc;
    pipeline_reg IDEX (.clk(~clock), .clr(Jump), .en(1'b1),
                       .wire32_1(ID_PC), .wire32_2(ID_imm), .wire32_3(rda), .wire32_4(rdb),
                       .wire5_1(ID_rd), .wire5_2(ID_rs1), .wire5_3(ID_rs2), 
                       .ALUAsrc(ID_ALUAsrc), .ALUBsrc(ID_ALUBsrc), .ALUctr(ID_ALUctr), .MemWr(ID_MemWr),
                       .Branch(ID_Branch), .MemOP(ID_MemOP), .MemtoReg(ID_MemtoReg),.RegWr(ID_RegWr),
                       .wire32_1o(EX_PC), .wire32_2o(EX_imm), .wire32_3o(EX_rda), .wire32_4o(EX_rdb),
                       .wire5_1o(EX_rd), .wire5_2o(EX_rs1), .wire5_3o(EX_rs2),
                       .ALUAsrc_o(EX_ALUAsrc), .ALUBsrc_o(EX_ALUBsrc), .ALUctr_o(EX_ALUctr), .MemWr_o(EX_MemWr),
                       .Branch_o(EX_Branch), .MemOP_o(EX_MemOP), .MemtoReg_o(EX_MemtoReg),.RegWr_o(EX_RegWr)
                       );
                       
                       
    // EX 論僇 
    wire [1:0] BusAFW, BusBFW;
    wire [31:0] busA, busB;
    wire [31:0] EX_ALUout, M_ALUout;
    wire zero;
    assign busA = (BusAFW == 2'b00) ? EX_rda :
                  (BusAFW == 2'b01) ? WB_DW :
                  (BusAFW == 2'b10) ? M_ALUout : 32'b0;
    assign busB = (BusBFW == 2'b00) ? EX_rdb :
                  (BusBFW == 2'b01) ? WB_DW :
                  (BusBFW == 2'b10) ? M_ALUout : 32'b0;
    ExecUnit myexc (.PC(EX_PC), .busA(busA), .busB(busB), .imm(EX_imm), .ALUASrc(EX_ALUAsrc), .ALUBSrc(EX_ALUBsrc),
                    .ALUctr(EX_ALUctr), .BandJ(EX_Branch), .Target(Target), .ALUout(EX_ALUout), .zero(zero));
    BandJ mybandj (.BandJ(EX_Branch), .zero(zero), .result0(EX_ALUout[0]), .PCMUX(Jump));
    
    wire [2:0] M_MemOP;
    wire M_RegWr, M_MemtoReg, M_MemWr;
    wire [31:0] M_busB;
    wire [4:0] M_rd;
    pipeline_reg EXM (.clk(~clock), .clr(1'b0), .en(1'b1),
                       .wire32_1(EX_ALUout), .wire32_2(busB),
                       .wire5_1(EX_rd),
                       .MemWr(EX_MemWr),
                       .MemOP(EX_MemOP), .MemtoReg(EX_MemtoReg),.RegWr(EX_RegWr),
                       .wire32_1o(M_ALUout), .wire32_2o(M_busB),
                       .wire5_1o(M_rd),
                       .MemWr_o(M_MemWr),
                       .MemOP_o(M_MemOP), .MemtoReg_o(M_MemtoReg),.RegWr_o(M_RegWr)
                       );
    
    
    // M 論僇 
    assign dmemaddr = M_ALUout;
    assign dmemdatain = M_busB;
    assign dmemop = M_MemOP;
    assign dmemwe = M_MemWr;
    wire [31:0] M_dout;
    assign M_dout = dmemdataout;
    
    wire WB_MemtoReg;
    wire [31:0] WB_dout, WB_ALUout;
    wire [4:0] WB_rd;
    
    pipeline_reg MWB (.clk(~clock), .clr(1'b0), .en(1'b1),
                      .wire32_1(M_dout), .wire32_2(M_ALUout),
                      .wire5_1(M_rd),
                      .MemtoReg(M_MemtoReg), .RegWr(M_RegWr),
                      .wire32_1o(WB_dout), .wire32_2o(WB_ALUout),
                      .wire5_1o(WB_rd),
                      .MemtoReg_o(WB_MemtoReg), .RegWr_o(WB_RegWr)
                      );
    
    
    // WB 論僇 
    assign WB_DW = (WB_MemtoReg) ? WB_dout : WB_ALUout;
    
    // 簸玸 
    stalling mystl (.IR(ID_IR), .MemtoReg(EX_MemtoReg), .rd(EX_rd), .ctrMUX(ctrMUX), .ifidWr(IFIDWr), .PCWr(PCWr));
    forwarding myfwd (.EX_rs1(EX_rs1), .EX_rs2(EX_rs2), .M_RegWr(M_RegWr), .M_rd(M_rd), .WB_RegWr(WB_RegWr), .WB_rd(WB_rd),
                     .BusAFW(BusAFW), .BusBFW(BusBFW));

endmodule

module IFU(
    input         clk, 
    input         reset,
    input  [31:0] Target,
    input         PCMUX,
    input         PCWr,
    output [31:0] nextPC_wire,
    output reg [31:0] PC
    );
    assign nextPC_comb = (PCMUX) ? (Target) : (PC + 4);
    assign nextPC_wire = reset ? 32'b0 : nextPC_comb;
    
    always @(posedge clk) begin
        if (!PCWr) PC <= PC;
        if (reset) begin 
            PC <= 32'b0;
        end else begin 
            PC <= nextPC_wire;
        end
    end
endmodule

module IDU(
    input [31:0]  IR,
    input [2:0]   ExtOp,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [31:0] imm
    );
    immgen myimmgen (.instr(IR), .ExtOp(ExtOp), .imm(imm));
    assign rs1 = IR[19:15];
    assign rs2 = IR[24:20];
    assign rd = IR[11:7];
endmodule

module immgen(input  [31:0] instr, 
              input  [2:0]  ExtOp,
              output reg [31:0] imm
              );
    always @(*) begin
        case (ExtOp)
            3'b000: imm = {{20{instr[31]}}, instr[31:20]};
            3'b001: imm = {instr[31:12], 12'b0};
            3'b010: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            3'b011: imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            3'b100: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm = 32'b0;
        endcase
    end
endmodule

module regfile(
    input  [4:0]  ra,
	input  [4:0]  rb,
	input  [4:0]  rw,
	input  [31:0] wrdata,
	input  regwr,
	input  wrclk,
	output [31:0] outa,
	output [31:0] outb
	);
	
	reg [31:0] regs[31:0];	
	
    assign outa = (ra == 0) ? 32'd0 : regs[ra];
    assign outb = (rb == 0) ? 32'd0 : regs[rb];

	always@(posedge wrclk) begin
        if (regwr) begin
            if (rw != 0) begin
                regs[rw] <= wrdata;
            end 
        end 
    end 
endmodule

module control(
    input [31:0] IR,
    input ctrMUX,
    output [2:0] ExtOp_o,
    output       RegWr_o,
    output [2:0] Branch_o,
    output       MemtoReg_o,
    output       MemWr_o,
    output [2:0] MemOP_o,
    output       ALUAsrc_o,
    output [1:0] ALUBsrc_o,
    output [3:0] ALUctr_o
);
    reg [3:0] ALUctr;
    reg [2:0] ExtOp, Branch, MemOP;
    reg [1:0] ALUBsrc;
    reg RegWr, MemtoReg, MemWr, ALUAsrc;
    
    wire [6:0] op;
    wire [2:0] func3;
    wire func7_5;
    assign op = IR[6:0];
    assign func3 = IR[14:12];
    assign func7_5 = IR[30];
    wire [4:0] op5 = op[6:2];

    always @(*) begin
        // defaults
        ExtOp = 3'b000;
        RegWr = 1'b0;
        Branch = 3'b000;
        MemtoReg = 1'b0;
        MemWr = 1'b0;
        MemOP = 3'b010; // default word
        ALUAsrc = 1'b0;
        ALUBsrc = 2'b00;
        ALUctr = 4'b0000;

        case (op5)
            5'b01101: begin // lui
                ExtOp = 3'b001; RegWr = 1'b1; ALUBsrc = 2'b01; ALUctr = 4'b0011; ALUAsrc = 1'b0;
            end
            5'b00101: begin // auipc
                ExtOp = 3'b001; RegWr = 1'b1; ALUAsrc = 1'b1; ALUBsrc = 2'b01; ALUctr = 4'b0000;
            end
            5'b00100: begin // I-type ALU immediate (addi, slti, sltiu, xori, ori, andi, shifts)
                ExtOp = 3'b000; RegWr = 1'b1; ALUBsrc = 2'b01; ALUAsrc = 1'b0;
                case (func3)
                    3'b000: ALUctr = 4'b0000; // addi
                    3'b010: ALUctr = 4'b0010; // slti -> slt compare via ALU set 1/0
                    3'b011: ALUctr = 4'b1010; // sltiu
                    3'b100: ALUctr = 4'b0100; // xori
                    3'b110: ALUctr = 4'b0110; // ori
                    3'b111: ALUctr = 4'b0111; // andi
                    3'b001: ALUctr = 4'b0001; // slli (shamt)
                    3'b101: begin // srli or srai depending on func7[5]
                        if (func7_5==1'b0) ALUctr = 4'b0101; else ALUctr = 4'b1101;
                    end
                    default: ALUctr = 4'b0000;
                endcase
            end
            5'b01100: begin // R-type (register-reg)
                RegWr = 1'b1; ALUAsrc = 1'b0; ALUBsrc = 2'b00;
                case (func3)
                    3'b000: ALUctr = (func7_5==1'b1) ? 4'b1000 : 4'b0000; // sub/add
                    3'b001: ALUctr = 4'b0001; // sll
                    3'b010: ALUctr = 4'b0010; // slt
                    3'b011: ALUctr = 4'b1010; // sltu
                    3'b100: ALUctr = 4'b0100; // xor
                    3'b101: ALUctr = (func7_5==1'b1) ? 4'b1101 : 4'b0101; // sra/srl
                    3'b110: ALUctr = 4'b0110; // or
                    3'b111: ALUctr = 4'b0111; // and
                    default: ALUctr = 4'b0000;
                endcase
            end
            5'b11011: begin // jal
                ExtOp = 3'b100; RegWr = 1'b1; Branch = 3'b001; ALUAsrc = 1'b1; ALUBsrc = 2'b10; ALUctr = 4'b0000; // ALU produces PC+4
            end
            5'b11001: begin // jalr
                ExtOp = 3'b000; RegWr = 1'b1; Branch = 3'b010; ALUAsrc = 1'b1; ALUBsrc = 2'b10; ALUctr = 4'b0000;
            end
            5'b11000: begin // branches (B-type) beq bne blt bge bltu bgeu
                ExtOp = 3'b011; RegWr = 1'b0; ALUAsrc = 1'b0; ALUBsrc = 2'b00;
                case (func3)
                    3'b000: begin Branch = 3'b100; ALUctr = 4'b0010; end // beq uses Zero
                    3'b001: begin Branch = 3'b101; ALUctr = 4'b0010; end// bne
                    3'b100: begin Branch = 3'b110; ALUctr = 4'b0010; end// blt
                    3'b101: begin Branch = 3'b111; ALUctr = 4'b0010; end// bge
                    3'b110: begin Branch = 3'b110; ALUctr = 4'b1010; end// bltu
                    3'b111: begin Branch = 3'b111; ALUctr = 4'b1010; end// bgeu
                    default: Branch = 3'b000;
                endcase
            end
            5'b00000: begin // loads: lb lh lw lbu lhu
                ExtOp = 3'b000; RegWr = 1'b1; MemtoReg = 1'b1; MemWr = 1'b0; ALUAsrc = 1'b0; ALUBsrc = 2'b01; ALUctr = 4'b0000;
                case (func3)
                    3'b000: MemOP = 3'b000; // lb (sign)
                    3'b001: MemOP = 3'b001; // lh
                    3'b010: MemOP = 3'b010; // lw
                    3'b100: MemOP = 3'b100; // lbu
                    3'b101: MemOP = 3'b101; // lhu
                    default: MemOP = 3'b010;
                endcase
            end
            5'b01000: begin // stores: sb sh sw
                ExtOp = 3'b010; RegWr = 1'b0; MemWr = 1'b1; ALUAsrc = 1'b0; ALUBsrc = 2'b01; ALUctr = 4'b0000;
                case (func3)
                    3'b000: MemOP = 3'b000; // sb
                    3'b001: MemOP = 3'b001; // sh
                    3'b010: MemOP = 3'b010; // sw
                    default: MemOP = 3'b010;
                endcase
            end
            default: begin
                // unknown opcode - keep defaults (NOP-ish)
                ExtOp = 3'b000; RegWr = 1'b0; Branch = 3'b000; MemtoReg = 1'b0; MemWr = 1'b0; MemOP = 3'b010;
                ALUAsrc = 1'b0; ALUBsrc = 2'b00; ALUctr = 4'b0000;
            end
        endcase
    end
    assign ExtOp_o = (ctrMUX) ? 3'b0 : ExtOp;
    assign RegWr_o = (ctrMUX) ? 1'b0 : RegWr;
    assign Branch_o = (ctrMUX) ? 3'b0 : Branch;
    assign MemtoReg_o = (ctrMUX) ? 1'b0 : MemtoReg; 
    assign MemWr_o = (ctrMUX) ? 1'b0 : MemWr;
    assign MemOP_o = (ctrMUX) ? 3'b0 : MemOP; 
    assign ALUAsrc_o = (ctrMUX) ? 1'b0 : ALUAsrc;
    assign ALUBsrc_o = (ctrMUX) ? 2'b0 : ALUBsrc;
    assign ALUctr_o = (ctrMUX) ? 4'b0 :  ALUctr; 
endmodule

module alu(
	input [31:0] dataa,
	input [31:0] datab,
	input [3:0]  ALUctr,
	output less,
	output zero,
	output reg [31:0] aluresult);

    wire [31:0] F;
    wire cf, of, zero_adder;
    wire less_sign;
    adder a_adder(
        .A(dataa),
        .B(datab),
        .addsub(|ALUctr),
        .F(F),
        .cf(cf),
        .zero(zero_adder),
        .of(of)
    );
    assign less_sign = F[31] ^ of;
    wire less_unsign = cf;

    wire [4:0] shamt = datab[4:0];
    
    always @(*) begin
        case (ALUctr) 
            4'b0000: aluresult = dataa + datab;
            4'b1000: aluresult = dataa - datab;
            4'b0001: aluresult = dataa << shamt;
            4'b1001: aluresult = dataa << shamt;
            4'b0010: aluresult = {31'b0, less_sign};
            4'b1010: aluresult = {31'b0, less_unsign};
            4'b0011: aluresult = datab;
            4'b1011: aluresult = datab;
            4'b0100: aluresult = dataa ^ datab;
            4'b1100: aluresult = dataa ^ datab;
            4'b0101: aluresult = dataa >> shamt;
            4'b1101: aluresult = (dataa >> shamt) | ({32{dataa[31]}} << (32 - shamt));
            4'b0110: aluresult = dataa | datab;
            4'b1110: aluresult = dataa | datab;
            4'b0111: aluresult = dataa & datab;
            4'b1111: aluresult = dataa & datab;
            default: aluresult = 32'b0;
        endcase
    end

    assign zero = (ALUctr[2:0] == 3'b010) ? (dataa == datab) : (aluresult == 32'b0);
    assign less = (ALUctr == 4'b0010) ? less_sign :       
                  (ALUctr == 4'b1010) ? less_unsign : 1'b0;

endmodule

module adder(
	input  [31:0] A,
	input  [31:0] B,
	input  addsub,
	output [31:0] F,
	output cf,
	output zero,
	output of
	);

    wire [31:0] b_in;
    wire carry;
    assign b_in = B ^ {32{addsub}};
    assign {carry, F} = A + b_in + {31'b0, addsub}; 
    assign cf = carry ^ addsub;
    assign of = (A[31] == (B[31] ^ addsub)) & (F[31] != A[31]);
    assign zero = (F == 32'b0);

endmodule

module BandJ(
    input [2:0] BandJ,
    input zero,
    input result0,
    output PCMUX
    );
    wire NPCASrc;
    reg NPCBSrc;
    always @(*) begin 
        case (BandJ)
            3'b000: NPCBSrc = 1'b0;
            3'b001: NPCBSrc = 1'b1;
            3'b010: NPCBSrc = 1'b1;
            3'b100: NPCBSrc = zero;
            3'b101: NPCBSrc = ~zero;
            3'b110: NPCBSrc = result0;
            3'b111: NPCBSrc = zero | ~result0;
            default: NPCBSrc = 1'b0;
        endcase 
    end 
    assign NPCASrc = (~BandJ[0]) & (BandJ[1]) & (~BandJ[2]);
    assign PCMUX = NPCASrc | NPCBSrc;
endmodule

module pipeline_reg (
    input clk,
    input clr, 
    input en,
    input [31:0] wire32_1,
    input [31:0] wire32_2, 
    input [31:0] wire32_3, 
    input [31:0] wire32_4,
    input [4:0] wire5_1, 
    input [4:0] wire5_2, 
    input [4:0] wire5_3,
    input [2:0] ExtOp,
    input       RegWr,
    input [2:0] Branch,
    input       MemtoReg,
    input       MemWr,
    input [2:0] MemOP,
    input       ALUAsrc,
    input [1:0] ALUBsrc,
    input [3:0] ALUctr,
    output reg [31:0] wire32_1o,
    output reg [31:0] wire32_2o,
    output reg [31:0] wire32_3o,
    output reg [31:0] wire32_4o,
    output reg [4:0] wire5_1o,
    output reg [4:0] wire5_2o,
    output reg [4:0] wire5_3o,
    output reg [2:0] ExtOp_o,
    output reg       RegWr_o,
    output reg [2:0] Branch_o,
    output reg       MemtoReg_o,
    output reg       MemWr_o,
    output reg [2:0] MemOP_o,
    output reg       ALUAsrc_o,
    output reg [1:0] ALUBsrc_o,
    output reg [3:0] ALUctr_o
    );
    always @(posedge clk) begin    
        if (en) begin
            if (clr) begin 
                wire32_1o = 32'b0;
                wire32_2o = 32'b0;
                wire32_3o = 32'b0;
                wire32_4o = 32'b0;
                wire5_1o = 32'b0;
                wire5_2o = 32'b0;
                wire5_3o = 32'b0;
                ExtOp_o = 3'b0; 
                RegWr_o = 1'b0;
                Branch_o = 3'b0;
                MemtoReg_o = 1'b0;
                MemWr_o = 1'b0;
                MemOP_o = 3'b0;
                ALUAsrc_o = 1'b0;
                ALUBsrc_o = 2'b0;
                ALUctr_o = 4'b0;
            end else begin
                wire32_1o = wire32_1;
                wire32_2o = wire32_2;
                wire32_3o = wire32_3;
                wire32_4o = wire32_4;
                wire5_1o = wire5_1;
                wire5_2o = wire5_2;
                wire5_3o = wire5_3;
                ExtOp_o = ExtOp; 
                RegWr_o = RegWr;
                Branch_o = Branch;
                MemtoReg_o = MemtoReg;
                MemWr_o = MemWr;
                MemOP_o = MemOP;
                ALUAsrc_o = ALUAsrc;
                ALUBsrc_o = ALUBsrc;
                ALUctr_o = ALUctr;
            end
        end
    end
endmodule

module ExecUnit (
    input [31:0] PC,
    input [31:0] busA,
    input [31:0] busB,
    input [31:0] imm,
    input ALUASrc, 
    input [1:0] ALUBSrc,
    input [3:0] ALUctr,
    input [2:0] BandJ,
    output [31:0] Target,
    output [31:0] ALUout,
    output zero
    );
    wire isjalr;
    assign isjalr = BandJ == 3'b010;
    wire [31:0] srca, srcb;
    assign srca = (isjalr) ? busA : PC;
    assign srcb = imm;
    assign Target = srca + srcb;
    
    wire [31:0] alua, alub;
    assign alua = (ALUASrc) ? PC : busA;
    assign alub = (ALUBSrc == 2'b00) ? busB :
                  (ALUBSrc == 2'b01) ? imm :
                  (ALUBSrc == 2'b10) ? 32'd4 : 32'b0;  
    wire less;
    alu myalu (.dataa(alua), .datab(alub), .ALUctr(ALUctr), .less(less), .zero(zero), .aluresult(ALUout));
endmodule 

module stalling (
    input [31:0] IR,
    input MemtoReg,
    input [4:0] rd,
    output ctrMUX,
    output ifidWr,
    output PCWr
    );
    wire [4:0] rs1, rs2;
    assign rs1 = IR[19:15];
    assign rs2 = IR[24:20];
    
    wire flag;
    assign flag = ((rs1 == rd) | (rs2 == rd)) & MemtoReg;
    assign ctrMUX = flag;
    assign ifidWr = ~flag;
    assign PCWr = ~flag;
endmodule 

module forwarding (
    input [4:0] EX_rs1,
    input [4:0] EX_rs2,
    input M_RegWr,
    input [4:0] M_rd,
    input WB_RegWr,
    input [4:0] WB_rd,
    output [1:0] BusAFW,
    output [1:0] BusBFW
    );
    assign BusAFW[1] = (EX_rs1 == M_rd) & M_RegWr;
    assign BusAFW[0] = ~BusAFW[1] & ((EX_rs1 == WB_rd) & WB_RegWr);
    assign BusBFW[1] = (EX_rs2 == M_rd) & M_RegWr;
    assign BusBFW[0] = ~BusBFW[1] & ((EX_rs2 == WB_rd) & WB_RegWr);
endmodule
