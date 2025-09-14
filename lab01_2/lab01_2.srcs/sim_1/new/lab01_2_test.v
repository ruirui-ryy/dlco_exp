`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/30 18:29:55
// Design Name: 
// Module Name: lab01_2_test
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


module lab01_2_test;

    reg [7:0] X;
    reg en;
    wire valid;
    wire [6:0] F;
    wire [2:0] encoded_output;
    wire [7:0] AN;
    wire DP;

    lab01_2 i0 (
        .X(X),
        .en(en),
        .valid(valid),
        .F(F),
        .encoded_output(encoded_output),
        .AN(AN),
        .DP(DP)
    );


    initial
    begin
        X = 8'b0000000; en = 1'b0; #200;
        en = 1'b1; X = 8'b00000000; #200;
        X = 8'b00000001; #200;
        X = 8'b00001000; #200;
        X = 8'b10000000; #200;
        X = 8'b00100010; #200;
        en = 1'b0; X = 8'b00100010; #200;
    end
endmodule

