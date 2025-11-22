`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/01 23:46:11
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


module rv32is(
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

	// 信号 
	wire [31:0] PC;
	assign dbgdata = PC;
	assign imemclk   = ~clock;
    assign dmemrdclk = clock;
    assign dmemwrclk = ~clock;
    
    // 取指令 
    IFU myifu (.imm(imm), .BusA(BusA), .clk(~clock), .reset(reset), .NPCASrc(NPCASrc), .NPCBSrc(NPCBSrc), .nextPC_wire(imemaddr), .PC(PC));
    
    // 指令解析 
    wire [31:0] BusW, DataA, DataB, BusA, BusB, imm;
    wire [6:0] op, funct7;
    wire [2:0] funct3;
    wire [4:0] rs1 = imemdataout[19:15];
    wire [4:0] rs2 = imemdataout[24:20];
    wire [4:0] rd  = imemdataout[11:7];
    
    regfile myregfile (.ra(rs1),.rb(rs2), .rw(rd), .wrdata(BusW), .regwr(RegWr), .wrclk(~clock), .outa(BusA), .outb(BusB));
	IDU myidu (.IR(imemdataout), .PC(PC), .BusA(BusA), .BusB(BusB), .ExtOp(ExtOp),
	           .ALUAsrc(ALUAsrc), .ALUBsrc(ALUBsrc), .DataA(DataA), .DataB(DataB),
               .imm(imm), .op(op), .funct3(funct3), .funct7(funct7)
               );
	           
	// 控制信号 
	wire        RegWr;
    wire        MemWr;
    wire        MemtoReg;
    wire        ALUAsrc;
    wire [1:0]  ALUBsrc;
    wire [2:0]  ExtOp;
    wire [3:0]  ALUctr;
    wire [2:0]  Branch;
    wire [2:0]  MemOP;
    control ctrl(
        .op(op), .func3(funct3), .func7_5(funct7[5]),
        .ExtOp(ExtOp), .RegWr(RegWr), .Branch(Branch),
        .MemtoReg(MemtoReg), .MemWr(MemWr), .MemOP(MemOP),
        .ALUAsrc(ALUAsrc), .ALUBsrc(ALUBsrc), .ALUctr(ALUctr)
    );
    
    // ALU 模块 
    wire less, zero;
    wire [31:0] ALUout;
    alu myalu (.dataa(DataA), .datab(DataB), .ALUctr(ALUctr), .less(less), .zero(zero), .aluresult(ALUout));
    
    // 跳转控制模块 
    BandJ mybj (.BandJ(Branch), .zero(zero), .result0(ALUout[0]), .NPCASrc(NPCASrc), .NPCBSrc(NPCBSrc)); 
    
    // 数据通路 
    assign dmemaddr = ALUout;
    assign dmemdatain = BusB;
    assign dmemop = MemOP;
    assign dmemwe = MemWr;
    
    // 写入数据 
    assign BusW = (MemtoReg == 1'b0) ? ALUout : dmemdataout;
    
endmodule