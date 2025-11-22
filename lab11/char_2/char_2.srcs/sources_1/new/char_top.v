module char_top(
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
    
    reg [11:0] ascii_addr = 0;
    wire [7:0] ascii_din_wire;
    reg [7:0] ascii_din;
    reg ascii_wea = 0;
    wire kbd_pressed_wire;
    reg kbd_pressed;
    
    vga_main myvga(
        .CLK100MHZ(CLK100MHZ),
        .reset(reset),
        .ascii_addr(cur_addr),
        .ascii_din(ascii_din),
        .ascii_wea(ascii_wea),
        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .locked(locked));
        
    kbd_main mykbd(
        .clk(CLK100MHZ),
        .clrn(1'b1),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .key_pressed(kbd_pressed_wire),
        .ascii_key(ascii_din_wire));
    always @(kbd_pressed_wire) begin kbd_pressed <= kbd_pressed_wire; end
//    always @(ascii_din_wire) begin ascii_din <= ascii_din_wire; end
    
    wire input_clk;
    clkgen myclk1(.clk(CLK100MHZ), .input_clk(input_clk));
    reg [11:0] cur_addr;
    reg [6:0] clkcnt = 0;
    reg [6:0] delay = 2;
    reg [7:0] prekey = 0;
    reg repet = 0;
    
    always @(posedge input_clk) begin
//    always @(posedge ps2_clk) begin
        ascii_din <= ascii_din_wire;
        cur_addr <= ascii_addr;
        if (kbd_pressed == 0 || ascii_din == 0) begin 
            ascii_wea <= 1'b0;
            prekey <= 0;
            delay <= 2;
            clkcnt <= 0;
        end else begin
            if (ascii_din == 10) ascii_wea <= 1'b0;
            else ascii_wea <= 1'b1;
            if (ascii_din != prekey) begin delay <= 2; repet = 1; end
            if (clkcnt == delay) begin
                clkcnt <= 0;
                if (ascii_addr[6:0] == 69 || ascii_din == 10)
                    ascii_addr <= {ascii_addr[11:7] + 1, 7'b0};
                else ascii_addr <= ascii_addr + 1;
                if (delay == 40) delay <= 2;
                else if (repet) begin delay <= 40; repet = 0; end
            end else begin clkcnt <= clkcnt + 1; ascii_wea <= 1'b0; end
            prekey <= ascii_din;
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