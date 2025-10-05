`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/04 21:10:17
// Design Name: 
// Module Name: scan2ascii
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


module scan2ascii(
    input [7:0] scan,
    input shift,
    output reg [7:0] ascii,
    output reg valid
);
    always @(*) begin
        valid = 1'b1;
        ascii = 8'h00;
        case (scan)
            // letters
            8'h1C: ascii = shift ? "A" : "a";
            8'h32: ascii = shift ? "B" : "b";
            8'h21: ascii = shift ? "C" : "c";
            8'h23: ascii = shift ? "D" : "d";
            8'h24: ascii = shift ? "E" : "e";
            8'h2B: ascii = shift ? "F" : "f";
            8'h34: ascii = shift ? "G" : "g";
            8'h33: ascii = shift ? "H" : "h";
            8'h43: ascii = shift ? "I" : "i";
            8'h3B: ascii = shift ? "J" : "j";
            8'h42: ascii = shift ? "K" : "k";
            8'h4B: ascii = shift ? "L" : "l";
            8'h3A: ascii = shift ? "M" : "m";
            8'h31: ascii = shift ? "N" : "n";
            8'h44: ascii = shift ? "O" : "o";
            8'h4D: ascii = shift ? "P" : "p";
            8'h15: ascii = shift ? "Q" : "q";
            8'h2D: ascii = shift ? "R" : "r";
            8'h1B: ascii = shift ? "S" : "s";
            8'h2C: ascii = shift ? "T" : "t";
            8'h3C: ascii = shift ? "U" : "u";
            8'h2A: ascii = shift ? "V" : "v";
            8'h1D: ascii = shift ? "W" : "w";
            8'h22: ascii = shift ? "X" : "x";
            8'h35: ascii = shift ? "Y" : "y";
            8'h1A: ascii = shift ? "Z" : "z";
            // numbers top row
            8'h16: ascii = shift ? "!" : "1";
            8'h1E: ascii = shift ? "@" : "2";
            8'h26: ascii = shift ? "#" : "3";
            8'h25: ascii = shift ? "$" : "4";
            8'h2E: ascii = shift ? "%" : "5";
            8'h36: ascii = shift ? "^" : "6";
            8'h3D: ascii = shift ? "&" : "7";
            8'h3E: ascii = shift ? "*" : "8";
            8'h46: ascii = shift ? "(" : "9";
            8'h45: ascii = shift ? ")" : "0";
            8'h29: ascii = 8'h20; // space
            8'h5A: ascii = 8'h0D; // Enter -> CR
            8'h0D: ascii = shift ? "~" : "`";
            8'h4E: ascii = shift ? "_" : "-";
            8'h55: ascii = shift ? "+" : "=";
            8'h54: ascii = shift ? "{" : "[";
            8'h5B: ascii = shift ? "}" : "]";
            8'h4C: ascii = shift ? ":" : ";";
            8'h52: ascii = shift ? "\"" : "\'";
            8'h41: ascii = shift ? "<" : ",";
            8'h49: ascii = shift ? ">" : ".";
            8'h4A: ascii = shift ? "?" : "/";
            8'h5D: ascii = shift ? "|" : "\\";
            default: begin
                valid = 1'b0;
                ascii = 8'h00;
            end
        endcase
    end
endmodule
