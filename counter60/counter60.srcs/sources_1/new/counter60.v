`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/11 19:09:18
// Design Name: 
// Module Name: counter60
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
///////////////////////////////////////////////
// ��Ƶ����100MHz �� 1Hz
///////////////////////////////////////////////
module clk_div(
    input clk,
    input [25:0] limit,
    output reg clk_d = 0   
);
    reg [25:0] cnt = 0;
    always @(posedge clk) begin
        if (cnt == limit - 1) begin 
            cnt <= 0;
            clk_d <= ~clk_d;      
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule

///////////////////////////////////////////////
// ���������00~59
///////////////////////////////////////////////
module counter60(
    input clk_1s,
    input start,           // ʹ��
    input rst,          // ����
    output reg [3:0] sec_ones, // ��λ
    output reg [3:0] sec_tens, // ʮλ
    output reg led_pulse       // 59��00ʱ��˸
);
    always @(posedge clk_1s or posedge rst) begin
        if (rst) begin
            sec_ones <= 0;
            sec_tens <= 0;
            led_pulse <= 0;
        end else if (start) begin
            if (sec_ones == 9) begin
                sec_ones <= 0;
                if (sec_tens == 5) begin
                    sec_tens <= 0;
                    led_pulse <= 1;
                end else begin
                    sec_tens <= sec_tens + 1;
                    led_pulse <= 0;
                end
            end else begin
                sec_ones <= sec_ones + 1;
                led_pulse <= 0;
            end
        end
    end
endmodule


///////////////////////////////////////////////
// BCD ת �߶������
///////////////////////////////////////////////
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

///////////////////////////////////////////////
// ����ģ�飺���Ϸ�Ƶ��+������+�����
///////////////////////////////////////////////
module top_timer(
    input CLK100MHZ,
    input sw_en,
    input btn_start,
    input btn_pause,
    input btn_reset,
    output reg [6:0] seg,
    output reg [7:0] an,
    output led
);
    wire clk_1s, clk_100ms, clk_1ms;
    wire [3:0] sec_ones, sec_tens;
    reg start;

    // 1s ʱ�� 1Hz
    clk_div u_1s (
        .clk(CLK100MHZ),
        .limit(50000000),
        .clk_d(clk_1s)
    );
    // 100ms ʱ�� 10Hz
    clk_div u_100ms (
        .clk(CLK100MHZ),
        .limit(5000000),
        .clk_d(clk_100ms)
    );
    clk_div u_1ms (
        .clk(CLK100MHZ),
        .limit(50000),
        .clk_d(clk_1ms)
    );
    
    // ��ť����
    always @(btn_start or btn_pause) begin
        if (btn_start) start = 1;
        else if (btn_pause) start = 0;
    end

    // ������
    counter60 u_cnt (
        .clk_1s(clk_1s),
        .start(start),
        .rst(btn_reset),
        .sec_ones(sec_ones),
        .sec_tens(sec_tens),
        .led_pulse(led)
    );

    // ����ܶ�̬ɨ��
    reg sel = 0;
    always @(posedge clk_1ms) begin
        sel <= ~sel;
    end

    wire [6:0] seg_ones, seg_tens;
    bcd7seg ones_disp(sec_ones, seg_ones);
    bcd7seg tens_disp(sec_tens, seg_tens); 
    always @(clk_100ms) begin
        if (~sw_en) begin
            an = 8'b11111111;
        end else begin
            if (sel == 0) begin
                an = 8'b11111110; // ��λ
                seg = seg_ones;
            end else begin
                an = 8'b11111101; // ʮλ
                seg = seg_tens;
            end
        end
    end
endmodule
