`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/13 17:40:18
// Design Name: 
// Module Name: digital_clock
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

module debounce(
    input wire inp,
    input wire clk,
    input wire clr,
    output outp
);
    reg delay1;
    reg delay2;
    reg [19:0] count = 0;
    reg clk_20ms;
    always @( posedge clk or negedge clr)
        if (!clr) begin
            count <= 20'd0;
            clk_20ms <= 1'b0;
        end else if (count == 20'hfffff) begin
            clk_20ms <= ~clk_20ms;
            count <= 20'd0;
        end else begin
            count <= count + 1'b1;
        end
    always @( posedge clk_20ms or negedge clr)
        if (!clr) begin
            delay1 <= 1'b0;
            delay2 <= 1'b0;
        end else begin
           delay1 <= inp;
           delay2 <= delay1;
        end
    assign outp = delay1 & delay2;
endmodule
 
///////////////////////////////////////////////
// 分频器：100MHz → 1Hz
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
// 秒(分)计数器：00~59
///////////////////////////////////////////////
module counter60(
    input clk_1s,
    input start,           // 使能
    input rst,          // 清零
    output reg [3:0] sec_ones, // 个位
    output reg [3:0] sec_tens, // 十位
    output reg led_pulse       // 59→00时闪烁
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
// 小时计数器
///////////////////////////////////////////////
module counter24(
    input clk_1h,
    input rst,          // 清零
    output reg [3:0] hour_ones, // 个位
    output reg [3:0] hour_tens, // 十位
    output reg led_pulse       // 23→00时闪烁
);
    always @(posedge clk_1h or posedge rst) begin
        if (rst) begin
            hour_ones <= 0;
            hour_tens <= 0;
            led_pulse <= 0;
        end else begin
            if (hour_ones == 9) begin
                hour_ones <= 0;
                hour_tens <= hour_tens + 1;
            end else if (hour_tens == 2 && hour_ones == 3) begin
                hour_tens <= 0;
                hour_ones <= 0;
                led_pulse <= 1;
            end else begin
                hour_ones <= hour_ones + 1;
            end
        end
    end
endmodule

///////////////////////////////////////////////
// BCD 转 七段数码管
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
// 顶层模块：整合分频器+计数器+数码管
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
    wire clk_1s, clk_100ms, clk_10ms, clk_1ms;
    // 1s 时钟 1Hz
    clk_div u_1s (
        .clk(CLK100MHZ),
        .limit(50000000),
        .clk_d(clk_1s)
    );
    // 100ms 时钟 10Hz
    clk_div u_100ms (
        .clk(CLK100MHZ),
        .limit(5000000),
        .clk_d(clk_100ms)
    );
    // 10ms 100Hz
    clk_div u_10ms (
        .clk(CLK100MHZ),
        .limit(500000),
        .clk_d(clk_10ms)
    );
    // 1ms 1kHz
    clk_div u_1ms (
        .clk(CLK100MHZ),
        .limit(50000),
        .clk_d(clk_1ms)
    );
    
    // 按钮控制
    reg start = 0;
    wire btn_start_db;
    debounce u_db_start (
        .inp(btn_start),
        .clk(CLK100MHZ), 
        .clr(1'b1),
        .outp(btn_start_db)
    );
    reg start_reg = 0;
    always @(posedge clk_1ms) begin
        start_reg <= btn_start_db;
        if (btn_start_db && ~start_reg) begin
            start <= ~start;
        end
    end

    // 秒
    wire [3:0] sec_ones, sec_tens;
    wire sec_carry;
    counter60 u_sec (
        .clk_1s(clk_1s),
        .start(start),
        .rst(btn_reset),
        .sec_ones(sec_ones),
        .sec_tens(sec_tens),
        .led_pulse (sec_carry)
    );
    // 分
    wire [3:0] min_ones, min_tens;
    wire min_carry;
    counter60 u_min (
        .clk_1s(sec_carry),
        .start(1),
        .rst(btn_reset),
        .sec_ones(min_ones),
        .sec_tens(min_tens),
        .led_pulse(min_carry)
    );
    // 时
    wire [3:0] hour_ones, hour_tens;
    counter24 u_hour(
        .clk_1h(min_carry),
        .rst(btn_reset),
        .hour_ones(hour_ones),
        .hour_tens(hour_tens),
        .led_pulse(led)
    );
            
    // 数码管动态扫描
    reg [2:0] sel = 0;
    always @(posedge clk_1ms) begin
        sel <= sel + 1;
    end

    // 数码管显示
    wire [6:0] sec0, sec1, min0, min1, hour0, hour1;
    bcd7seg sec0_disp(sec_ones, sec0);
    bcd7seg sec1_disp(sec_tens, sec1);
    bcd7seg min0_disp(min_ones, min0);
    bcd7seg min1_disp(min_tens, min1);
    bcd7seg hour0_disp(hour_ones, hour0);
    bcd7seg hour1_disp(hour_tens, hour1); 
    always @(clk_1ms) begin
        if (~sw_en) begin
            an = 8'b11111111;
        end else begin
            case (sel)
                3'd0: begin an = 8'b11111110; seg = sec0; end
                3'd1: begin an = 8'b11111101; seg = sec1; end
                3'd2: begin an = 8'b11111011; seg = min0; end
                3'd3: begin an = 8'b11110111; seg = min1; end
                3'd4: begin an = 8'b11101111; seg = hour0; end
                3'd5: begin an = 8'b11011111; seg = hour1; end
                default: begin an = 8'b11111111; seg = 7'b1111111; end
            endcase
        end
    end
endmodule
