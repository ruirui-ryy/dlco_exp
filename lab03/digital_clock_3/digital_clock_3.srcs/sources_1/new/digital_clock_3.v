`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/16 16:13:31
// Design Name: 
// Module Name: digital_clock_3
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


module digital_clock_3(
    input CLK100MHZ,
    input sw_en,
    input btn_rst,
    input btn_add,
    input btn_adj,
    input btn_mode,
    input btn_clock,
    output reg [7:0] seg,
    output reg [7:0] AN,
    output reg led
    );
    
    // 复位按钮 
    wire clock_rst = (btn_rst && mode == 0);
    wire stopwatch_rst = (btn_rst && mode == 1);
    
    // 调整按钮
    reg [1:0] adj = 0;
    reg adj_reg = 0;
    always @(posedge CLK100MHZ) begin
        adj_reg <= btn_adj;
        if (btn_adj && ~adj_reg) begin
            adj <= adj + 1;
        end
    end
    
    // 模式按钮
    reg mode = 0;
    reg mode_reg = 0;
    always @(posedge CLK100MHZ) begin
        mode_reg <= btn_mode;
        if (btn_mode && ~mode_reg) begin
            mode <= ~mode;
        end
    end
    
    // 闹钟按钮
    reg [1:0] clock = 0;
    reg clock_reg = 0;
    always @(posedge CLK100MHZ) begin
        clock_reg <= btn_clock;
        if (btn_clock && ~clock_reg) begin
            clock <= clock + 1;
        end
    end
    
    
    // 时间脉冲
    wire sec_pulse, min_pulse, hour_pulse, day_pulse, cs_pulse;
    clk_pulse u_1s_pulse(.CLK100MHZ(CLK100MHZ),.in_pulse(1),.limit(100000000),.out_pulse(sec_pulse));
    clk_pulse u_1cs_pulse(.CLK100MHZ(CLK100MHZ),.in_pulse(1),.limit(1000000),.out_pulse(cs_pulse));
    
    // 时钟逻辑 
    wire [3:0] sec_ones, sec_tens, min_ones, min_tens, hour_ones, hour_tens;
    wire add_hour = (adj == 1 && btn_add); 
    wire add_min = (adj == 2 && btn_add); 
    wire add_sec = (adj == 3 && btn_add); 
    timer u_sec(.CLK100MHZ(CLK100MHZ),.en(sec_pulse),.limit(60),.rst(clock_rst),.add(add_sec),.ones(sec_ones),.tens(sec_tens),.carry(min_pulse));
    timer u_min(.CLK100MHZ(CLK100MHZ),.en(min_pulse),.limit(60),.rst(clock_rst),.add(add_min),.ones(min_ones),.tens(min_tens),.carry(hour_pulse));
    timer u_hour(.CLK100MHZ(CLK100MHZ),.en(hour_pulse),.limit(24),.rst(clock_rst),.add(add_hour),.ones(hour_ones),.tens(hour_tens),.carry(day_pulse));
    
    // 闹钟逻辑 
    wire fk0, fk1, fk2;
    wire [3:0] c_sec_ones, c_sec_tens, c_min_ones, c_min_tens, c_hour_ones, c_hour_tens;
    wire c_add_hour = (clock == 1 && btn_add); 
    wire c_add_min = (clock == 2 && btn_add); 
    wire c_add_sec = (clock == 3 && btn_add); 
    timer u_c_sec(.CLK100MHZ(CLK100MHZ),.en(0),.limit(60),.rst(clock_rst),.add(c_add_sec),.ones(c_sec_ones),.tens(c_sec_tens),.carry(fk0));
    timer u_c_min(.CLK100MHZ(CLK100MHZ),.en(0),.limit(60),.rst(clock_rst),.add(c_add_min),.ones(c_min_ones),.tens(c_min_tens),.carry(fk1));
    timer u_c_hour(.CLK100MHZ(CLK100MHZ),.en(0),.limit(24),.rst(clock_rst),.add(c_add_hour),.ones(c_hour_ones),.tens(c_hour_tens),.carry(fk2));
    
    // 秒表逻辑 
    wire [3:0] w_min_ones, w_min_tens, w_sec_ones, w_sec_tens, w_cs_ones, w_cs_tens;
    wire btn_start = (mode == 1 && btn_add);
    reg start = 0;
    reg start_reg = 0;
    always @(posedge CLK100MHZ) begin
        start_reg <= btn_start;
        if (btn_start && ~start_reg) begin
            start <= ~start;
        end
    end
    wire w_sec_pulse, w_min_pulse, w_hour_pulse;
    wire cs_en = start && cs_pulse;
    wire sec_en = start && w_sec_pulse;
    wire min_en = start && w_min_pulse;
    timer u_w_cs(.CLK100MHZ(CLK100MHZ),.en(cs_en),.limit(100),.rst(stopwatch_rst),.add(0),.ones(w_cs_ones),.tens(w_cs_tens),.carry(w_sec_pulse));
    timer u_w_sec(.CLK100MHZ(CLK100MHZ),.en(sec_en),.limit(60),.rst(stopwatch_rst),.add(0),.ones(w_sec_ones),.tens(w_sec_tens),.carry(w_min_pulse));
    timer u_w_min(.CLK100MHZ(CLK100MHZ),.en(min_en),.limit(60),.rst(stopwatch_rst),.add(0),.ones(w_min_ones),.tens(w_min_tens),.carry(w_hour_pulse));
    
    // 时钟方波 
    wire clk_1s, clk_500ms, clk_1ms;
    clk_div u_1s (.clk(CLK100MHZ),.limit(50000000),.clk_d(clk_1s));
    clk_div u_500ms (.clk(CLK100MHZ),.limit(25000000),.clk_d(clk_500ms));
    clk_div u_1ms (.clk(CLK100MHZ),.limit(50000),.clk_d(clk_1ms));
    
    // 数码管动态扫描
    reg [2:0] sel = 0;
    always @(posedge clk_1ms) begin
        sel <= sel + 1;
    end
    // 数码管显示
    wire [7:0] sec0, sec1, min0, min1, hour0, hour1;
    bcd7seg sec0_disp(sec_ones, sec0);
    bcd7seg sec1_disp(sec_tens, sec1);
    bcd7seg min0_disp(min_ones, min0);
    bcd7seg min1_disp(min_tens, min1);
    bcd7seg hour0_disp(hour_ones, hour0);
    bcd7seg hour1_disp(hour_tens, hour1); 
    wire [7:0] c_sec0, c_sec1, c_min0, c_min1, c_hour0, c_hour1;
    bcd7seg c_sec0_disp(c_sec_ones, c_sec0);
    bcd7seg c_sec1_disp(c_sec_tens, c_sec1);
    bcd7seg c_min0_disp(c_min_ones, c_min0);
    bcd7seg c_min1_disp(c_min_tens, c_min1);
    bcd7seg c_hour0_disp(c_hour_ones, c_hour0);
    bcd7seg c_hour1_disp(c_hour_tens, c_hour1); 
    wire [7:0] w_cs0, w_cs1, w_sec0, w_sec1, w_min0, w_min1;
    bcd7seg w_cs0_disp(w_cs_ones, w_cs0);
    bcd7seg w_cs1_disp(w_cs_tens, w_cs1);
    bcd7seg w_sec0_disp(w_sec_ones, w_sec0);
    bcd7seg w_sec1_disp(w_sec_tens, w_sec1);
    bcd7seg w_min0_disp(w_min_ones, w_min0);
    bcd7seg w_min1_disp(w_min_tens, w_min1); 
    
    // 显示逻辑
    always @(*) begin
        led = (sec0 == c_sec0 && sec1 == c_sec1 && min0 == c_min0 && min1 == c_min1 && hour0 == c_hour0 && hour1 == c_hour1);
        if (~sw_en) begin
            AN = 8'b11111111;
        end else begin
            if (mode == 0) begin
                if (clock == 0) begin
                    case (sel)
                        3'd0: begin AN = 8'b11111110; seg = (clk_500ms && adj == 3) ? 8'b11111111 : sec0; end
                        3'd1: begin AN = 8'b11111101; seg = (clk_500ms && adj == 3) ? 8'b11111111 : sec1; end
                        3'd2: begin AN = 8'b11111011; seg = (clk_500ms && adj == 2) ? 8'b11111111 : min0; end
                        3'd3: begin AN = 8'b11110111; seg = (clk_500ms && adj == 2) ? 8'b11111111 : min1; end
                        3'd4: begin AN = 8'b11101111; seg = (clk_500ms && adj == 1) ? 8'b11111111 : hour0; end
                        3'd5: begin AN = 8'b11011111; seg = (clk_500ms && adj == 1) ? 8'b11111111 : hour1; end
                        default: begin AN = 8'b11111111; seg = 8'b11111111; end
                    endcase
                end else begin // clock != 0 
                    case (sel)
                        3'd0: begin AN = 8'b11111110; seg = (clk_500ms && clock == 3) ? 8'b11111111 : c_sec0; end
                        3'd1: begin AN = 8'b11111101; seg = (clk_500ms && clock == 3) ? 8'b11111111 : c_sec1; end
                        3'd2: begin AN = 8'b11111011; seg = (clk_500ms && clock == 2) ? 8'b11111111 : c_min0; end
                        3'd3: begin AN = 8'b11110111; seg = (clk_500ms && clock == 2) ? 8'b11111111 : c_min1; end
                        3'd4: begin AN = 8'b11101111; seg = (clk_500ms && clock == 1) ? 8'b11111111 : c_hour0; end
                        3'd5: begin AN = 8'b11011111; seg = (clk_500ms && clock == 1) ? 8'b11111111 : c_hour1; end
                        default: begin AN = 8'b11111111; seg = 8'b11111111; end
                    endcase
                end
            end else begin // mode == 1 
                case (sel)
                    3'd0: begin AN = 8'b11111110; seg = w_cs0; end
                    3'd1: begin AN = 8'b11111101; seg = w_cs1; end
                    3'd2: begin AN = 8'b11111011; seg = w_sec0; end
                    3'd3: begin AN = 8'b11110111; seg = w_sec1; end
                    3'd4: begin AN = 8'b11101111; seg = w_min0; end
                    3'd5: begin AN = 8'b11011111; seg = w_min1; end
                    default: begin AN = 8'b11111111; seg = 8'b11111111; end
                endcase
            end
        end
    end
endmodule
