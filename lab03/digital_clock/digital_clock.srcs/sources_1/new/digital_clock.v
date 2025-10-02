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
    input clk_fast,
    input clk_1s,
    input start, // 使能
    input rst, // 清零
    input up,
    output [3:0] sec_ones, // 个位
    output [3:0] sec_tens, // 十位
    output reg led_pulse // 59→00时闪烁
);
    reg up_d1, up_d2;
    reg up_pressed;
    always @(posedge clk_fast or posedge rst) begin
        if (rst) begin
            up_d1 <= 0;
            up_d2 <= 0;
            up_pressed <= 0;
        end else begin
            up_d1 <= up;
            up_d2 <= up_d1;
            up_pressed <= up_d1 & ~up_d2; // 检测上升沿
        end
    end
    
    reg [6:0] sec;
    always @(posedge clk_1s or posedge rst or posedge up_pressed) begin
        if (rst) begin
            sec <= 0;
            led_pulse <= 0;
        end else if (up_pressed) begin
            sec <= (sec == 59) ? 0 : sec + 1;
            led_pulse <= (sec == 59) ? 1 : 0;
        end else if (start) begin
            if (sec == 59) begin
            sec <= 0;
            led_pulse <= 1;
        end else begin
            sec <= sec + 1;
            led_pulse <= 0;
        end
    end
end
    assign sec_ones = sec % 10;
    assign sec_tens = sec / 10;
endmodule


///////////////////////////////////////////////
// 小时计数器
///////////////////////////////////////////////
module counter24(
    input clk_1h,
    input rst,          // 清零
    input up,
    output [3:0] hour_ones, // 个位
    output [3:0] hour_tens, // 十位
    output reg led_pulse       // 23→00时闪烁
);
    reg [4:0] hour;
    always @(posedge clk_1h or posedge rst or posedge up) begin
        if (rst) begin
            hour <= 0;
            led_pulse <= 0;
        end else if (up) begin
            hour <= (hour == 23) ? 0 : hour + 1;
        end else begin
            if (hour == 23) begin
                hour <= 0;
                led_pulse <= 1;
            end else begin
                hour <= hour + 1;
                led_pulse <= 0;
            end
        end
    end
    assign hour_ones = hour % 10;
    assign hour_tens = hour / 10;
endmodule 

module counter100(
    input clk_10ms,
    input start,
    input rst,
    output reg [3:0] cs_ones,
    output reg [3:0] cs_tens,
    output reg cs_carry
);
    always @(posedge clk_10ms or posedge rst) begin
        if (rst) begin
            cs_ones <= 0;
            cs_tens <= 0;
            cs_carry <= 0;
        end else if (start) begin
            if (cs_ones == 9) begin
                cs_ones <= 0;
                if (cs_tens == 9) begin
                    cs_tens <= 0;
                    cs_carry <= 1;
                end else begin
                    cs_tens <= cs_tens + 1;
                    cs_carry <= 0;
                end
            end else begin
                cs_ones <= cs_ones + 1;
                cs_carry <= 0;
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
    input btn_mode,
    input btn_adj,
    input btn_up,
    input btn_reset,
    output reg [6:0] seg,
    output reg [7:0] an,
    output led
);
    wire clk_1s, clk_500ms, clk_100ms, clk_10ms, clk_1ms;
    // 1s 时钟 1Hz
    clk_div u_1s (
        .clk(CLK100MHZ),
        .limit(50000000),
        .clk_d(clk_1s)
    );
    // 0.5s 500ms 2Hz
    clk_div u_500ms (
        .clk(CLK100MHZ),
        .limit(25000000),
        .clk_d(clk_500ms)
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
    
    // 按钮消抖
    wire btn_start_db, btn_mode_db, btn_adj_db, btn_up_db, btn_reset_db;
    debounce u_db_start (.inp(btn_start),.clk(CLK100MHZ),.clr(1'b1),.outp(btn_start_db));
    debounce u_db_mode (.inp(btn_mode),.clk(CLK100MHZ),.clr(1'b1),.outp(btn_mode_db));
    debounce u_db_adj (.inp(btn_adj),.clk(CLK100MHZ),.clr(1'b1),.outp(btn_adj_db));
    debounce u_db_up (.inp(btn_up),.clk(CLK100MHZ),.clr(1'b1),.outp(btn_up_db));
    debounce u_db_reset (.inp(btn_reset),.clk(CLK100MHZ),.clr(1'b1),.outp(btn_reset_db));
   
    // 模式按钮
    reg [1:0] mode = 0;
    reg mode_reg = 0;
    always @(posedge clk_1ms) begin
        mode_reg <= btn_mode_db;
        if (btn_mode_db && ~mode_reg) begin
            if (mode == 2'd0) begin mode <= 1; end
            else if (mode == 2'd1) begin mode <= 2; end
            else if (mode == 2'd2) begin mode <= 0; end
        end
    end
    
    // 调整按钮
    reg [1:0] adj = 0;
    reg adj_reg = 0;
    always @(posedge clk_1ms) begin
        adj_reg <= btn_adj_db;
        if (btn_adj_db && ~adj_reg) begin
            adj <= adj + 1;
        end
    end
    
    // 开始按钮 & 调整时间按钮
    reg start = 0, up = 0;
    reg start_reg = 0;
    always @(posedge clk_1ms) begin
        start_reg <= btn_start_db;
        if (btn_start_db && ~start_reg) begin
            if (adj == 0) begin start <= ~start; end
            else begin up <= 1; end
        end else if (~btn_start_db && start_reg) begin
            up <= 0;
        end
    end
    
    // 
             
    // 时间逻辑 
    wire btn_sec_up = (btn_up_db && adj == 2'd3);
    wire btn_min_up = (btn_up_db && adj == 2'd2);
    wire btn_hour_up = (btn_up_db && adj == 2'd1);
    // 秒
    wire [3:0] sec_ones, sec_tens;
    wire sec_carry;
    counter60 u_sec (
        .clk_fast(CLK100MHZ),
        .clk_1s(clk_1s),
        .start(start),
        .rst(btn_reset),
        .up(btn_sec_up),
        .sec_ones(sec_ones),
        .sec_tens(sec_tens),
        .led_pulse (sec_carry)
    );
    // 分
    wire [3:0] min_ones, min_tens;
    wire min_carry;
    counter60 u_min (
        .clk_fast(CLK100MHZ),
        .clk_1s(sec_carry),
        .start(1),
        .rst(btn_reset),
        .up(btn_min_up),
        .sec_ones(min_ones),
        .sec_tens(min_tens),
        .led_pulse(min_carry)
    );
    // 时
    wire [3:0] hour_ones, hour_tens;
    counter24 u_hour(
        .clk_1h(min_carry),
        .rst(btn_reset),
        .up(btn_hour_up),
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
    always @(*) begin
        if (~sw_en) begin
            an = 8'b11111111;
        end else begin
            if (mode == 0) begin
                case (sel)
                    3'd0: begin an = 8'b11111110; seg = (clk_500ms && adj == 3) ? 8'b11111111 : sec0; end
                    3'd1: begin an = 8'b11111101; seg = (clk_500ms && adj == 3) ? 8'b11111111 : sec1; end
                    3'd2: begin an = 8'b11111011; seg = (clk_500ms && adj == 2) ? 8'b11111111 : min0; end
                    3'd3: begin an = 8'b11110111; seg = (clk_500ms && adj == 2) ? 8'b11111111 : min1; end
                    3'd4: begin an = 8'b11101111; seg = (clk_500ms && adj == 1) ? 8'b11111111 : hour0; end
                    3'd5: begin an = 8'b11011111; seg = (clk_500ms && adj == 1) ? 8'b11111111 : hour1; end
                    default: begin an = 8'b11111111; seg = 7'b1111111; end
                endcase
            end
        end
    end
endmodule
