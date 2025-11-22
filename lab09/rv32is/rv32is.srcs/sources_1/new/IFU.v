`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/02 23:46:57
// Design Name: 
// Module Name: IFU
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


module IFU(
    input [31:0]  imm,
    input [31:0]  BusA,
    input         clk, 
    input         reset,
    input         NPCASrc, 
    input         NPCBSrc, 
    output [31:0] nextPC_wire,
    output reg [31:0] PC
    );
    
    wire [31:0] SrcA, SrcB;
    wire [31:0] nextPC_comb;
    assign SrcA = (NPCASrc == 1'b0) ? PC : BusA;
    assign SrcB = (NPCBSrc == 1'b0) ? 32'd4 : imm;
    assign nextPC_comb = SrcA + SrcB;
    assign nextPC_wire = reset ? 32'b0 : nextPC_comb;
    
    always @(posedge clk) begin
        if (reset) begin 
            PC <= 32'b0;
        end else begin 
            PC <= nextPC_wire;
        end
    end
endmodule
