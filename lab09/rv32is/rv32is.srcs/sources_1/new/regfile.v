`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/02 14:51:09
// Design Name: 
// Module Name: regfile
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
