`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/30 18:24:17
// Design Name: 
// Module Name: lab01_2
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


module lab01_2(
	input  [7:0] X,
	input  en,
	output reg valid,
	output [6:0] F,
	output reg [2:0] encoded_output,
	output [7:0] AN,
	output DP
	);
    
    assign AN = 8'b11111110;
    assign DP = 1'b1;
    wire [6:0] seg_code;
    bcd7seg seg_decoder(
        .b({1'b0, encoded_output}),
        .h(seg_code)
    );

    assign F = (en == 1'b0 || valid == 1'b0) ? 7'b1111111 : seg_code;

    always @(*) begin
        if (en == 1'b0) begin
            valid = 1'b0;
            encoded_output = 3'b000;
        end else begin
            case (1'b1)
                X[7]: begin valid = 1'b1; encoded_output = 3'b111; end
                X[6]: begin valid = 1'b1; encoded_output = 3'b110; end
                X[5]: begin valid = 1'b1; encoded_output = 3'b101; end
                X[4]: begin valid = 1'b1; encoded_output = 3'b100; end
                X[3]: begin valid = 1'b1; encoded_output = 3'b011; end
                X[2]: begin valid = 1'b1; encoded_output = 3'b010; end
                X[1]: begin valid = 1'b1; encoded_output = 3'b001; end
                X[0]: begin valid = 1'b1; encoded_output = 3'b000; end
                default: begin valid = 1'b0; encoded_output = 3'b000; end
            endcase
        end
    end
endmodule


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
            default: h = 7'b1111111;
        endcase
    end
endmodule
