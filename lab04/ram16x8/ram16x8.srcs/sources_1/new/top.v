`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/20 16:44:02
// Design Name: 
// Module Name: top
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


module top(
    input CLK100MHZ,
    input clk,
    input we,
    input wr_sel,
    input [3:0] wrdata,
    input [3:0] addr,
    output reg [7:0] seg,
    output reg [7:0] AN
    );
    wire [7:0] reg_in, ram_in, outa, outb, douta;
    wire regwr, ramwr;
    assign reg_in = {4'b0000, wrdata};
    assign ram_in = {4'b1111, wrdata};
    assign regwr = (we && wr_sel == 0);
    assign ramwr = (we && wr_sel == 1);
    
    // 实例化 
    reg16x8 u_reg (
        .ra(addr),
        .rb(0),
        .rw(addr),
        .wrdata(reg_in),
        .regwr(regwr),
        .wrclk(clk),
        .outa(outa),
        .outb(outb)
    );
    blk_mem_gen_0 u_ram (
       .addra(addr),
       .clka(clk),
       .dina(ram_in),
       .douta(douta),
       .ena(1),
       .wea(ramwr)
    );
     
    // 数码管显示 
    wire [7:0] rega0, rega1, rama0, rama1;
    bcd7seg u_rega0 (.b(outa[3:0]), .h(rega0));
    bcd7seg u_rega1 (.b(outa[7:4]), .h(rega1));
    bcd7seg u_rama0 (.b(douta[3:0]), .h(rama0));
    bcd7seg u_rama1 (.b(douta[7:4]), .h(rama1));
    reg [1:0] sel = 0;
    reg [16:0] cnt = 0;
    always @(posedge CLK100MHZ) begin
        if (cnt == 99999) begin
            cnt <= 0;
            sel <= sel + 1;
        end else begin 
            cnt <= cnt + 1;
        end
    end
    
    always @(*) begin 
        case (sel) 
            2'd0: begin AN = 8'b11111110; seg = rega0; end 
            2'd1: begin AN = 8'b11111101; seg = rega1; end 
            2'd2: begin AN = 8'b11111011; seg = rama0; end 
            2'd3: begin AN = 8'b11110111; seg = rama1; end
        endcase
    end 
endmodule
