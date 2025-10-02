`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/20 16:17:55
// Design Name: 
// Module Name: reg16x8
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

module reg16x8(
    input  [3:0]  ra,
	input  [3:0]  rb,
	input  [3:0]  rw,
	input  [7:0] wrdata,
	input  regwr,
	input  wrclk,
	output [7:0] outa,
	output [7:0] outb
	);
	
	//The regfile
	reg [7:0] regs[15:0];	
	initial
        begin
            $readmemh("D:/digitaldesign/ram16x8/mem1.txt", regs, 0, 15);
        end
	
    assign outa = regs[ra];
    assign outb = regs[rb];

	always@(posedge wrclk) begin
        if (regwr) begin
            regs[rw] <= wrdata;
        end 
    end 
	
endmodule