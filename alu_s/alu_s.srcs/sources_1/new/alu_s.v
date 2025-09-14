`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/03 17:05:45
// Design Name: 
// Module Name: alu_s
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


module alu_s( input [3:0] A,
			  input [3:0] B,
			  input [2:0] ALUctr,
			  output reg [3:0] F,
			  output reg cf,
			  output reg zero,
			  output reg of,
			  output [6:0] seg,
			  output [7:0] AN,
			  output DP
);
    assign AN = 8'b11111110;
    assign DP = 1'b1;
    wire [3:0] a_F;
    wire a_cf, a_zero, a_of;
    wire less;
    adder a_adder(
        .A(A),
        .B(B),
        .addsub(|ALUctr),
        .F(a_F),
        .cf(a_cf),
        .zero(a_zero),
        .of(a_of)
    );
    assign less = a_F[3] ^ a_of;

    always@(*)
    begin
    case(ALUctr)
        3'd0: begin F = a_F; cf = a_cf; zero = a_zero; of = a_of; end
        3'd1: begin F = a_F; cf = a_cf; zero = a_zero; of = a_of; end
        3'd2: begin F = ~A; cf = 1'b0; zero = !(|F); of = 1'b0; end
        3'd3: begin F = A&B; cf = 1'b0; zero = !(|F); of = 1'b0; end
        3'd4: begin F = A|B; cf = 1'b0; zero = !(|F); of = 1'b0; end
        3'd5: begin F = A^B; cf = 1'b0; zero = !(|F); of = 1'b0; end
        3'd6: begin F = less ? 4'b0001 : 4'b0000;
                    cf = 1'b0; zero = !(|F); of = 1'b0; end
        3'd7: begin F = a_zero ? 4'b0001 : 4'b0000;
                    cf = 1'b0; zero = !(|F); of = 1'b0; end
    endcase
    end
    
    bcd7seg bcd (
        .b(F),
        .h(seg)
    );

endmodule

module adder(
	input  [3:0] A,
	input  [3:0] B,
	input  addsub,
	output [3:0] F,
	output cf,
	output zero,
	output of
	);

    wire [3:0] b_in;
    wire carry;
    assign b_in = B ^ {4{addsub}};
    assign {carry, F} = A + b_in + {3'b0, addsub}; 
    assign cf = carry ^ addsub;
    assign of = (A[3] == (B[3] ^ addsub)) & (F[3] != A[3]);
    assign zero = (F == 4'b0);

endmodule

// Æß¶ÎÊýÂë¹Ü
module bcd7seg(
	 input  [3:0] b,
	 output reg [6:0] h
	 );

    always @(*) begin
        case (b)
            4'd0: h = 7'b1000000;
            4'd1: h = 7'b1111001;
            4'd2: h = 7'b0100100;
            4'd3: h = 7'b0110000;
            4'd4: h = 7'b0011001;
            4'd5: h = 7'b0010010;
            4'd6: h = 7'b0000010;
            4'd7: h = 7'b1111000;
            4'd8: h = 7'b0000000;
            4'd9: h = 7'b0010000;
            4'ha: h = 7'b0001000;
            4'hb: h = 7'b0000011; 
            4'hc: h = 7'b1000110; 
            4'hd: h = 7'b0100001; 
            4'he: h = 7'b0000110; 
            4'hf: h = 7'b0001110; 
            default: h = 7'b1111111;
        endcase
    end
endmodule