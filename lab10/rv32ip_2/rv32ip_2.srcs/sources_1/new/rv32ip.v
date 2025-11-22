`define PIPE_CONNECT(P_Origin, P_Dest, P_Width, P_BaseName, P_WriteEnable, P_ClearStall) \
  pipereg #(.width(P_Width)) reg_``P_BaseName``_to_``P_Dest ( \
    .i_write_en(P_WriteEnable), .i_sys_rst(reset), .i_pipe_clr(P_ClearStall), .i_clk(clock), \
    .i_data(P_BaseName``_``P_Origin), .o_data(P_BaseName``_``P_Dest) \
  );

// Define Wire and connect Pipeline Register Macro
`define DEF_PIPE_CONNECT(P_Origin, P_Dest, P_Width, P_BaseName, P_WriteEnable, P_ClearStall) \
  wire [P_Width-1:0] P_BaseName``_``P_Dest; \
  `PIPE_CONNECT(P_Origin, P_Dest, P_Width, P_BaseName, P_WriteEnable, P_ClearStall)

// Control Signal Values Macro for 'ctrl' module
`define CONTROL_SET_VALUES(is_invalid, imm_op, wr_reg, alu_a_src, alu_b_src, alu_op, branch_type, mem_to_reg, wr_mem, mem_access_op) \
  begin\
    o_invalid_instr = is_invalid;\
    o_ext_op = imm_op;\
    o_reg_write_en = wr_reg;\
    o_alu_a_sel = alu_a_src;\
    o_alu_b_sel = alu_b_src;\
    o_alu_func = alu_op;\
    o_branch_ctrl = branch_type;\
    o_wb_mem_sel = mem_to_reg;\
    o_mem_write_en = wr_mem;\
    o_mem_op_size = mem_access_op;\
  end

module rv32ip #(
  parameter PMEM_LEFT    = 32'h00000000,
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

  // General Status Register
  reg halt;
  assign instr = imemdataout;

  // Global Control Wires
  wire [31:0] target;     // Next PC target address
  wire        PCNxtMUX;   // MUX for PC next value (PC+4 vs target)
  wire        PCWr;       // PC Write Enable

  // ---------------------------------------------------------------------------
  // IF (Instruction Fetch) Stage Wires and Logic
  // ---------------------------------------------------------------------------
  wire [31:0] PC_IF;
  wire [31:0] instr_IF;

  // Internal wire names for instr_fetch module ports
  wire pc_fetch_wr_sig = PCWr;
  wire pc_next_mux_sel = PCNxtMUX;
  wire [31:0] pc_target_addr = target;
  wire pc_reset_sig = reset;
  wire pc_halt_sig = halt;
  wire pc_clock = clock;

  instr_fetch #(
    .RESET_VECTOR(RESET_VECTOR)
  ) instr_fetch_instance(
    .PCWr(pc_fetch_wr_sig),
    .PCNxtMUX(pc_next_mux_sel),
    .target(pc_target_addr),
    .rst(pc_reset_sig),
    .Halt(pc_halt_sig),
    .clk(pc_clock),
    .PC(PC_IF)
  );

  assign imemaddr = PC_IF;
  assign imemclk  = clock; 
  assign instr_IF = imemdataout;

  // ---------------------------------------------------------------------------
  // IF/ID Pipeline Register Wires and Logic
  // **These names are part of the critical path and must not be changed**
  // ---------------------------------------------------------------------------
  wire IF_IDWr; 

  `DEF_PIPE_CONNECT(IF, ID, 32, PC,    IF_IDWr, PCNxtMUX)
  `DEF_PIPE_CONNECT(IF, ID, 32, instr, IF_IDWr, PCNxtMUX)

  // ---------------------------------------------------------------------------
  // ID (Instruction Decode) Stage Wires and Logic
  // ---------------------------------------------------------------------------
  // Instruction Fields (ID stage input)
  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [4:0] rd_ID;
  wire [4:0] rs1_ID;
  wire [4:0] rs2_ID;

  instr_parse instr_parse_instance(
    .o_opcode_field(opcode),
    .o_f3_field(funct3),
    .o_f7_field(funct7),
    .o_dest_reg(rd_ID),
    .o_src1_reg(rs1_ID),
    .o_src2_reg(rs2_ID),
    .i_instruction(instr_ID)
  );

  // Control Unit Outputs (ID_outputs_wires)
  wire        Invalid_ID;
  wire [2:0]  ExtOp;
  wire        RegWr_ID;
  wire        ALUASrc_ID;
  wire [1:0]  ALUBSrc_ID;
  wire [3:0]  ALUctr_ID;
  wire [2:0]  Branch_ID;
  wire        MemtoReg_ID;
  wire        MemWr_ID;
  wire [2:0]  MemOp_ID;
  wire        isjalr_ID;
  wire        have_rs1_ID; 
  wire        have_rs2_ID; 
  wire        CtrCLR;      

  ctrl ctrl_instance(
    .o_invalid_instr(Invalid_ID),
    .o_ext_op(ExtOp),
    .o_reg_write_en(RegWr_ID),
    .o_alu_a_sel(ALUASrc_ID),
    .o_alu_b_sel(ALUBSrc_ID),
    .o_alu_func(ALUctr_ID),
    .o_branch_ctrl(Branch_ID),
    .o_wb_mem_sel(MemtoReg_ID),
    .o_mem_write_en(MemWr_ID),
    .o_mem_op_size(MemOp_ID),
    .o_is_jalr(isjalr_ID),
    .o_needs_rs1(have_rs1_ID),
    .o_needs_rs2(have_rs2_ID),
    .i_opcode(opcode),
    .i_funct3(funct3),
    .i_funct7(funct7),
    .i_ctrl_clear(CtrCLR),
    .i_reset(reset)
  );

  // Immediate Generation
  wire [31:0] Imm_ID;
  instr_to_imm instr_to_imm_instance(
    .i_instr_data(instr_ID),
    .i_ext_mode(ExtOp),
    .o_immediate_val(Imm_ID)
  );

  // Register File Interface
  wire [31:0] BusA_ID;
  wire [31:0] BusB_ID;
  wire [31:0] BusW_WB;
  wire [4:0]  rd_WB;
  wire        RegWr_WB;

  regfile myregfile(
    .o_data_a(BusA_ID),
    .o_data_b(BusB_ID),
    .i_clk(clock), 
    .i_ra(rs1_ID),
    .i_rb(rs2_ID),
    .i_rw(rd_WB),
    .i_data_w(BusW_WB),
    .i_we(RegWr_WB)
  );

  // ---------------------------------------------------------------------------
  // ID/EX Pipeline Register Wires and Logic
  // **These names are part of the critical path and must not be changed**
  // ---------------------------------------------------------------------------
  `DEF_PIPE_CONNECT(ID, EX, 1,  Invalid,  1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 1,  RegWr,    1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 1,  ALUASrc,  1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 2,  ALUBSrc,  1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 4,  ALUctr,   1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 3,  Branch,   1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 1,  MemtoReg, 1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 1,  MemWr,    1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 3,  MemOp,    1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 1,  isjalr,   1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 32, BusA,     1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 32, BusB,     1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 32, Imm,      1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 32, PC,       1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 5,  rs1,      1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 5,  rs2,      1'b1, PCNxtMUX)
  `DEF_PIPE_CONNECT(ID, EX, 5,  rd,       1'b1, PCNxtMUX)


  // ---------------------------------------------------------------------------
  // EX (Execute) Stage Wires and Logic
  // ---------------------------------------------------------------------------
  wire [1:0]  BusAFW;    
  wire [1:0]  BusBFW;    
  wire [31:0] ValFW_WB;  
  wire [31:0] ValFW_M;   
  wire [31:0] Result_EX; 
  wire        Zero_EX;   
  wire [31:0] target_EX; 
  wire        Br_EX;     

  // Forwarding MUXs
  wire [31:0] EU_BusA_EX =
    BusAFW == 2'b00 ? BusA_EX  :
    BusAFW == 2'b01 ? ValFW_WB :
    BusAFW == 2'b10 ? ValFW_M  : 32'b0;
  wire [31:0] EU_BusB_EX =
    BusBFW == 2'b00 ? BusB_EX  :
    BusBFW == 2'b01 ? ValFW_WB :
    BusBFW == 2'b10 ? ValFW_M  : 32'b0;

  execute_unit execute_unit_instance(
    .i_alu_data_a(EU_BusA_EX),
    .i_alu_data_b(EU_BusB_EX),
    .i_pc_in(PC_EX),
    .i_imm_in(Imm_EX),
    .i_alu_ctrl(ALUctr_EX),
    .i_alu_a_src(ALUASrc_EX),
    .i_alu_b_src(ALUBSrc_EX),
    .i_is_jalr(isjalr_EX),
    .o_next_pc_target(target_EX),
    .o_alu_result(Result_EX),
    .o_alu_zero(Zero_EX)
  );

  branch_ctrl branch_ctrl_instance(
    .o_branch_taken(Br_EX),
    .i_zero_flag(Zero_EX),
    .i_lsb_result(Result_EX[0]),
    .i_branch_mode(Branch_EX)
  );

  // Invalid Instruction Handling
  reg [31:0] invalid_PC;
  always @(negedge clock) begin
    if (reset) begin
      halt <= 1'b0;
      invalid_PC <= 32'h1;
    end
    else if (Invalid_EX) begin
      halt <= 1'b1;
      invalid_PC <= PC_EX;
    end
  end

  // PC MUX control logic
  assign PCNxtMUX = Br_EX | (halt | Invalid_EX);
  assign target =
    halt       ? invalid_PC :
    Invalid_EX ? PC_EX      :
    target_EX;

  // ---------------------------------------------------------------------------
  // EX/M Pipeline Register Wires and Logic
  // **These names are part of the critical path and must not be changed**
  // ---------------------------------------------------------------------------
  `DEF_PIPE_CONNECT(EX, M, 3,  MemOp,    1'b1, 1'b0)
  `DEF_PIPE_CONNECT(EX, M, 1,  MemWr,    1'b1, 1'b0)
  `DEF_PIPE_CONNECT(EX, M, 1,  RegWr,    1'b1, 1'b0)
  `DEF_PIPE_CONNECT(EX, M, 1,  MemtoReg, 1'b1, 1'b0)
  `DEF_PIPE_CONNECT(EX, M, 32, PC,       1'b1, 1'b0)
  `DEF_PIPE_CONNECT(EX, M, 32, Result,   1'b1, 1'b0)
  `DEF_PIPE_CONNECT(EX, M, 32, EU_BusB,  1'b1, 1'b0)
  `DEF_PIPE_CONNECT(EX, M, 5,  rd,       1'b1, 1'b0)


  // ---------------------------------------------------------------------------
  // M (Memory Access) Stage Wires and Logic
  // ---------------------------------------------------------------------------
  wire [31:0] Dataout_M;

  assign dmemaddr   = Result_M;
  assign dmemdatain = EU_BusB_M;
  assign dmemrdclk  = clock;
  assign dmemwrclk  = ~clock;
  assign dmemop     = MemOp_M;
  assign dmemwe     = MemWr_M;
  assign Dataout_M  = dmemdataout;


  // ---------------------------------------------------------------------------
  // M/WB Pipeline Register Wires and Logic
  // **These names are part of the critical path and must not be changed**
  // ---------------------------------------------------------------------------
  `PIPE_CONNECT(M, WB, 1,  RegWr,    1'b1, 1'b0)
  `DEF_PIPE_CONNECT(M, WB, 1,  MemtoReg, 1'b1, 1'b0)
  `DEF_PIPE_CONNECT(M, WB, 32, PC,       1'b1, 1'b0)
  `DEF_PIPE_CONNECT(M, WB, 32, Result,   1'b1, 1'b0)
  `DEF_PIPE_CONNECT(M, WB, 32, Dataout,  1'b1, 1'b0)
  `PIPE_CONNECT(M, WB, 5,  rd,       1'b1, 1'b0)
  
  // ---------------------------------------------------------------------------
  // WB (Write Back) Stage Wires and Logic
  // ---------------------------------------------------------------------------
  assign BusW_WB =
    MemtoReg_WB == 1'b0 ? Result_WB  :
    MemtoReg_WB == 1'b1 ? Dataout_WB : 32'b0;

  // ---------------------------------------------------------------------------
  // Hazard Control Units
  // ---------------------------------------------------------------------------
  // Forwarding Unit
  assign ValFW_M  = Result_M;
  assign ValFW_WB = BusW_WB;

  forward_ctrl forward_ctrl_instance(
    .i_rs1_ex(rs1_EX),
    .i_rs2_ex(rs2_EX),
    .i_reg_wr_m(RegWr_M),
    .i_rd_m(rd_M),
    .i_reg_wr_wb(RegWr_WB),
    .i_rd_wb(rd_WB),
    .o_fw_a_sel(BusAFW),
    .o_fw_b_sel(BusBFW)
  );

  // Stalling/Hazard Unit
  stall_ctrl stall_ctrl_instance(
    .i_rs1_needed(have_rs1_ID),
    .i_rs2_needed(have_rs2_ID),
    .i_rs1_reg(rs1_ID),
    .i_rs2_reg(rs2_ID),
    .i_load_ex(MemtoReg_EX),
    .i_dest_reg_ex(rd_EX),
    .o_pc_write(PCWr),
    .o_id_write(IF_IDWr),
    .o_ctrl_clear_sig(CtrCLR)
  );
  
  // Debug output
  assign dbgdata = PC_IF;

endmodule


//******************************************************************************
// Module: regfile (Register File) - New Ports
//******************************************************************************

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
    if (i_we && i_rw != 5'b0) regs[i_rw] <= i_data_w;
  end

  assign o_data_a = (i_ra == 5'b0) ? 32'b0 : regs[i_ra];
  assign o_data_b = (i_rb == 5'b0) ? 32'b0 : regs[i_rb];
endmodule

//******************************************************************************
// Module: stall_ctrl (Stall Control Unit) - New Ports and Internal Logic
//******************************************************************************

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
  wire hazard_detected = i_load_ex & 
    (
      (i_rs1_needed & (i_rs1_reg == i_dest_reg_ex) & (i_rs1_reg != 5'b0)) |
      (i_rs2_needed & (i_rs2_reg == i_dest_reg_ex) & (i_rs2_reg != 5'b0))
    );
  
  assign o_pc_write       = ~hazard_detected;
  assign o_id_write       = ~hazard_detected;
  assign o_ctrl_clear_sig = hazard_detected;

endmodule

//******************************************************************************
// Module: pipereg (General Pipeline Register) - New Ports and Internal Logic
//******************************************************************************

module pipereg # (
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

//******************************************************************************
// Module: instr_to_imm (Immediate Value Generator) - New Ports and Internal Logic
//******************************************************************************

module instr_to_imm (
  input [31:0] i_instr_data,
  input [2:0]  i_ext_mode,
  output reg [31:0] o_immediate_val
);
  wire [31:0] imm_i_type, imm_u_type, imm_s_type, imm_b_type, imm_j_type;

  // I-Type Immediate
  assign imm_i_type = {{20{i_instr_data[31]}}, i_instr_data[31:20]};
  // U-Type Immediate
  assign imm_u_type = {i_instr_data[31:12], 12'b0};
  // S-Type Immediate
  assign imm_s_type = {{20{i_instr_data[31]}}, i_instr_data[31:25], i_instr_data[11:7]};
  // B-Type Immediate
  assign imm_b_type = {{19{i_instr_data[31]}}, i_instr_data[31], i_instr_data[7], i_instr_data[30:25], i_instr_data[11:8], 1'b0};
  // J-Type Immediate
  assign imm_j_type = {{11{i_instr_data[31]}}, i_instr_data[31], i_instr_data[19:12], i_instr_data[20], i_instr_data[30:21], 1'b0};
  
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

//******************************************************************************
// Module: instr_parse (Instruction Field Parser) - New Ports
//******************************************************************************

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

//******************************************************************************
// Module: instr_fetch (Program Counter) - New Ports
//******************************************************************************

module instr_fetch #(
  parameter RESET_VECTOR = 32'h80000000
)(
  input           PCWr,
  input           PCNxtMUX,
  input  [31:0]   target,
  input           rst,
  input           Halt,
  input           clk,
  output reg [31:0] PC
);
  // Internal logic is preserved, only module name is kept
  always @(negedge clk) begin
    if (rst)
      PC <= RESET_VECTOR;
    else if ((PCWr & ~Halt) | PCNxtMUX)
      PC <=
        PCNxtMUX == 1'b0 ? PC + 32'd4 :
        PCNxtMUX == 1'b1 ? target     : 32'b0;
  end
endmodule

//******************************************************************************
// Module: forward_ctrl (Data Forwarding Unit) - New Ports and Internal Logic
//******************************************************************************

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
  always @(*) begin
    // Check M stage first (2'b10)
    if (i_reg_wr_m & (i_rd_m == i_rs1_ex) & (i_rs1_ex != 5'b0))
      o_fw_a_sel = 2'b10;
    // Check WB stage second (2'b01)
    else if (i_reg_wr_wb & (i_rd_wb == i_rs1_ex) & (i_rs1_ex != 5'b0))
      o_fw_a_sel = 2'b01;
    // No forwarding (2'b00)
    else
      o_fw_a_sel = 2'b00;
  end
  
  always @(*) begin
    // Check M stage first (2'b10)
    if (i_reg_wr_m & (i_rd_m == i_rs2_ex) & (i_rs2_ex != 5'b0))
      o_fw_b_sel = 2'b10;
    // Check WB stage second (2'b01)
    else if (i_reg_wr_wb & (i_rd_wb == i_rs2_ex) & (i_rs2_ex != 5'b0))
      o_fw_b_sel = 2'b01;
    // No forwarding (2'b00)
    else
      o_fw_b_sel = 2'b00;
  end
endmodule

//******************************************************************************
// Module: execute_unit (Execution Unit) - New Ports and Internal Logic
//******************************************************************************

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
  wire [31:0] alu_a_mux_out =
    i_alu_a_src == 1'b0 ? i_alu_data_a :
    i_alu_a_src == 1'b1 ? i_pc_in      : 32'b0;
  wire [31:0] alu_b_mux_out =
    i_alu_b_src == 2'b00 ? i_alu_data_b :
    i_alu_b_src == 2'b01 ? 32'd4        :
    i_alu_b_src == 2'b10 ? i_imm_in     : 32'b0;
    
  wire [31:0] target_calc_src_a =
    i_is_jalr == 1'b0 ? i_pc_in      :
    i_is_jalr == 1'b1 ? i_alu_data_a : 32'b0;
    
  ALU32 alu_core(
    .o_result(o_alu_result),
    .o_is_zero(o_alu_zero),
    .i_data_a(alu_a_mux_out),
    .i_data_b(alu_b_mux_out),
    .i_control(i_alu_ctrl)
  );

  assign o_next_pc_target = target_calc_src_a + i_imm_in;
endmodule

//******************************************************************************
// Module: ctrl (Control Unit) - New Ports and Internal Logic
//******************************************************************************

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
  input           i_ctrl_clear,
  input           i_reset
);
  localparam U_LUI   = 7'b0110111;
  localparam U_AUIPC = 7'b0010111; 
  localparam I_arith = 7'b0010011;
  localparam R_arith = 7'b0110011;
  localparam J_JAL   = 7'b1101111;
  localparam I_JALR  = 7'b1100111;
  localparam B_instr = 7'b1100011;
  localparam I_load  = 7'b0000011;
  localparam S_instr = 7'b0100011;
  
  wire instr_is_empty   = ~|i_opcode;
  wire instr_is_lui     = (i_opcode == U_LUI);
  wire instr_is_auipc   = (i_opcode == U_AUIPC); 
  wire instr_is_i_arith = (i_opcode == I_arith);
  wire instr_is_r_arith = (i_opcode == R_arith ) && (i_funct7 == 7'b0000000 || i_funct7 == 7'b0100000);
  wire instr_is_jal     = (i_opcode == J_JAL);
  wire instr_is_jalr    = (i_opcode == I_JALR);
  wire instr_is_branch  = (i_opcode == B_instr);
  wire instr_is_load    = (i_opcode == I_load);
  wire instr_is_store   = (i_opcode == S_instr);

  wire i_ext_alu_ctrl = (instr_is_i_arith & (i_funct3 == 3'b001 || i_funct3 == 3'b101)) ? i_funct7[5] : 1'b0;
  wire r_ext_alu_ctrl = i_funct7[5];

  wire [3:0] branch_alu_op =
    (i_funct3 == 3'b000 || i_funct3 == 3'b001) ? 4'b1000 : // SUB
    (i_funct3 == 3'b110 || i_funct3 == 3'b111) ? 4'b0011 : // SLTU (unsigned)
    4'b0010; // SLT (signed)
  reg [2:0] branch_comparison_type;

  always @(*) begin
    case (i_funct3)
      3'b000: branch_comparison_type = 3'b100;
      3'b001: branch_comparison_type = 3'b101;
      3'b100: branch_comparison_type = 3'b110;
      3'b101: branch_comparison_type = 3'b111;
      3'b110: branch_comparison_type = 3'b110;
      3'b111: branch_comparison_type = 3'b111;
      default: branch_comparison_type = 3'b000;
    endcase
  end

  wire control_clear = i_reset | instr_is_empty | i_ctrl_clear;
  
  always @(*) begin
    if (control_clear)
      `CONTROL_SET_VALUES(1'b0, 3'b000, 1'b0, 1'b0, 2'b00, 4'b0000, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (instr_is_lui)
      `CONTROL_SET_VALUES(1'b0, 3'b001, 1'b1, 1'b0, 2'b10, 4'b1111, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (instr_is_auipc)
      `CONTROL_SET_VALUES(1'b0, 3'b001, 1'b1, 1'b1, 2'b10, 4'b0000, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (instr_is_i_arith)
      `CONTROL_SET_VALUES(1'b0, 3'b000, 1'b1, 1'b0, 2'b10, {i_ext_alu_ctrl, i_funct3}, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (instr_is_r_arith)
      `CONTROL_SET_VALUES(1'b0, 3'b000, 1'b1, 1'b0, 2'b00, {r_ext_alu_ctrl, i_funct3}, 3'b000, 1'b0, 1'b0, 3'b000)
    else if (instr_is_jal)
      `CONTROL_SET_VALUES(1'b0, 3'b100, 1'b1, 1'b1, 2'b01, 4'b0000, 3'b001, 1'b0, 1'b0, 3'b000)
    else if (instr_is_jalr)
      `CONTROL_SET_VALUES(1'b0, 3'b000, 1'b1, 1'b1, 2'b01, 4'b0000, 3'b010, 1'b0, 1'b0, 3'b000)
    else if (instr_is_branch)
      `CONTROL_SET_VALUES(1'b0, 3'b011, 1'b0, 1'b0, 2'b00, branch_alu_op, branch_comparison_type, 1'b0, 1'b0, 3'b000)
    else if (instr_is_load)
      `CONTROL_SET_VALUES(1'b0, 3'b000, 1'b1, 1'b0, 2'b10, 4'b0000, 3'b000, 1'b1, 1'b0, i_funct3)
    else if (instr_is_store)
      `CONTROL_SET_VALUES(1'b0, 3'b010, 1'b0, 1'b0, 2'b10, 4'b0000, 3'b000, 1'b0, 1'b1, i_funct3)
    else
      `CONTROL_SET_VALUES(1'b1, 3'b000, 1'b0, 1'b0, 2'b00, 4'b0000, 3'b000, 1'b0, 1'b0, 3'b000)
  end
  assign o_is_jalr   = control_clear ? 1'b0 : instr_is_jalr;
  assign o_needs_rs1 = instr_is_r_arith | instr_is_i_arith | instr_is_load | instr_is_jalr | instr_is_store | instr_is_branch | instr_is_auipc;
  assign o_needs_rs2 = instr_is_r_arith | instr_is_store | instr_is_branch;
endmodule

//******************************************************************************
// Module: branch_ctrl (Branch Condition Checker) - New Ports
//******************************************************************************

module branch_ctrl (
  output reg o_branch_taken,
  input i_zero_flag, 
  input i_lsb_result,
  input [2:0] i_branch_mode
);
  always @(*) begin
    case (i_branch_mode)
      3'b000: o_branch_taken = 1'b0;
      3'b001: o_branch_taken = 1'b1;
      3'b010: o_branch_taken = 1'b1;
      3'b100: o_branch_taken = i_zero_flag;
      3'b101: o_branch_taken = ~i_zero_flag;
      3'b110: o_branch_taken = i_lsb_result;
      3'b111: o_branch_taken = ~i_lsb_result;
      default: o_branch_taken = 1'b0;
    endcase
  end
endmodule

//******************************************************************************
// Module: ALU32 (32-bit Arithmetic Logic Unit) - New Ports and Internal Logic
//******************************************************************************

module ALU32 (
  output reg [31:0] o_result,
  output wire o_is_zero,
  input [31:0] i_data_a,
  input [31:0] i_data_b,
  input [3:0] i_control
);

  assign o_is_zero = (o_result == 32'b0);
  
  wire [31:0] slt_comparison_result;
  assign slt_comparison_result = {{31{1'b0}}, 
                                  i_control[0] ? ($unsigned(i_data_a) < $unsigned(i_data_b)) : 
                                                 ($signed(i_data_a) < $signed(i_data_b))};

  always @(*) begin
    casez (i_control)
      4'b0000: o_result = i_data_a + i_data_b;
      4'b1000: o_result = i_data_a - i_data_b;
      
      4'b0001: o_result = i_data_a << i_data_b[4:0];
      4'b0101: o_result = $unsigned(i_data_a) >> i_data_b[4:0];
      4'b1101: o_result = $signed(i_data_a) >>> i_data_b[4:0];
      
      4'b0010: o_result = slt_comparison_result;
      4'b0011: o_result = slt_comparison_result;
      
      4'b0100: o_result = i_data_a ^ i_data_b;
      4'b0110: o_result = i_data_a | i_data_b;
      4'b0111: o_result = i_data_a & i_data_b;
      
      4'b1111: o_result = i_data_b;
      
      default: o_result = 32'b0;
    endcase
  end
endmodule