`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/01 23:46:23
// Design Name: 
// Module Name: alu
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


module alu(
	input [31:0] dataa,
	input [31:0] datab,
	input [3:0]  ALUctr,
	output less,
	output zero,
	output reg [31:0] aluresult);

    wire [31:0] F;
    wire cf, of, zero_adder;
    wire less_sign;
    adder a_adder(
        .A(dataa),
        .B(datab),
        .addsub(|ALUctr),
        .F(F),
        .cf(cf),
        .zero(zero_adder),
        .of(of)
    );
    assign less_sign = F[31] ^ of;
    wire less_unsign = cf;

    wire [4:0] shamt = datab[4:0];
    
    always @(*) begin
        case (ALUctr) 
            4'b0000: aluresult = dataa + datab;
            4'b1000: aluresult = dataa - datab;
            4'b0001: aluresult = dataa << shamt;
            4'b1001: aluresult = dataa << shamt;
            4'b0010: aluresult = {31'b0, less_sign};
            4'b1010: aluresult = {31'b0, less_unsign};
            4'b0011: aluresult = datab;
            4'b1011: aluresult = datab;
            4'b0100: aluresult = dataa ^ datab;
            4'b1100: aluresult = dataa ^ datab;
            4'b0101: aluresult = dataa >> shamt;
            4'b1101: aluresult = (dataa >> shamt) | ({32{dataa[31]}} << (32 - shamt));
            4'b0110: aluresult = dataa | datab;
            4'b1110: aluresult = dataa | datab;
            4'b0111: aluresult = dataa & datab;
            4'b1111: aluresult = dataa & datab;
            default: aluresult = 32'b0;
        endcase
    end

    assign zero = (ALUctr[2:0] == 3'b010) ? (dataa == datab) : (aluresult == 32'b0);
    assign less = (ALUctr == 4'b0010) ? less_sign :       
                  (ALUctr == 4'b1010) ? less_unsign : 1'b0;

endmodule

module adder(
	input  [31:0] A,
	input  [31:0] B,
	input  addsub,
	output [31:0] F,
	output cf,
	output zero,
	output of
	);

    wire [31:0] b_in;
    wire carry;
    assign b_in = B ^ {32{addsub}};
    assign {carry, F} = A + b_in + {31'b0, addsub}; 
    assign cf = carry ^ addsub;
    assign of = (A[31] == (B[31] ^ addsub)) & (F[31] != A[31]);
    assign zero = (F == 32'b0);

endmodule
