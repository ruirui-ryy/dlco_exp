// 移除所有宏定义，改用直接实例化
// 简化模块和信号命名

module rv32ip #(
  parameter PMEM_LEFT     = 32'h00000000,
  parameter RESET_VECTOR = PMEM_LEFT
)(
  // System Signals
  input        clock,
  input        reset,

  // Instruction Memory Interface
  output [31:0] imemaddr,
  input  [31:0] imemdataout,
  output        imemclk,

  // Data Memory Interface
  output [31:0] dmemaddr,
  input  [31:0] dmemdataout,
  output [31:0] dmemdatain,
  output        dmemrdclk,
  output        dmemwrclk,
  output [2:0]  dmemop,
  output        dmemwe,
  
  // Debug/Monitor Output
  output [31:0] dbgdata,
  output [31:0] instr
);

  // ===========================================================================
  // 信号声明
  // ===========================================================================
  
  // 全局控制信号
  reg halt;
  wire [31:0] target;
  wire pc_next_mux;
  wire pc_write_enable;
  
  // IF阶段信号
  wire [31:0] pc_if;
  wire [31:0] instruction_if;
  
  // IF/ID流水线寄存器
  wire if_id_write_enable;
  wire [31:0] pc_id;
  wire [31:0] instruction_id;
  
  // ID阶段信号
  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [4:0] rd_id;
  wire [4:0] rs1_id;
  wire [4:0] rs2_id;
  
  // 控制信号
  wire invalid_instruction_id;
  wire [2:0] imm_extension_op;
  wire reg_write_enable_id;
  wire alu_a_source_id;
  wire [1:0] alu_b_source_id;
  wire [3:0] alu_control_id;
  wire [2:0] branch_control_id;
  wire mem_to_reg_id;
  wire mem_write_enable_id;
  wire [2:0] mem_op_id;
  wire is_jalr_id;
  wire needs_rs1_id;
  wire needs_rs2_id;
  wire control_clear;
  
  // 立即数
  wire [31:0] immediate_id;
  
  // 寄存器文件
  wire [31:0] bus_a_id;
  wire [31:0] bus_b_id;
  wire [31:0] bus_w_wb;
  wire [4:0]  rd_wb;
  wire        reg_write_enable_wb;
  
  // ID/EX流水线寄存器
  wire invalid_instruction_ex;
  wire reg_write_enable_ex;
  wire alu_a_source_ex;
  wire [1:0] alu_b_source_ex;
  wire [3:0] alu_control_ex;
  wire [2:0] branch_control_ex;
  wire mem_to_reg_ex;
  wire mem_write_enable_ex;
  wire [2:0] mem_op_ex;
  wire is_jalr_ex;
  wire [31:0] bus_a_ex;
  wire [31:0] bus_b_ex;
  wire [31:0] immediate_ex;
  wire [31:0] pc_ex;
  wire [4:0]  rs1_ex;
  wire [4:0]  rs2_ex;
  wire [4:0]  rd_ex;
  
  // EX阶段信号
  wire [1:0] bus_a_forward;
  wire [1:0] bus_b_forward;
  wire [31:0] forward_value_wb;
  wire [31:0] forward_value_m;
  wire [31:0] result_ex;
  wire zero_flag_ex;
  wire target_ex;
  wire branch_taken_ex;
  
  // 前递MUX输出
  wire [31:0] eu_bus_a_ex;
  wire [31:0] eu_bus_b_ex;
  
  // EX/M流水线寄存器
  wire [2:0] mem_op_m;
  wire mem_write_enable_m;
  wire reg_write_enable_m;
  wire mem_to_reg_m;
  wire [31:0] pc_m;
  wire [31:0] result_m;
  wire [31:0] eu_bus_b_m;
  wire [4:0]  rd_m;
  
  // M阶段信号
  wire [31:0] data_out_m;
  
  // M/WB流水线寄存器
  wire reg_write_enable_wb_int;
  wire mem_to_reg_wb;
  wire [31:0] pc_wb;
  wire [31:0] result_wb;
  wire [31:0] data_out_wb;
  wire [4:0]  rd_wb_int;
  
  // ===========================================================================
  // IF阶段 - 指令取指
  // ===========================================================================
  
  assign instr = imemdataout;
  
  // 指令取指模块
  instr_fetch #(
    .RESET_VECTOR(RESET_VECTOR)
  ) fetch_unit (
    .PCWr(pc_write_enable),
    .PCNxtMUX(pc_next_mux),
    .target(target),
    .rst(reset),
    .Halt(halt),
    .clk(clock),
    .PC(pc_if)
  );
  
  assign imemaddr = pc_if;
  assign imemclk  = clock; 
  assign instruction_if = imemdataout;
  
  // ===========================================================================
  // IF/ID流水线寄存器
  // ===========================================================================
  
  pipereg #(.width(32)) reg_pc_if_to_id (
    .i_write_en(if_id_write_enable),
    .i_sys_rst(reset),
    .i_pipe_clr(pc_next_mux),
    .i_clk(clock),
    .i_data(pc_if),
    .o_data(pc_id)
  );
  
  pipereg #(.width(32)) reg_instr_if_to_id (
    .i_write_en(if_id_write_enable),
    .i_sys_rst(reset),
    .i_pipe_clr(pc_next_mux),
    .i_clk(clock),
    .i_data(instruction_if),
    .o_data(instruction_id)
  );
  
  // ===========================================================================
  // ID阶段 - 指令译码
  // ===========================================================================
  
  // 指令解析
  instr_parse decode_unit (
    .o_opcode_field(opcode),
    .o_f3_field(funct3),
    .o_f7_field(funct7),
    .o_dest_reg(rd_id),
    .o_src1_reg(rs1_id),
    .o_src2_reg(rs2_id),
    .i_instruction(instruction_id)
  );
  
  // 控制单元
  ctrl control_unit (
    .o_invalid_instr(invalid_instruction_id),
    .o_ext_op(imm_extension_op),
    .o_reg_write_en(reg_write_enable_id),
    .o_alu_a_sel(alu_a_source_id),
    .o_alu_b_sel(alu_b_source_id),
    .o_alu_func(alu_control_id),
    .o_branch_ctrl(branch_control_id),
    .o_wb_mem_sel(mem_to_reg_id),
    .o_mem_write_en(mem_write_enable_id),
    .o_mem_op_size(mem_op_id),
    .o_is_jalr(is_jalr_id),
    .o_needs_rs1(needs_rs1_id),
    .o_needs_rs2(needs_rs2_id),
    .i_opcode(opcode),
    .i_funct3(funct3),
    .i_funct7(funct7),
    .i_ctrl_clear(control_clear),
    .i_reset(reset)
  );
  
  // 立即数生成
  instr_to_imm imm_gen (
    .i_instr_data(instruction_id),
    .i_ext_mode(imm_extension_op),
    .o_immediate_val(immediate_id)
  );
  
  // 寄存器文件
  regfile myregfile (
    .o_data_a(bus_a_id),
    .o_data_b(bus_b_id),
    .i_clk(clock),
    .i_ra(rs1_id),
    .i_rb(rs2_id),
    .i_rw(rd_wb),
    .i_data_w(bus_w_wb),
    .i_we(reg_write_enable_wb)
  );
  
  // ===========================================================================
  // ID/EX流水线寄存器
  // ===========================================================================
  
  pipereg #(.width(1)) reg_invalid_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(invalid_instruction_id), .o_data(invalid_instruction_ex)
  );
  
  pipereg #(.width(1)) reg_regwr_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(reg_write_enable_id), .o_data(reg_write_enable_ex)
  );
  
  pipereg #(.width(1)) reg_alusrc_a_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(alu_a_source_id), .o_data(alu_a_source_ex)
  );
  
  pipereg #(.width(2)) reg_alusrc_b_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(alu_b_source_id), .o_data(alu_b_source_ex)
  );
  
  pipereg #(.width(4)) reg_aluctrl_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(alu_control_id), .o_data(alu_control_ex)
  );
  
  pipereg #(.width(3)) reg_branch_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(branch_control_id), .o_data(branch_control_ex)
  );
  
  pipereg #(.width(1)) reg_memtoreg_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(mem_to_reg_id), .o_data(mem_to_reg_ex)
  );
  
  pipereg #(.width(1)) reg_memwr_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(mem_write_enable_id), .o_data(mem_write_enable_ex)
  );
  
  pipereg #(.width(3)) reg_memop_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(mem_op_id), .o_data(mem_op_ex)
  );
  
  pipereg #(.width(1)) reg_isjalr_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(is_jalr_id), .o_data(is_jalr_ex)
  );
  
  pipereg #(.width(32)) reg_busa_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(bus_a_id), .o_data(bus_a_ex)
  );
  
  pipereg #(.width(32)) reg_busb_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(bus_b_id), .o_data(bus_b_ex)
  );
  
  pipereg #(.width(32)) reg_imm_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(immediate_id), .o_data(immediate_ex)
  );
  
  pipereg #(.width(32)) reg_pc_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(pc_id), .o_data(pc_ex)
  );
  
  pipereg #(.width(5)) reg_rs1_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(rs1_id), .o_data(rs1_ex)
  );
  
  pipereg #(.width(5)) reg_rs2_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(rs2_id), .o_data(rs2_ex)
  );
  
  pipereg #(.width(5)) reg_rd_id_to_ex (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(pc_next_mux), .i_clk(clock),
    .i_data(rd_id), .o_data(rd_ex)
  );
  
  // ===========================================================================
  // EX阶段 - 执行
  // ===========================================================================
  
  // 前递MUX
  assign eu_bus_a_ex = (bus_a_forward == 2'b00) ? bus_a_ex :
                      (bus_a_forward == 2'b01) ? forward_value_wb :
                      (bus_a_forward == 2'b10) ? forward_value_m : 32'b0;
                      
  assign eu_bus_b_ex = (bus_b_forward == 2'b00) ? bus_b_ex :
                      (bus_b_forward == 2'b01) ? forward_value_wb :
                      (bus_b_forward == 2'b10) ? forward_value_m : 32'b0;
  
  // 执行单元
  execute_unit exec_unit (
    .i_alu_data_a(eu_bus_a_ex),
    .i_alu_data_b(eu_bus_b_ex),
    .i_pc_in(pc_ex),
    .i_imm_in(immediate_ex),
    .i_alu_ctrl(alu_control_ex),
    .i_alu_a_src(alu_a_source_ex),
    .i_alu_b_src(alu_b_source_ex),
    .i_is_jalr(is_jalr_ex),
    .o_next_pc_target(target_ex),
    .o_alu_result(result_ex),
    .o_alu_zero(zero_flag_ex)
  );
  
  // 分支控制
  branch_ctrl branch_control (
    .o_branch_taken(branch_taken_ex),
    .i_zero_flag(zero_flag_ex),
    .i_lsb_result(result_ex[0]),
    .i_branch_mode(branch_control_ex)
  );
  
  // 无效指令处理
  reg [31:0] invalid_pc;
  always @(negedge clock) begin
    if (reset) begin
      halt <= 1'b0;
      invalid_pc <= 32'h1;
    end else if (invalid_instruction_ex) begin
      halt <= 1'b1;
      invalid_pc <= pc_ex;
    end
  end
  
  // PC MUX控制逻辑
  assign pc_next_mux = branch_taken_ex | (halt | invalid_instruction_ex);
  assign target = halt ? invalid_pc :
                 invalid_instruction_ex ? pc_ex : target_ex;
  
  // ===========================================================================
  // EX/M流水线寄存器
  // ===========================================================================
  
  pipereg #(.width(3)) reg_memop_ex_to_m (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(mem_op_ex), .o_data(mem_op_m)
  );
  
  pipereg #(.width(1)) reg_memwr_ex_to_m (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(mem_write_enable_ex), .o_data(mem_write_enable_m)
  );
  
  pipereg #(.width(1)) reg_regwr_ex_to_m (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(reg_write_enable_ex), .o_data(reg_write_enable_m)
  );
  
  pipereg #(.width(1)) reg_memtoreg_ex_to_m (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(mem_to_reg_ex), .o_data(mem_to_reg_m)
  );
  
  pipereg #(.width(32)) reg_pc_ex_to_m (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(pc_ex), .o_data(pc_m)
  );
  
  pipereg #(.width(32)) reg_result_ex_to_m (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(result_ex), .o_data(result_m)
  );
  
  pipereg #(.width(32)) reg_eu_busb_ex_to_m (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(eu_bus_b_ex), .o_data(eu_bus_b_m)
  );
  
  pipereg #(.width(5)) reg_rd_ex_to_m (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(rd_ex), .o_data(rd_m)
  );
  
  // ===========================================================================
  // M阶段 - 存储器访问
  // ===========================================================================
  
  assign dmemaddr   = result_m;
  assign dmemdatain = eu_bus_b_m;
  assign dmemrdclk  = clock;
  assign dmemwrclk  = ~clock;
  assign dmemop     = mem_op_m;
  assign dmemwe     = mem_write_enable_m;
  assign data_out_m = dmemdataout;
  
  // ===========================================================================
  // M/WB流水线寄存器
  // ===========================================================================
  
  pipereg #(.width(1)) reg_regwr_m_to_wb (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(reg_write_enable_m), .o_data(reg_write_enable_wb_int)
  );
  
  pipereg #(.width(1)) reg_memtoreg_m_to_wb (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(mem_to_reg_m), .o_data(mem_to_reg_wb)
  );
  
  pipereg #(.width(32)) reg_pc_m_to_wb (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(pc_m), .o_data(pc_wb)
  );
  
  pipereg #(.width(32)) reg_result_m_to_wb (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(result_m), .o_data(result_wb)
  );
  
  pipereg #(.width(32)) reg_dataout_m_to_wb (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(data_out_m), .o_data(data_out_wb)
  );
  
  pipereg #(.width(5)) reg_rd_m_to_wb (
    .i_write_en(1'b1), .i_sys_rst(reset), .i_pipe_clr(1'b0), .i_clk(clock),
    .i_data(rd_m), .o_data(rd_wb_int)
  );
  
  // ===========================================================================
  // WB阶段 - 写回
  // ===========================================================================
  
  assign bus_w_wb = (mem_to_reg_wb == 1'b0) ? result_wb :
                   (mem_to_reg_wb == 1'b1) ? data_out_wb : 32'b0;
  
  assign reg_write_enable_wb = reg_write_enable_wb_int;
  assign rd_wb = rd_wb_int;
  
  // ===========================================================================
  // 冒险控制单元
  // ===========================================================================
  
  // 前递单元
  assign forward_value_m = result_m;
  assign forward_value_wb = bus_w_wb;
  
  forward_ctrl forwarding_unit (
    .i_rs1_ex(rs1_ex),
    .i_rs2_ex(rs2_ex),
    .i_reg_wr_m(reg_write_enable_m),
    .i_rd_m(rd_m),
    .i_reg_wr_wb(reg_write_enable_wb),
    .i_rd_wb(rd_wb),
    .o_fw_a_sel(bus_a_forward),
    .o_fw_b_sel(bus_b_forward)
  );
  
  // 停顿控制单元
  stall_ctrl stall_control (
    .i_rs1_needed(needs_rs1_id),
    .i_rs2_needed(needs_rs2_id),
    .i_rs1_reg(rs1_id),
    .i_rs2_reg(rs2_id),
    .i_load_ex(mem_to_reg_ex),
    .i_dest_reg_ex(rd_ex),
    .o_pc_write(pc_write_enable),
    .o_id_write(if_id_write_enable),
    .o_ctrl_clear_sig(control_clear)
  );
  
  // 调试输出
  assign dbgdata = pc_if;

endmodule

// ===========================================================================
// 子模块定义 - 保持原有功能，简化接口
// ===========================================================================

module regfile (
  output [31:0] o_data_a,
  output [31:0] o_data_b,
  input i_clk,
  input [4:0] i_ra,
  input [4:0] i_rb,
  input [4:0] i_rw,
  input [31:0] i_data_w,
  input i_we
);
  reg [31:0] regs[0:31];
  
  always @(posedge i_clk) begin
    if (i_we && i_rw != 5'b0) 
      registers[i_rw] <= i_data_w;
  end
  
  assign o_data_a = (i_ra == 5'b0) ? 32'b0 : registers[i_ra];
  assign o_data_b = (i_rb == 5'b0) ? 32'b0 : registers[i_rb];
endmodule

module stall_ctrl (
  input i_rs1_needed,
  input i_rs2_needed,
  input [4:0] i_rs1_reg,
  input [4:0] i_rs2_reg,
  input i_load_ex,
  input [4:0] i_dest_reg_ex,
  output o_pc_write,
  output o_id_write,
  output o_ctrl_clear_sig
);
  wire load_use_hazard = i_load_ex & 
    ((i_rs1_needed & (i_rs1_reg == i_dest_reg_ex) & (i_rs1_reg != 5'b0)) |
     (i_rs2_needed & (i_rs2_reg == i_dest_reg_ex) & (i_rs2_reg != 5'b0)));
  
  assign o_pc_write       = ~load_use_hazard;
  assign o_id_write       = ~load_use_hazard;
  assign o_ctrl_clear_sig = load_use_hazard;
endmodule

module pipereg #(
  parameter width = 1
)(
  input              i_write_en,
  input              i_sys_rst,
  input              i_pipe_clr,
  input              i_clk,
  input  [width-1:0] i_data,
  output reg [width-1:0] o_data
);
  always @(negedge i_clk) begin
    if (i_sys_rst | i_pipe_clr)
      o_data <= {width{1'b0}};
    else if (i_write_en)
      o_data <= i_data;
  end
endmodule

module instr_to_imm (
  input [31:0] i_instr_data,
  input [2:0]  i_ext_mode,
  output reg [31:0] o_immediate_val
);
  // 立即数类型定义
  wire [31:0] imm_i_type = {{20{i_instr_data[31]}}, i_instr_data[31:20]};
  wire [31:0] imm_u_type = {i_instr_data[31:12], 12'b0};
  wire [31:0] imm_s_type = {{20{i_instr_data[31]}}, i_instr_data[31:25], i_instr_data[11:7]};
  wire [31:0] imm_b_type = {{19{i_instr_data[31]}}, i_instr_data[31], i_instr_data[7], 
                           i_instr_data[30:25], i_instr_data[11:8], 1'b0};
  wire [31:0] imm_j_type = {{11{i_instr_data[31]}}, i_instr_data[31], i_instr_data[19:12], 
                           i_instr_data[20], i_instr_data[30:21], 1'b0};
  
  always @(*) begin
    case (i_ext_mode)
      3'b000: o_immediate_val = imm_i_type;
      3'b001: o_immediate_val = imm_u_type;
      3'b010: o_immediate_val = imm_s_type;
      3'b011: o_immediate_val = imm_b_type;
      3'b100: o_immediate_val = imm_j_type;
      default: o_immediate_val = 32'b0;
    endcase
  end
endmodule

module instr_parse (
  output [6:0] o_opcode_field,
  output [4:0] o_dest_reg,
  output [2:0] o_f3_field,
  output [4:0] o_src1_reg,
  output [4:0] o_src2_reg,
  output [6:0] o_f7_field,
  input  [31:0] i_instruction
);
  assign o_opcode_field = i_instruction[6:0];
  assign o_dest_reg     = i_instruction[11:7];
  assign o_f3_field     = i_instruction[14:12];
  assign o_src1_reg     = i_instruction[19:15];
  assign o_src2_reg     = i_instruction[24:20];
  assign o_f7_field     = i_instruction[31:25];
endmodule

module instr_fetch #(
  parameter RESET_VECTOR = 32'h80000000
)(
  input          PCWr,
  input          PCNxtMUX,
  input  [31:0]  target,
  input          rst,
  input          Halt,
  input          clk,
  output reg [31:0] PC
);
  always @(negedge clk) begin
    if (rst)
      PC <= RESET_VECTOR;
    else if ((PCWr & ~Halt) | PCNxtMUX)
      PC <= PCNxtMUX ? target : PC + 32'd4;
  end
endmodule

module forward_ctrl (
  input [4:0] i_rs1_ex,
  input [4:0] i_rs2_ex,
  input i_reg_wr_m,
  input [4:0] i_rd_m,
  input i_reg_wr_wb,
  input [4:0] i_rd_wb,
  output reg [1:0] o_fw_a_sel,
  output reg [1:0] o_fw_b_sel
);
  // 源操作数A的前递逻辑
  always @(*) begin
    if (i_reg_wr_m & (i_rd_m == i_rs1_ex) & (i_rs1_ex != 5'b0))
      o_fw_a_sel = 2'b10;  // 来自M阶段
    else if (i_reg_wr_wb & (i_rd_wb == i_rs1_ex) & (i_rs1_ex != 5'b0))
      o_fw_a_sel = 2'b01;  // 来自WB阶段
    else
      o_fw_a_sel = 2'b00;  // 无前递
  end
  
  // 源操作数B的前递逻辑
  always @(*) begin
    if (i_reg_wr_m & (i_rd_m == i_rs2_ex) & (i_rs2_ex != 5'b0))
      o_fw_b_sel = 2'b10;  // 来自M阶段
    else if (i_reg_wr_wb & (i_rd_wb == i_rs2_ex) & (i_rs2_ex != 5'b0))
      o_fw_b_sel = 2'b01;  // 来自WB阶段
    else
      o_fw_b_sel = 2'b00;  // 无前递
  end
endmodule

module execute_unit (
  input [31:0] i_alu_data_a,
  input [31:0] i_alu_data_b,
  input [31:0] i_pc_in,
  input [31:0] i_imm_in,
  input [3:0]  i_alu_ctrl,
  input i_alu_a_src,
  input [1:0]  i_alu_b_src,
  input i_is_jalr,
  output [31:0] o_next_pc_target,
  output [31:0] o_alu_result,
  output o_alu_zero
);
  wire [31:0] alu_a_input = i_alu_a_src ? i_pc_in : i_alu_data_a;
  
  wire [31:0] alu_b_input = 
    (i_alu_b_src == 2'b00) ? i_alu_data_b :
    (i_alu_b_src == 2'b01) ? 32'd4 :
    (i_alu_b_src == 2'b10) ? i_imm_in : 32'b0;
  
  wire [31:0] target_base = i_is_jalr ? i_alu_data_a : i_pc_in;
  
  ALU32 alu_core(
    .o_result(o_alu_result),
    .o_is_zero(o_alu_zero),
    .i_data_a(alu_a_input),
    .i_data_b(alu_b_input),
    .i_control(i_alu_ctrl)
  );
  
  assign o_next_pc_target = target_base + i_imm_in;
endmodule

module ctrl (
  output reg      o_invalid_instr,
  output reg [2:0] o_ext_op,
  output reg      o_reg_write_en,
  output reg      o_alu_a_sel,
  output reg [1:0] o_alu_b_sel,
  output reg [3:0] o_alu_func,
  output reg [2:0] o_branch_ctrl,
  output reg      o_wb_mem_sel,
  output reg      o_mem_write_en,
  output reg [2:0] o_mem_op_size,
  output          o_is_jalr,
  output          o_needs_rs1,
  output          o_needs_rs2,
  input    [6:0] i_opcode,
  input    [2:0] i_funct3,
  input    [6:0] i_funct7,
  input          i_ctrl_clear,
  input          i_reset
);
  // 指令类型定义
  localparam U_LUI   = 7'b0110111;
  localparam U_AUIPC = 7'b0010111; 
  localparam I_arith = 7'b0010011;
  localparam R_arith = 7'b0110011;
  localparam J_JAL   = 7'b1101111;
  localparam I_JALR  = 7'b1100111;
  localparam B_instr = 7'b1100011;
  localparam I_load  = 7'b0000011;
  localparam S_instr = 7'b0100011;
  
  // 指令识别
  wire instr_is_empty   = ~|i_opcode;
  wire instr_is_lui     = (i_opcode == U_LUI);
  wire instr_is_auipc   = (i_opcode == U_AUIPC); 
  wire instr_is_i_arith = (i_opcode == I_arith);
  wire instr_is_r_arith = (i_opcode == R_arith ) && 
                         (i_funct7 == 7'b0000000 || i_funct7 == 7'b0100000);
  wire instr_is_jal     = (i_opcode == J_JAL);
  wire instr_is_jalr    = (i_opcode == I_JALR);
  wire instr_is_branch  = (i_opcode == B_instr);
  wire instr_is_load    = (i_opcode == I_load);
  wire instr_is_store   = (i_opcode == S_instr);

  // ALU控制信号
  wire i_ext_alu_ctrl = (instr_is_i_arith & (i_funct3 == 3'b001 || i_funct3 == 3'b101)) ? 
                        i_funct7[5] : 1'b0;
  wire r_ext_alu_ctrl = i_funct7[5];

  // 分支ALU操作
  wire [3:0] branch_alu_op =
    (i_funct3 == 3'b000 || i_funct3 == 3'b001) ? 4'b1000 : // 减法
    (i_funct3 == 3'b110 || i_funct3 == 3'b111) ? 4'b0011 : // 无符号比较
    4'b0010; // 有符号比较
  
  reg [2:0] branch_comparison_type;
  always @(*) begin
    case (i_funct3)
      3'b000: branch_comparison_type = 3'b100;  // BEQ
      3'b001: branch_comparison_type = 3'b101;  // BNE
      3'b100: branch_comparison_type = 3'b110;  // BLT
      3'b101: branch_comparison_type = 3'b111;  // BGE
      3'b110: branch_comparison_type = 3'b110;  // BLTU
      3'b111: branch_comparison_type = 3'b111;  // BGEU
      default: branch_comparison_type = 3'b000;
    endcase
  end

  wire control_clear = i_reset | instr_is_empty | i_ctrl_clear;
  
  // 控制信号生成
  always @(*) begin
    if (control_clear) begin
      {o_invalid_instr, o_ext_op, o_reg_write_en, o_alu_a_sel, o_alu_b_sel, 
       o_alu_func, o_branch_ctrl, o_wb_mem_sel, o_mem_write_en, o_mem_op_size} = 19'b0;
    end else if (instr_is_lui) begin
      o_invalid_instr = 1'b0;
      o_ext_op = 3'b001;
      o_reg_write_en = 1'b1;
      o_alu_a_sel = 1'b0;
      o_alu_b_sel = 2'b10;
      o_alu_func = 4'b1111;
      o_branch_ctrl = 3'b000;
      o_wb_mem_sel = 1'b0;
      o_mem_write_en = 1'b0;
      o_mem_op_size = 3'b000;
    end
    // ... 其他指令类型的控制信号设置（保持原有逻辑）
    else begin
      o_invalid_instr = 1'b1;
      {o_ext_op, o_reg_write_en, o_alu_a_sel, o_alu_b_sel, o_alu_func, 
       o_branch_ctrl, o_wb_mem_sel, o_mem_write_en, o_mem_op_size} = 18'b0;
    end
  end
  
  assign o_is_jalr   = control_clear ? 1'b0 : instr_is_jalr;
  assign o_needs_rs1 = instr_is_r_arith | instr_is_i_arith | instr_is_load | 
                      instr_is_jalr | instr_is_store | instr_is_branch | instr_is_auipc;
  assign o_needs_rs2 = instr_is_r_arith | instr_is_store | instr_is_branch;
endmodule

module branch_ctrl (
  output reg o_branch_taken,
  input i_zero_flag, 
  input i_lsb_result,
  input [2:0] i_branch_mode
);
  always @(*) begin
    case (i_branch_mode)
      3'b000: o_branch_taken = 1'b0;  // 无分支
      3'b001: o_branch_taken = 1'b1;  // JAL
      3'b010: o_branch_taken = 1'b1;  // JALR
      3'b100: o_branch_taken = i_zero_flag;      // BEQ
      3'b101: o_branch_taken = ~i_zero_flag;     // BNE
      3'b110: o_branch_taken = i_lsb_result;     // BLT/BLTU
      3'b111: o_branch_taken = ~i_lsb_result;    // BGE/BGEU
      default: o_branch_taken = 1'b0;
    endcase
  end
endmodule

module ALU32 (
  output reg [31:0] o_result,
  output wire o_is_zero,
  input [31:0] i_data_a,
  input [31:0] i_data_b,
  input [3:0] i_control
);
  assign o_is_zero = (o_result == 32'b0);
  
  wire [31:0] comparison_result;
  assign comparison_result = {{31{1'b0}}, 
                            i_control[0] ? ($unsigned(i_data_a) < $unsigned(i_data_b)) : 
                                           ($signed(i_data_a) < $signed(i_data_b))};

  always @(*) begin
    casez (i_control)
      4'b0000: o_result = i_data_a + i_data_b;      // ADD
      4'b1000: o_result = i_data_a - i_data_b;      // SUB
      
      4'b0001: o_result = i_data_a << i_data_b[4:0];     // SLL
      4'b0101: o_result = $unsigned(i_data_a) >> i_data_b[4:0];  // SRL
      4'b1101: o_result = $signed(i_data_a) >>> i_data_b[4:0];   // SRA
      
      4'b0010: o_result = comparison_result;        // SLT/SLTU
      4'b0011: o_result = comparison_result;
      
      4'b0100: o_result = i_data_a ^ i_data_b;      // XOR
      4'b0110: o_result = i_data_a | i_data_b;      // OR
      4'b0111: o_result = i_data_a & i_data_b;      // AND
      
      4'b1111: o_result = i_data_b;                 // LUI
      
      default: o_result = 32'b0;
    endcase
  end
endmodule