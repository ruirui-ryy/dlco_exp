module lab11(
    input CLK100MHZ,
    input reset,
    input ps2_clk,
    input ps2_data,
    output hsync,
    output vsync,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output locked
    );
    
    // --- 1. 信号定义 ---
    // cursor_pos: 始终指向当前光标位置
    // 格式: {5位行号, 7位列号}
    reg [11:0] cursor_pos = 0; 
    
    // 显存写接口 
    reg [11:0] ram_write_addr;
    reg [7:0]  ram_write_data;
    reg ram_write_en = 0;
    
    // 键盘信号
    wire [7:0] kbd_data_wire;
    reg [7:0] kbd_data;
    wire kbd_pressed_wire;
    reg kbd_pressed;
    
    reg [6:0] last_non_empty_col [0:29];
    integer i;
    initial begin
        for (i = 0; i < 30; i = i + 1)
            last_non_empty_col[i] = 0;
    end
    
    // --- 2. 模块实例化 ---
    
    vga_main myvga(
        .CLK100MHZ(CLK100MHZ),
        .reset(reset),
        .ascii_addr(ram_write_addr),
        .ascii_din(ram_write_data),
        .ascii_wea(ram_write_en),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .locked(locked)
    );
        
    kbd_main mykbd(
        .clk(CLK100MHZ),
        .clrn(1'b1),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .key_pressed(kbd_pressed_wire),
        .ascii_key(kbd_data_wire)
    );
    
    always @(kbd_pressed_wire) begin kbd_pressed <= kbd_pressed_wire; end

    wire input_clk;
    clkgen myclk1(.clk(CLK100MHZ), .input_clk(input_clk));

    reg [6:0] clkcnt = 0;
    reg [6:0] delay = 2;
    reg [7:0] prekey = 0;
    reg repet = 0;
    
    // 常量
    localparam KEY_BS    = 8'h08;
    localparam KEY_ENTER = 8'h0A;
    localparam KEY_UP = 8'h81;
    localparam KEY_DOWN = 8'h82; 
    localparam KEY_LEFT = 8'h83;
    localparam KEY_RIGHT = 8'h84;
    
    // --- 3. 核心逻辑 ---
    always @(posedge input_clk) begin
        kbd_data <= kbd_data_wire;
        
        // 默认行为：不写显存
        ram_write_en <= 1'b0;
        
        // 关键：默认将写地址指向光标位置
        // 这样 vga_main 里的 getcol 才能读到正确的光标位置用于闪烁显示
        ram_write_addr <= cursor_pos; 
        ram_write_data <= 0;

        if (kbd_pressed == 0 || kbd_data == 0) begin 
            prekey <= 0;
            delay <= 2;
            clkcnt <= 0;
        end else begin
            if (kbd_data != prekey) begin delay <= 2; repet = 1; end
            
            if (clkcnt == delay) begin
                clkcnt <= 0;
                
                case (kbd_data)
                    // === Backspace (退格) ===
                    KEY_BS: begin   
                        // 情况A: 在行中间 (列号 > 0)
                        if (cursor_pos[6:0] > 0) begin
                            cursor_pos <= cursor_pos - 1;     // 简单减1
                            ram_write_addr <= cursor_pos - 1; // 擦除前一个位置
                            ram_write_data <= 8'h00;          // 写入空
                            ram_write_en <= 1'b1;
                            if (cursor_pos[6:0] - 1 == last_non_empty_col[cursor_pos[11:7]])
                                if (last_non_empty_col[cursor_pos[11:7]] > 0) 
                                    last_non_empty_col[cursor_pos[11:7]] <= last_non_empty_col[cursor_pos[11:7]] - 1;
                        end
                        // 情况B: 在行首 (列号 == 0)，且不在第一行
                        // 需要"逆向"原来的换行算法：回到上一行的第69列
                        else if (cursor_pos[11:7] > 0) begin
                            cursor_pos <= {cursor_pos[11:7] - 1, last_non_empty_col[cursor_pos[11:7] - 1]};
                            ram_write_addr <= {cursor_pos[11:7] - 1, last_non_empty_col[cursor_pos[11:7] - 1]};
                            ram_write_data <= 8'h00;
                            ram_write_en <= 1;
                        
                            if (last_non_empty_col[cursor_pos[11:7] - 1] > 0)
                                last_non_empty_col[cursor_pos[11:7] - 1] <= last_non_empty_col[cursor_pos[11:7] - 1] - 1;
                        end
                    end
                    
                    // === Enter (回车) ===
                    KEY_ENTER: begin
                        cursor_pos <= {cursor_pos[11:7] + 1, 7'b0};
                    end
                    
                    KEY_UP: cursor_pos <= (cursor_pos[11:7] > 0) ? {cursor_pos[11:7] - 1, cursor_pos[6:0]} : cursor_pos;
                    KEY_DOWN: cursor_pos <= {cursor_pos[11:7] + 1, cursor_pos[6:0]};
                    KEY_LEFT: begin
                        if (cursor_pos[6:0] > 0) cursor_pos <= cursor_pos - 1;
                        else if (cursor_pos[11:7] > 0) cursor_pos <= {cursor_pos[11:7] - 1, 7'd69};
                    end 
                    KEY_RIGHT: begin 
                        if (cursor_pos[6:0] <= 68) cursor_pos <= cursor_pos + 1;
                        else cursor_pos <= {cursor_pos[11:7] + 1, 7'b0};
                    end     
                    
                    // === 普通字符 ===
                    default: begin
                        if (kbd_data >= 32 && kbd_data <= 126) begin
                            // 1. 写显存 (在当前位置)
                            ram_write_addr <= cursor_pos;
                            ram_write_data <= kbd_data;
                            ram_write_en <= 1'b1;
                            
                            if (cursor_pos[6:0] > last_non_empty_col[cursor_pos[11:7]])
                            last_non_empty_col[cursor_pos[11:7]] <= cursor_pos[6:0];
                            
                            // 2. 移动光标 
                            if (cursor_pos[6:0] == 69) 
                                cursor_pos <= {cursor_pos[11:7] + 1, 7'b0};
                            else 
                                cursor_pos <= cursor_pos + 1; // 列号未满，简单+1
                        end
                    end 
                endcase
                
                if (delay == 40) delay <= 2;
                else if (repet) begin delay <= 40; repet = 0; end
                
            end else begin 
                clkcnt <= clkcnt + 1; 
            end
            prekey <= kbd_data;
        end
    end

endmodule

module clkgen(input clk, output reg input_clk = 0);
    reg [31:0] count = 0;
    always @(posedge clk) begin
        if (count == 499999) begin
            count <= 0; input_clk <= ~input_clk;
        end else count <= count + 1;
    end
endmodule