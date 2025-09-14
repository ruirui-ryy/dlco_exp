`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 14:05:38
// Design Name: 
// Module Name: clk_div_test
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


module clk_div_test(

    );
    reg CLK100MHZ;
    wire clk_1;
    
    top uut(
        .CLK100MHZ(CLK100MHZ),
        .clk_1(clk_1)
    );
    
    initial begin
        CLK100MHZ = 0;
        forever #5 CLK100MHZ = ~CLK100MHZ; 
    end
        
endmodule
