`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/10 23:40:22
// Design Name: 
// Module Name: counter
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

module clk_div(
    input clk,          
    output reg clk_1s = 0   
);
    reg [25:0] cnt = 0;
    always @(posedge clk) begin
        if (cnt == 49999999) begin  
            cnt <= 0;
            clk_1s <= ~clk_1s;    
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule

module counter(
	input  CLK100MHZ,
	input  en,
	input  rst,
	input  [3:0] cnt_limit,
	output reg [3:0] Q,
	output reg rco
	);
	
	wire clk_1s;
	
	clk_div u_clk(
	   .clk(CLK100MHZ),
	   .clk_1s(clk_1s)
	   );

    always @(posedge clk_1s) begin
        if (en) begin
            if (rst) begin
                Q <= 4'd0;
                rco <= 1'b0;
            end else if (Q == cnt_limit - 1) begin
                Q <= 4'd0;
                rco <= 1'b1;
            end else begin
                Q <= Q + 1'b1;
                rco <= 1'b0;
            end
        end
        else begin
            Q <= Q;
            rco <= 1'b0;
        end
    end

endmodule