`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/30 17:48:57
// Design Name: 
// Module Name: lab01_1_test
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


module lab01_1_test(

    );
    reg [1:0] X0;
    reg [1:0] X1;
    reg [1:0] X2;
    reg [1:0] X3;
    reg [1:0] Y;
    wire [1:0] F;
    
    lab01_1 i1 (
        .X0(X0),
        .X1(X1),
        .X2(X2),
        .X3(X3),
        .Y(Y),
        .F(F)
    );
    
    initial
    begin
        X0 = 2'b00; X1 = 2'b01; X2 = 2'b10; X3 = 2'b11; Y = 2'b00; #200;
        X0 = 2'b00; X1 = 2'b01; X2 = 2'b10; X3 = 2'b11; Y = 2'b01; #200;
        X0 = 2'b00; X1 = 2'b01; X2 = 2'b10; X3 = 2'b11; Y = 2'b10; #200;
        X0 = 2'b00; X1 = 2'b01; X2 = 2'b10; X3 = 2'b11; Y = 2'b11; #200;
    end
endmodule
