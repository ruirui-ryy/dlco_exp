`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/27 20:39:20
// Design Name: 
// Module Name: mylab0_test
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


module mylab0_test(
    
    );
    reg A;
    reg B;
    wire F;
    
    mylab0 i1 (
        .A(A),
        .B(B),
        .F(F)
    );
    initial
    begin
        A = 1'b0; B = 1'b0; #200;
        A = 1'b0; B = 1'b1; #200;
        A = 1'b1; B = 1'b0; #200;
        A = 1'b1; B = 1'b1; #200;
        A = 1'b0; B = 1'b0; #200;
    end
endmodule
