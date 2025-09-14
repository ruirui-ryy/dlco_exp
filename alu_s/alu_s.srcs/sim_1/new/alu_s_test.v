`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/03 17:44:07
// Design Name: 
// Module Name: alu_s_test
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


module alu_s_test(

    );
    reg [3:0] A, B;
    reg [2:0] ALUctr;
    wire [3:0] F;
    wire cf, zero, of;
    wire [6:0] seg;
    wire [7:0] AN;
    wire DP;
    
    alu_s i0 (
        .A(A),
        .B(B),
        .ALUctr(ALUctr),
        .F(F),
        .cf(cf),
        .zero(zero),
        .of(of),
        .seg(seg),
        .AN(AN),
        .DP(DP)
    );

    
    initial
    begin
        A = 4'd3; B = 4'd2; ALUctr = 3'd0; #20; // A+B
        A = 4'd3; B = 4'd2; ALUctr = 3'd1; #20; // A-B
        A = 4'd5; B = 4'd7; ALUctr = 3'd1; #20; // A-B (负数)
        A = 4'd6; B = 4'd9; ALUctr = 3'd2; #20; // ~A
        A = 4'd12; B = 4'd10; ALUctr = 3'd3; #20; // A AND B = 1000
        A = 4'd12; B = 4'd10; ALUctr = 3'd4; #20; // A OR B = 1110
        A = 4'd12; B = 4'd10; ALUctr = 3'd5; #20; // A XOR B = 0110
        A = 4'd2; B = 4'd7; ALUctr = 3'd6; #20; // 比较 A<B
        A = 4'd7; B = 4'd7; ALUctr = 3'd7; #20; // 相等判断
    end
endmodule
