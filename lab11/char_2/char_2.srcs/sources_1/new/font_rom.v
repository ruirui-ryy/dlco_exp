`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/18 11:07:00
// Design Name: 
// Module Name: font_rom
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


module font_rom(
    input         clka,
    input         ena,
    input  [11:0] addra,   // {ascii_code, pixel_row[3:0]}
    output reg [11:0] douta
);

    reg [11:0] mem [0:4095];

    initial begin
        $readmemh("vga_font.mem", mem);
    end

    always @(posedge clka) begin
        if (ena)
            douta <= mem[addra];
    end

endmodule
