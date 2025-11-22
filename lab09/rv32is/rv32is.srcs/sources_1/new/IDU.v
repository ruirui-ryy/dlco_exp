`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/02 20:41:44
// Design Name: 
// Module Name: IDU
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


module IDU(
    input [31:0]  IR,
    input [31:0]  PC,
    input [31:0]  BusA,
    input [31:0]  BusB,
    input [2:0]   ExtOp,
    input         ALUAsrc, 
    input [1:0]   ALUBsrc, 
    output [31:0] DataA,
    output [31:0] DataB,
    output [31:0] imm,
    output [6:0]  op,
    output [2:0]  funct3,
    output [6:0]  funct7
    );
    
    // 指令解析 
    assign op = IR[6:0];
    assign funct3 = IR[14:12];
    assign funct7 = IR[31:25];
    immgen myimmgen (.instr(IR), .ExtOp(ExtOp), .imm(imm));

    // 输出数据 
    assign DataA = (ALUAsrc == 1'b0) ? BusA : PC;
    assign DataB = (ALUBsrc == 2'b00) ? BusB :
                   (ALUBsrc == 2'b01) ? imm :
                   (ALUBsrc == 2'b10) ? 32'd4 : 32'b0;
    
endmodule