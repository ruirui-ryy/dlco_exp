`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/04 10:28:36
// Design Name: 
// Module Name: lab06
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


module kbd_main(
    input clk,
    input clrn,
    input ps2_clk,
    input ps2_data,
    output reg key_pressed,
    output [7:0] ascii_key
);

// 内部信号定义
reg nextdata_n;
wire [7:0] keydata;
wire ready;
wire overflow;
reg [7:0] key_count;
reg [7:0] cur_key;
wire [7:0] ascii_key;
reg shift_pressed, caps_lock, alt_pressed, ctrl_pressed;

reg break_code = 0;  // 标记是否收到了断码
reg extend_code = 0; // 标记是否收到了扩展码 E0
reg read_flag = 0;   // 标记是否正在读取数据
reg key_pressed = 0;

// 特殊键扫描码定义
localparam SHIFT_LEFT = 8'h12;
localparam SHIFT_RIGHT = 8'h59;
localparam CTRL_LEFT = 8'h14;
localparam ALT_LEFT = 8'h11;
localparam CAPS_LOCK = 8'h58;

//----DO NOT CHANGE BEGIN----
// scancode to ascii conversion, will be initialized by the testbench
scancode_ram myram(clk, cur_key, shift_pressed, ctrl_pressed, alt_pressed, caps_lock, extend_code, ascii_key);

// PS2 interface, you may need to specify the inputs and outputs
ps2_keyboard mykey(clk, clrn, ps2_clk, ps2_data, keydata, ready, nextdata_n, overflow);
//---DO NOT CHANGE END-----

// 处理按键检测
always @(posedge clk or negedge clrn) begin
    if (!clrn) begin
        nextdata_n <= 1;
        key_count  <= 0;
        cur_key    <= 0;
        break_code <= 0;
        extend_code <= 0;
        read_flag  <= 0;
        key_pressed <= 0;
        shift_pressed <= 0;
        ctrl_pressed <= 0;
        alt_pressed <= 0;
        caps_lock <= 0;
    end else begin
        if (ready && !read_flag) begin
            nextdata_n <= 0;
            read_flag <= 1;
        end else if (read_flag) begin
            nextdata_n <= 1;
            read_flag <= 0;
            if (keydata == 8'hE0) begin
                // 收到扩展码前缀，只置位标志，不处理按键
                extend_code <= 1; 
            end else if (keydata == 8'hF0) begin
                // 收到断码
                break_code <= 1;
                cur_key <= 0;
                key_pressed <= 0;
            end else begin
                if (break_code) begin
                    // 断码后的按键码 - 处理特殊键释放
                    case (keydata)
                        SHIFT_LEFT, SHIFT_RIGHT: shift_pressed <= 0;
                        CTRL_LEFT: ctrl_pressed <= 0;
                        ALT_LEFT: alt_pressed <= 0;
                        // Caps Lock释放不改变状态
                    endcase
                    cur_key <= 0;
                    break_code <= 0;
                    extend_code <= 0;
                    key_pressed <= 0;
                end else begin
                    // 正常按键按下
                    case (keydata)
                        SHIFT_LEFT, SHIFT_RIGHT: begin
                            shift_pressed <= 1;
                            cur_key <= keydata;  // 显示Shift键码
                            key_pressed <= 0;
                        end
                        CTRL_LEFT: begin
                            ctrl_pressed <= 1;
                            cur_key <= keydata;  // 显示Ctrl键码
                            key_pressed <= 0;
                        end
                        ALT_LEFT: begin
                            alt_pressed <= 1;
                            cur_key <= keydata;  // 显示Alt键码
                            key_pressed <= 0;
                        end
                        CAPS_LOCK: begin
                            caps_lock <= ~caps_lock;  // 切换状态
                            cur_key <= keydata;       // 显示Caps Lock键码
                            key_pressed <= 0;
                        end
                        default: begin
                            if (extend_code) begin
                                case (keydata)
                                    8'h6B: cur_key <= 8'hF1; // Left Arrow (Mapped from E0 6B)
                                    8'h72: cur_key <= 8'hF2; // Down Arrow (Mapped from E0 72)
                                    8'h74: cur_key <= 8'hF3; // Right Arrow (Mapped from E0 74)
                                    8'h75: cur_key <= 8'hF4; // Up Arrow (Mapped from E0 75)
                                    default: cur_key <= keydata; // 其他扩展码（如 E0 14 右Ctrl）保持不变，继续走重叠逻辑
                                endcase
                            end else begin
                                // 普通字母数字键 
                                cur_key <= keydata;
                            end
                            if (!key_pressed) begin
                                key_count <= key_count + 1;
                                key_pressed <= 1;
                            end
                        end
                    endcase
                    extend_code <= 0;
                end
            end
        end else begin
            nextdata_n <= 1;
        end
    end
end

endmodule