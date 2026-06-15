// sisRvCore.sv - RV32IMC core with a 3-stage pipeline.
// Stages:
//   IF        - instruction fetch, including RV32C halfword assembly
//   ID        - decode and register read
//   EX/MEM/WB - execute, data memory, writeback, CSR/trap retirement
//
// The external corebus contract remains single-outstanding. Instruction fetch
// and data memory arbitrate internally; data memory has priority.

module sisRvCore #(
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000,
    parameter bit          ENABLE_M     = 1'b1,
    parameter bit          ENABLE_C     = 1'b1
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        dbg_halt_req,
    input  logic        dbg_resume_req,
    input  logic        dbg_single_step,
    output logic        dbg_halted,

    input  logic        dbg_abs_valid,
    output logic        dbg_abs_ready,
    input  logic        dbg_abs_write,
    input  logic [4:0]  dbg_abs_regaddr,
    input  logic [31:0] dbg_abs_wdata,
    output logic [31:0] dbg_abs_rdata,

    input  logic        ext_msip,
    input  logic        ext_mtip,
    input  logic        ext_meip,

    output logic        req_valid,
    input  logic        req_ready,
    output logic [31:0] req_addr,
    output logic        req_we,
    output logic [31:0] req_wdata,
    output logic [3:0]  req_wstrb,

    input  logic        rsp_valid,
    output logic        rsp_ready,
    input  logic [31:0] rsp_rdata,
    input  logic        rsp_err
);

  localparam logic [3:0] ALU_ADD = 4'b0000;
  localparam logic [3:0] ALU_SUB = 4'b1000;

  typedef enum logic [1:0] {
    BUS_NONE = 2'd0,
    BUS_IF   = 2'd1,
    BUS_DATA = 2'd2
  } bus_owner_t;

  typedef enum logic [1:0] {
    IF_REQ        = 2'd0,
    IF_WAIT       = 2'd1,
    IF_SECOND_REQ = 2'd2,
    IF_SECOND_WAIT= 2'd3
  } if_state_t;

  typedef enum logic [1:0] {
    EX_EXEC     = 2'd0,
    EX_MEM_REQ  = 2'd1,
    EX_MEM_WAIT = 2'd2,
    EX_WB       = 2'd3
  } ex_state_t;

  bus_owner_t bus_owner;

  // ---------------------------------------------------------------
  // IF stage
  // ---------------------------------------------------------------
  if_state_t  if_state;
  logic [31:0] fetch_pc;
  logic [31:0] fetch_req_pc;
  logic [15:0] fetch_upper_hold;
  logic        fetch_err_hold;
  logic        if_discard_rsp;

  logic        if_id_valid;
  logic [31:0] if_id_pc;
  logic [31:0] if_id_raw;
  logic [1:0]  if_id_len;
  logic        if_id_is_compressed;
  logic        if_id_fetch_err;

  // ---------------------------------------------------------------
  // ID stage decode
  // ---------------------------------------------------------------
  logic [31:0] decomp_instr;
  logic        decomp_illegal;
  logic        decomp_is_c;
  logic [31:0] decoded_instr;

  sisDecompress u_decompress (
    .c_instr         (if_id_raw[15:0]),
    .instr_o         (decomp_instr),
    .is_compressed_o (decomp_is_c),
    .illegal_o       (decomp_illegal)
  );

  assign decoded_instr = if_id_is_compressed ? decomp_instr : if_id_raw;

  logic [4:0]  dec_rs1, dec_rs2, dec_rd;
  logic [31:0] dec_imm_i, dec_imm_s, dec_imm_b, dec_imm_u, dec_imm_j;
  logic [6:0]  dec_opcode;
  logic [2:0]  dec_funct3;
  logic [6:0]  dec_funct7;
  logic        dec_is_lui, dec_is_auipc, dec_is_jal, dec_is_jalr;
  logic        dec_is_branch, dec_is_load, dec_is_store;
  logic        dec_is_alu_imm, dec_is_alu_reg;
  logic        dec_is_system, dec_is_fence;
  logic        dec_is_legal;

  sisDecode #(
    .ENABLE_M (ENABLE_M),
    .ENABLE_C (ENABLE_C)
  ) u_decode (
    .instr     (decoded_instr),
    .rs1       (dec_rs1),
    .rs2       (dec_rs2),
    .rd        (dec_rd),
    .imm_i     (dec_imm_i),
    .imm_s     (dec_imm_s),
    .imm_b     (dec_imm_b),
    .imm_u     (dec_imm_u),
    .imm_j     (dec_imm_j),
    .opcode    (dec_opcode),
    .funct3    (dec_funct3),
    .funct7    (dec_funct7),
    .is_lui    (dec_is_lui),
    .is_auipc  (dec_is_auipc),
    .is_jal    (dec_is_jal),
    .is_jalr   (dec_is_jalr),
    .is_branch (dec_is_branch),
    .is_load   (dec_is_load),
    .is_store  (dec_is_store),
    .is_alu_imm(dec_is_alu_imm),
    .is_alu_reg(dec_is_alu_reg),
    .is_system (dec_is_system),
    .is_fence  (dec_is_fence),
    .is_legal  (dec_is_legal)
  );

  // ---------------------------------------------------------------
  // Register file
  // ---------------------------------------------------------------
  logic [31:0] rf_rs1_data, rf_rs2_data;
  logic        rf_wr_en;
  logic [4:0]  rf_rd_addr;
  logic [31:0] rf_rd_data;

  sisRegFile u_regfile (
    .clk      (clk),
    .rs1_addr (dec_rs1),
    .rs1_data (rf_rs1_data),
    .rs2_addr (dec_rs2),
    .rs2_data (rf_rs2_data),
    .wr_en    (rf_wr_en),
    .rd_addr  (rf_rd_addr),
    .rd_data  (rf_rd_data),
    .dbg_en   (dbg_abs_valid && halted),
    .dbg_we   (dbg_abs_write),
    .dbg_addr (dbg_abs_regaddr),
    .dbg_wdata(dbg_abs_wdata),
    .dbg_rdata(dbg_abs_rdata)
  );

  assign dbg_abs_ready = dbg_abs_valid && halted;

  // ---------------------------------------------------------------
  // EX/MEM/WB stage registers
  // ---------------------------------------------------------------
  ex_state_t  ex_state;
  logic       ex_valid;
  logic [31:0] ex_pc;
  logic [31:0] ex_instr;
  logic [31:0] ex_raw;
  logic [1:0]  ex_len;
  logic        ex_is_compressed;
  logic        ex_fetch_err;
  logic        ex_illegal_compressed;

  logic [4:0]  ex_rs1, ex_rs2, ex_rd;
  logic [31:0] ex_imm_i, ex_imm_s, ex_imm_b, ex_imm_u, ex_imm_j;
  logic [6:0]  ex_opcode;
  logic [2:0]  ex_funct3;
  logic [6:0]  ex_funct7;
  logic        ex_is_lui, ex_is_auipc, ex_is_jal, ex_is_jalr;
  logic        ex_is_branch, ex_is_load, ex_is_store;
  logic        ex_is_alu_imm, ex_is_alu_reg;
  logic        ex_is_system, ex_is_fence;
  logic        ex_is_legal;

  logic [31:0] ex_rs1_val, ex_rs2_val;
  logic [31:0] ex_alu_result_reg;
  logic [31:0] ex_mem_addr_reg;
  logic [31:0] ex_mem_rdata_reg;
  logic        ex_mem_err;
  logic        ex_mem_misaligned;

  logic        halted;
  assign dbg_halted = halted;

  // ---------------------------------------------------------------
  // ALU and M extension
  // ---------------------------------------------------------------
  logic [31:0] alu_a, alu_b;
  logic [3:0]  alu_op;
  logic [31:0] alu_result;
  logic        alu_zero;
  logic [31:0] m_result;
  logic        ex_is_m_op;

  sisAlu u_alu (
    .a      (alu_a),
    .b      (alu_b),
    .op     (alu_op),
    .result (alu_result),
    .zero   (alu_zero)
  );

  function automatic logic [31:0] rv32m_result(
      input logic [31:0] lhs,
      input logic [31:0] rhs,
      input logic [2:0]  op
  );
    logic signed [31:0] lhs_s;
    logic signed [31:0] rhs_s;
    logic signed [63:0] lhs_s64;
    logic signed [63:0] rhs_s64;
    logic signed [63:0] rhs_u64_s;
    logic [63:0]        lhs_u64;
    logic [63:0]        rhs_u64;
    logic signed [63:0] ss_product;
    logic signed [63:0] su_product;
    logic [63:0]        uu_product;
    begin
      lhs_s      = lhs;
      rhs_s      = rhs;
      lhs_s64    = {{32{lhs[31]}}, lhs};
      rhs_s64    = {{32{rhs[31]}}, rhs};
      rhs_u64_s  = {32'h0, rhs};
      lhs_u64    = {32'h0, lhs};
      rhs_u64    = {32'h0, rhs};
      ss_product = lhs_s64 * rhs_s64;
      su_product = lhs_s64 * rhs_u64_s;
      uu_product = lhs_u64 * rhs_u64;

      case (op)
        3'b000: rv32m_result = ss_product[31:0];
        3'b001: rv32m_result = ss_product[63:32];
        3'b010: rv32m_result = su_product[63:32];
        3'b011: rv32m_result = uu_product[63:32];
        3'b100: begin
          if (rhs == 32'h0)
            rv32m_result = 32'hFFFF_FFFF;
          else if ((lhs == 32'h8000_0000) && (rhs == 32'hFFFF_FFFF))
            rv32m_result = 32'h8000_0000;
          else
            rv32m_result = lhs_s / rhs_s;
        end
        3'b101: rv32m_result = (rhs == 32'h0) ? 32'hFFFF_FFFF : (lhs / rhs);
        3'b110: begin
          if (rhs == 32'h0)
            rv32m_result = lhs;
          else if ((lhs == 32'h8000_0000) && (rhs == 32'hFFFF_FFFF))
            rv32m_result = 32'h0;
          else
            rv32m_result = lhs_s % rhs_s;
        end
        3'b111: rv32m_result = (rhs == 32'h0) ? lhs : (lhs % rhs);
        default: rv32m_result = 32'h0;
      endcase
    end
  endfunction

  assign ex_is_m_op = ENABLE_M && ex_is_alu_reg && (ex_funct7 == 7'b0000001);
  assign m_result   = rv32m_result(ex_rs1_val, ex_rs2_val, ex_funct3);

  always_comb begin
    alu_a  = ex_rs1_val;
    alu_b  = ex_rs2_val;
    alu_op = ALU_ADD;

    if (ex_is_alu_reg) begin
      alu_a  = ex_rs1_val;
      alu_b  = ex_rs2_val;
      alu_op = {ex_funct7[5], ex_funct3};
    end else if (ex_is_alu_imm) begin
      alu_a  = ex_rs1_val;
      alu_b  = ex_imm_i;
      alu_op = (ex_funct3 == 3'b101) ? {ex_funct7[5], ex_funct3} : {1'b0, ex_funct3};
    end else if (ex_is_load || ex_is_store) begin
      alu_a  = ex_rs1_val;
      alu_b  = ex_is_store ? ex_imm_s : ex_imm_i;
      alu_op = ALU_ADD;
    end else if (ex_is_branch) begin
      alu_a  = ex_rs1_val;
      alu_b  = ex_rs2_val;
      alu_op = ALU_SUB;
    end else if (ex_is_lui) begin
      alu_a  = 32'h0;
      alu_b  = ex_imm_u;
      alu_op = ALU_ADD;
    end else if (ex_is_auipc) begin
      alu_a  = ex_pc;
      alu_b  = ex_imm_u;
      alu_op = ALU_ADD;
    end else if (ex_is_jal || ex_is_jalr) begin
      alu_a  = ex_pc;
      alu_b  = (ex_len == 2'd2) ? 32'd2 : 32'd4;
      alu_op = ALU_ADD;
    end
  end

  // ---------------------------------------------------------------
  // CSR unit
  // ---------------------------------------------------------------
  logic [11:0] csr_addr_w;
  logic [31:0] csr_wdata_w;
  logic [1:0]  csr_op_w;
  logic        csr_wen_w;
  logic [31:0] csr_rdata_w;
  logic        trap_enter;
  logic [31:0] trap_cause;
  logic [31:0] trap_val;
  logic [31:0] trap_epc;
  logic        mret_exec;
  logic        instr_retire;
  logic [31:0] mtvec_out;
  logic [31:0] mepc_out;
  logic        irq_pending;
  logic [31:0] irq_cause;

  sisCsr #(
    .ENABLE_C (ENABLE_C)
  ) u_csr (
    .clk         (clk),
    .rst_n       (rst_n),
    .csr_addr    (csr_addr_w),
    .csr_wdata   (csr_wdata_w),
    .csr_op      (csr_op_w),
    .csr_wen     (csr_wen_w),
    .csr_rdata   (csr_rdata_w),
    .trap_enter  (trap_enter),
    .trap_cause  (trap_cause),
    .trap_val    (trap_val),
    .trap_epc    (trap_epc),
    .mret_exec   (mret_exec),
    .instr_retire(instr_retire),
    .ext_msip    (ext_msip),
    .ext_mtip    (ext_mtip),
    .ext_meip    (ext_meip),
    .mtvec_out   (mtvec_out),
    .mepc_out    (mepc_out),
    .irq_pending (irq_pending),
    .irq_cause   (irq_cause)
  );

  // ---------------------------------------------------------------
  // EX-stage helpers
  // ---------------------------------------------------------------
  logic ex_is_ecall, ex_is_ebreak, ex_is_mret, ex_is_csr_op;
  logic ex_dec_is_legal_eff;
  logic ex_branch_taken;
  logic [31:0] ex_branch_target, ex_jal_target, ex_jalr_target;
  logic [31:0] ex_next_pc_target, ex_pc_sequential, ex_pc_next;
  logic        ex_instr_addr_misaligned;
  logic        ex_redirect;
  logic [1:0]  ex_csr_op_type;
  logic [31:0] csr_src_val;
  logic [31:0] load_result;
  logic [31:0] store_data;
  logic [3:0]  store_strb;
  logic [31:0] ex_wb_result;
  logic        ex_writes_rd;

  assign ex_pc_sequential = ex_pc + ((ex_len == 2'd2) ? 32'd2 : 32'd4);
  assign ex_is_ecall  = ex_is_system && (ex_funct3 == 3'b000) && (ex_instr[31:20] == 12'h000);
  assign ex_is_ebreak = ex_is_system && (ex_funct3 == 3'b000) && (ex_instr[31:20] == 12'h001);
  assign ex_is_mret   = ex_is_system && (ex_funct3 == 3'b000) && (ex_instr[31:20] == 12'h302);
  assign ex_is_csr_op = ex_is_system && (ex_funct3 != 3'b000);
  assign ex_dec_is_legal_eff = ENABLE_C ? (ex_is_legal && !ex_illegal_compressed) :
                                          (ex_is_legal && !ex_is_compressed);

  always_comb begin
    ex_branch_taken = 1'b0;
    if (ex_is_branch) begin
      case (ex_funct3)
        3'b000: ex_branch_taken = (ex_rs1_val == ex_rs2_val);
        3'b001: ex_branch_taken = (ex_rs1_val != ex_rs2_val);
        3'b100: ex_branch_taken = ($signed(ex_rs1_val) < $signed(ex_rs2_val));
        3'b101: ex_branch_taken = ($signed(ex_rs1_val) >= $signed(ex_rs2_val));
        3'b110: ex_branch_taken = (ex_rs1_val < ex_rs2_val);
        3'b111: ex_branch_taken = (ex_rs1_val >= ex_rs2_val);
        default: ex_branch_taken = 1'b0;
      endcase
    end
  end

  assign ex_branch_target = ex_pc + ex_imm_b;
  assign ex_jal_target    = ex_pc + ex_imm_j;
  assign ex_jalr_target   = (ex_rs1_val + ex_imm_i) & 32'hFFFF_FFFE;

  always_comb begin
    ex_next_pc_target = ex_pc_sequential;
    if (ex_is_jal) begin
      ex_next_pc_target = ex_jal_target;
    end else if (ex_is_jalr) begin
      ex_next_pc_target = ex_jalr_target;
    end else if (ex_is_branch && ex_branch_taken) begin
      ex_next_pc_target = ex_branch_target;
    end
  end

  assign ex_instr_addr_misaligned = ex_dec_is_legal_eff &&
                                    (ex_is_jal || ex_is_jalr || (ex_is_branch && ex_branch_taken)) &&
                                    (ENABLE_C ? (ex_next_pc_target[0] != 1'b0) :
                                                (ex_is_compressed ? (ex_next_pc_target[0] != 1'b0) :
                                                                    (ex_next_pc_target[1:0] != 2'b00)));

  always_comb begin
    ex_pc_next = ex_pc_sequential;
    if (ex_fetch_err || ex_mem_err || ex_mem_misaligned || ex_instr_addr_misaligned || !ex_dec_is_legal_eff) begin
      ex_pc_next = mtvec_out;
    end else if (ex_is_jal) begin
      ex_pc_next = ex_jal_target;
    end else if (ex_is_jalr) begin
      ex_pc_next = ex_jalr_target;
    end else if (ex_is_branch && ex_branch_taken) begin
      ex_pc_next = ex_branch_target;
    end else if (ex_is_ecall || ex_is_ebreak) begin
      ex_pc_next = mtvec_out;
    end else if (ex_is_mret) begin
      ex_pc_next = mepc_out;
    end else if (irq_pending && !ex_is_csr_op) begin
      ex_pc_next = mtvec_out;
    end
  end

  assign ex_redirect = ex_valid && (ex_state == EX_WB) &&
                       (ex_fetch_err || ex_mem_err || ex_mem_misaligned ||
                        ex_instr_addr_misaligned || !ex_dec_is_legal_eff ||
                        ex_is_jal || ex_is_jalr || (ex_is_branch && ex_branch_taken) ||
                        ex_is_ecall || ex_is_ebreak || ex_is_mret ||
                        (irq_pending && !ex_is_csr_op));

  function automatic logic is_mem_misaligned(
      input logic [31:0] addr,
      input logic [2:0]  funct3
  );
    begin
      case (funct3[1:0])
        2'b00: is_mem_misaligned = 1'b0;
        2'b01: is_mem_misaligned = addr[0];
        2'b10: is_mem_misaligned = |addr[1:0];
        default: is_mem_misaligned = 1'b0;
      endcase
    end
  endfunction

  always_comb begin
    store_data = 32'h0;
    store_strb = 4'h0;
    case (ex_funct3[1:0])
      2'b00: begin
        case (ex_alu_result_reg[1:0])
          2'b00: begin store_data = {24'b0, ex_rs2_val[7:0]};       store_strb = 4'b0001; end
          2'b01: begin store_data = {16'b0, ex_rs2_val[7:0], 8'b0}; store_strb = 4'b0010; end
          2'b10: begin store_data = {8'b0, ex_rs2_val[7:0], 16'b0}; store_strb = 4'b0100; end
          2'b11: begin store_data = {ex_rs2_val[7:0], 24'b0};       store_strb = 4'b1000; end
        endcase
      end
      2'b01: begin
        case (ex_alu_result_reg[1])
          1'b0: begin store_data = {16'b0, ex_rs2_val[15:0]}; store_strb = 4'b0011; end
          1'b1: begin store_data = {ex_rs2_val[15:0], 16'b0}; store_strb = 4'b1100; end
        endcase
      end
      2'b10: begin
        store_data = ex_rs2_val;
        store_strb = 4'b1111;
      end
      default: ;
    endcase
  end

  always_comb begin
    load_result = 32'h0;
    case (ex_funct3)
      3'b000: begin
        case (ex_mem_addr_reg[1:0])
          2'b00: load_result = {{24{ex_mem_rdata_reg[7]}},  ex_mem_rdata_reg[7:0]};
          2'b01: load_result = {{24{ex_mem_rdata_reg[15]}}, ex_mem_rdata_reg[15:8]};
          2'b10: load_result = {{24{ex_mem_rdata_reg[23]}}, ex_mem_rdata_reg[23:16]};
          2'b11: load_result = {{24{ex_mem_rdata_reg[31]}}, ex_mem_rdata_reg[31:24]};
        endcase
      end
      3'b001: begin
        case (ex_mem_addr_reg[1])
          1'b0: load_result = {{16{ex_mem_rdata_reg[15]}}, ex_mem_rdata_reg[15:0]};
          1'b1: load_result = {{16{ex_mem_rdata_reg[31]}}, ex_mem_rdata_reg[31:16]};
        endcase
      end
      3'b010: load_result = ex_mem_rdata_reg;
      3'b100: begin
        case (ex_mem_addr_reg[1:0])
          2'b00: load_result = {24'b0, ex_mem_rdata_reg[7:0]};
          2'b01: load_result = {24'b0, ex_mem_rdata_reg[15:8]};
          2'b10: load_result = {24'b0, ex_mem_rdata_reg[23:16]};
          2'b11: load_result = {24'b0, ex_mem_rdata_reg[31:24]};
        endcase
      end
      3'b101: begin
        case (ex_mem_addr_reg[1])
          1'b0: load_result = {16'b0, ex_mem_rdata_reg[15:0]};
          1'b1: load_result = {16'b0, ex_mem_rdata_reg[31:16]};
        endcase
      end
      default: load_result = ex_mem_rdata_reg;
    endcase
  end

  always_comb begin
    ex_csr_op_type = 2'b00;
    case (ex_funct3[1:0])
      2'b01: ex_csr_op_type = 2'b01;
      2'b10: ex_csr_op_type = 2'b10;
      2'b11: ex_csr_op_type = 2'b11;
      default: ex_csr_op_type = 2'b00;
    endcase
  end

  assign csr_src_val = ex_funct3[2] ? {27'b0, ex_rs1} : ex_rs1_val;

  always_comb begin
    ex_wb_result = ex_alu_result_reg;
    if (ex_is_load) begin
      ex_wb_result = load_result;
    end else if (ex_is_csr_op) begin
      ex_wb_result = csr_rdata_w;
    end
  end

  assign ex_writes_rd = ex_valid && (ex_state == EX_WB) &&
                        !ex_fetch_err && !ex_mem_err && !ex_mem_misaligned &&
                        !ex_instr_addr_misaligned && ex_dec_is_legal_eff &&
                        (ex_is_alu_reg || ex_is_alu_imm || ex_is_lui ||
                         ex_is_auipc || ex_is_jal || ex_is_jalr ||
                         ex_is_load || ex_is_csr_op);

  // ID reads see same-cycle WB data through this bypass.
  logic [31:0] id_rs1_val, id_rs2_val;
  always_comb begin
    id_rs1_val = rf_rs1_data;
    id_rs2_val = rf_rs2_data;
    if (ex_writes_rd && (ex_rd != 5'd0) && (ex_rd == dec_rs1)) begin
      id_rs1_val = ex_wb_result;
    end
    if (ex_writes_rd && (ex_rd != 5'd0) && (ex_rd == dec_rs2)) begin
      id_rs2_val = ex_wb_result;
    end
  end

  // ---------------------------------------------------------------
  // Corebus arbitration
  // ---------------------------------------------------------------
  logic data_req_active;
  logic if_req_active;
  logic data_req_fire;
  logic if_req_fire;
  logic data_rsp_fire;
  logic if_rsp_fire;

  assign data_req_active = ex_valid && (ex_state == EX_MEM_REQ);
  assign if_req_active   = !halted && !dbg_halt_req && !dbg_single_step &&
                           !if_id_valid &&
                           ((if_state == IF_REQ) || (if_state == IF_SECOND_REQ));

  always_comb begin
    req_valid = 1'b0;
    req_addr  = 32'h0;
    req_we    = 1'b0;
    req_wdata = 32'h0;
    req_wstrb = 4'h0;

    if (bus_owner == BUS_NONE && data_req_active) begin
      req_valid = 1'b1;
      req_addr  = ex_alu_result_reg;
      req_we    = ex_is_store;
      req_wdata = store_data;
      req_wstrb = ex_is_store ? store_strb : 4'h0;
    end else if (bus_owner == BUS_NONE && if_req_active) begin
      req_valid = 1'b1;
      req_addr  = (if_state == IF_SECOND_REQ) ? ({fetch_req_pc[31:2], 2'b00} + 32'd4) :
                                                {fetch_pc[31:2], 2'b00};
      req_we    = 1'b0;
      req_wstrb = 4'h0;
    end
  end

  assign rsp_ready     = (bus_owner != BUS_NONE);
  assign data_req_fire = (bus_owner == BUS_NONE) && data_req_active && req_ready;
  assign if_req_fire   = (bus_owner == BUS_NONE) && !data_req_active && if_req_active && req_ready;
  assign data_rsp_fire = rsp_valid && rsp_ready && (bus_owner == BUS_DATA);
  assign if_rsp_fire   = rsp_valid && rsp_ready && (bus_owner == BUS_IF);

  // ---------------------------------------------------------------
  // Register file write logic
  // ---------------------------------------------------------------
  always_comb begin
    rf_wr_en   = ex_writes_rd;
    rf_rd_addr = ex_rd;
    rf_rd_data = ex_wb_result;
  end

  // ---------------------------------------------------------------
  // CSR control logic
  // ---------------------------------------------------------------
  always_comb begin
    csr_addr_w   = ex_instr[31:20];
    csr_wdata_w  = csr_src_val;
    csr_op_w     = ex_csr_op_type;
    csr_wen_w    = 1'b0;
    trap_enter   = 1'b0;
    trap_cause   = 32'h0;
    trap_val     = 32'h0;
    trap_epc     = ex_pc;
    mret_exec    = 1'b0;
    instr_retire = 1'b0;

    if (ex_valid && (ex_state == EX_WB)) begin
      instr_retire = !(ex_fetch_err || ex_mem_err || ex_mem_misaligned ||
                       ex_instr_addr_misaligned || !ex_dec_is_legal_eff ||
                       ex_is_ecall || ex_is_ebreak || (irq_pending && !ex_is_csr_op));

      if (ex_fetch_err) begin
        trap_enter = 1'b1;
        trap_cause = 32'd1;
        trap_val   = ex_pc;
        trap_epc   = ex_pc;
        instr_retire = 1'b0;
      end else if (ex_mem_misaligned) begin
        trap_enter = 1'b1;
        trap_cause = ex_is_store ? 32'd6 : 32'd4;
        trap_val   = ex_mem_addr_reg;
        trap_epc   = ex_pc;
        instr_retire = 1'b0;
      end else if (ex_mem_err) begin
        trap_enter = 1'b1;
        trap_cause = ex_is_store ? 32'd7 : 32'd5;
        trap_val   = ex_mem_addr_reg;
        trap_epc   = ex_pc;
        instr_retire = 1'b0;
      end else if (ex_instr_addr_misaligned) begin
        trap_enter = 1'b1;
        trap_cause = 32'd0;
        trap_val   = ex_next_pc_target;
        trap_epc   = ex_pc;
        instr_retire = 1'b0;
      end else if (!ex_dec_is_legal_eff) begin
        trap_enter = 1'b1;
        trap_cause = 32'd2;
        trap_val   = ex_is_compressed ? {16'h0, ex_raw[15:0]} : ex_raw;
        trap_epc   = ex_pc;
        instr_retire = 1'b0;
      end else if (ex_is_csr_op) begin
        csr_wen_w = 1'b1;
      end else if (ex_is_ecall) begin
        trap_enter = 1'b1;
        trap_cause = 32'd11;
        trap_epc   = ex_pc;
        instr_retire = 1'b0;
      end else if (ex_is_ebreak) begin
        trap_enter = 1'b1;
        trap_cause = 32'd3;
        trap_epc   = ex_pc;
        instr_retire = 1'b0;
      end else if (ex_is_mret) begin
        mret_exec = 1'b1;
      end else if (irq_pending && !ex_is_csr_op) begin
        trap_enter = 1'b1;
        trap_cause = irq_cause;
        trap_epc   = ex_pc_sequential;
        instr_retire = 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------
  // Pipeline control
  // ---------------------------------------------------------------
  logic ex_can_accept;
  logic id_to_ex_fire;
  logic wb_single_step_stop;

  assign ex_can_accept = !ex_valid || (ex_valid && (ex_state == EX_WB));
  assign id_to_ex_fire = if_id_valid && ex_can_accept && !ex_redirect &&
                         !halted && !dbg_halt_req && !dbg_single_step;
  assign wb_single_step_stop = dbg_single_step && ex_valid && (ex_state == EX_WB) && instr_retire;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bus_owner        <= BUS_NONE;
      if_state         <= IF_REQ;
      fetch_pc         <= RESET_VECTOR;
      fetch_req_pc     <= RESET_VECTOR;
      fetch_upper_hold <= 16'h0;
      fetch_err_hold   <= 1'b0;
      if_discard_rsp   <= 1'b0;

      if_id_valid         <= 1'b0;
      if_id_pc            <= 32'h0;
      if_id_raw           <= 32'h0000_0013;
      if_id_len           <= 2'd0;
      if_id_is_compressed <= 1'b0;
      if_id_fetch_err     <= 1'b0;

      ex_valid              <= 1'b0;
      ex_state              <= EX_EXEC;
      ex_pc                 <= 32'h0;
      ex_instr              <= 32'h0000_0013;
      ex_raw                <= 32'h0000_0013;
      ex_len                <= 2'd0;
      ex_is_compressed      <= 1'b0;
      ex_fetch_err          <= 1'b0;
      ex_illegal_compressed <= 1'b0;
      ex_rs1                <= 5'd0;
      ex_rs2                <= 5'd0;
      ex_rd                 <= 5'd0;
      ex_imm_i              <= 32'h0;
      ex_imm_s              <= 32'h0;
      ex_imm_b              <= 32'h0;
      ex_imm_u              <= 32'h0;
      ex_imm_j              <= 32'h0;
      ex_opcode             <= 7'h0;
      ex_funct3             <= 3'h0;
      ex_funct7             <= 7'h0;
      ex_is_lui             <= 1'b0;
      ex_is_auipc           <= 1'b0;
      ex_is_jal             <= 1'b0;
      ex_is_jalr            <= 1'b0;
      ex_is_branch          <= 1'b0;
      ex_is_load            <= 1'b0;
      ex_is_store           <= 1'b0;
      ex_is_alu_imm         <= 1'b0;
      ex_is_alu_reg         <= 1'b0;
      ex_is_system          <= 1'b0;
      ex_is_fence           <= 1'b0;
      ex_is_legal           <= 1'b0;
      ex_rs1_val            <= 32'h0;
      ex_rs2_val            <= 32'h0;
      ex_alu_result_reg     <= 32'h0;
      ex_mem_addr_reg       <= 32'h0;
      ex_mem_rdata_reg      <= 32'h0;
      ex_mem_err            <= 1'b0;
      ex_mem_misaligned     <= 1'b0;
      halted                <= 1'b0;
    end else begin
      if (dbg_halt_req) begin
        halted <= 1'b1;
      end else if (dbg_resume_req) begin
        halted <= 1'b0;
      end else if (wb_single_step_stop) begin
        halted <= 1'b1;
      end

      if (data_req_fire) begin
        bus_owner <= BUS_DATA;
        ex_state  <= EX_MEM_WAIT;
      end else if (if_req_fire) begin
        bus_owner <= BUS_IF;
        if (if_state == IF_REQ) begin
          fetch_req_pc <= fetch_pc;
          if_state     <= IF_WAIT;
        end else begin
          if_state     <= IF_SECOND_WAIT;
        end
      end else if (data_rsp_fire || if_rsp_fire) begin
        bus_owner <= BUS_NONE;
      end

      if (if_rsp_fire) begin
        if (if_discard_rsp) begin
          if_discard_rsp <= 1'b0;
          if_state       <= IF_REQ;
        end else if (if_state == IF_WAIT) begin
          fetch_err_hold <= rsp_err;
          if (rsp_err) begin
            if_id_valid         <= 1'b1;
            if_id_pc            <= fetch_req_pc;
            if_id_raw           <= 32'h0000_0013;
            if_id_len           <= 2'd0;
            if_id_is_compressed <= 1'b0;
            if_id_fetch_err     <= 1'b1;
            fetch_pc            <= fetch_req_pc + 32'd4;
            if_state            <= IF_REQ;
          end else if (fetch_req_pc[1] == 1'b0) begin
            if (ENABLE_C && (rsp_rdata[1:0] != 2'b11)) begin
              if_id_valid         <= 1'b1;
              if_id_pc            <= fetch_req_pc;
              if_id_raw           <= {16'h0, rsp_rdata[15:0]};
              if_id_len           <= 2'd2;
              if_id_is_compressed <= 1'b1;
              if_id_fetch_err     <= 1'b0;
              fetch_pc            <= fetch_req_pc + 32'd2;
            end else begin
              if_id_valid         <= 1'b1;
              if_id_pc            <= fetch_req_pc;
              if_id_raw           <= rsp_rdata;
              if_id_len           <= 2'd0;
              if_id_is_compressed <= 1'b0;
              if_id_fetch_err     <= 1'b0;
              fetch_pc            <= fetch_req_pc + 32'd4;
            end
            if_state <= IF_REQ;
          end else begin
            if (ENABLE_C && (rsp_rdata[17:16] != 2'b11)) begin
              if_id_valid         <= 1'b1;
              if_id_pc            <= fetch_req_pc;
              if_id_raw           <= {16'h0, rsp_rdata[31:16]};
              if_id_len           <= 2'd2;
              if_id_is_compressed <= 1'b1;
              if_id_fetch_err     <= 1'b0;
              fetch_pc            <= fetch_req_pc + 32'd2;
              if_state            <= IF_REQ;
            end else begin
              fetch_upper_hold <= rsp_rdata[31:16];
              if_state         <= IF_SECOND_REQ;
            end
          end
        end else if (if_state == IF_SECOND_WAIT) begin
          if_id_valid         <= 1'b1;
          if_id_pc            <= fetch_req_pc;
          if_id_raw           <= {rsp_rdata[15:0], fetch_upper_hold};
          if_id_len           <= 2'd0;
          if_id_is_compressed <= 1'b0;
          if_id_fetch_err     <= fetch_err_hold || rsp_err;
          fetch_pc            <= fetch_req_pc + 32'd4;
          fetch_upper_hold    <= 16'h0;
          fetch_err_hold      <= 1'b0;
          if_state            <= IF_REQ;
        end
      end

      if (ex_valid) begin
        case (ex_state)
          EX_EXEC: begin
            ex_alu_result_reg <= ex_is_m_op ? m_result : alu_result;
            ex_mem_addr_reg   <= alu_result;
            ex_mem_misaligned <= (ex_is_load || ex_is_store) && is_mem_misaligned(alu_result, ex_funct3);
            ex_mem_err        <= 1'b0;
            if ((ex_is_load || ex_is_store) && !is_mem_misaligned(alu_result, ex_funct3)) begin
              ex_state <= EX_MEM_REQ;
            end else begin
              ex_state <= EX_WB;
            end
          end

          EX_MEM_REQ: begin
            if (data_req_fire) begin
              ex_state <= EX_MEM_WAIT;
            end
          end

          EX_MEM_WAIT: begin
            if (data_rsp_fire) begin
              ex_mem_rdata_reg <= rsp_rdata;
              ex_mem_err       <= rsp_err;
              ex_state         <= EX_WB;
            end
          end

          EX_WB: begin
            ex_valid <= 1'b0;
          end

          default: ex_state <= EX_EXEC;
        endcase
      end

      if (ex_redirect) begin
        fetch_pc         <= ex_pc_next;
        if_id_valid      <= 1'b0;
        fetch_upper_hold <= 16'h0;
        fetch_err_hold   <= 1'b0;
        if (bus_owner == BUS_IF) begin
          if_discard_rsp <= 1'b1;
        end else begin
          if_state <= IF_REQ;
        end
      end

      if (id_to_ex_fire) begin
        ex_valid              <= 1'b1;
        ex_state              <= EX_EXEC;
        ex_pc                 <= if_id_pc;
        ex_instr              <= decoded_instr;
        ex_raw                <= if_id_raw;
        ex_len                <= if_id_len;
        ex_is_compressed      <= if_id_is_compressed;
        ex_fetch_err          <= if_id_fetch_err;
        ex_illegal_compressed <= if_id_is_compressed && decomp_illegal;
        ex_rs1                <= dec_rs1;
        ex_rs2                <= dec_rs2;
        ex_rd                 <= dec_rd;
        ex_imm_i              <= dec_imm_i;
        ex_imm_s              <= dec_imm_s;
        ex_imm_b              <= dec_imm_b;
        ex_imm_u              <= dec_imm_u;
        ex_imm_j              <= dec_imm_j;
        ex_opcode             <= dec_opcode;
        ex_funct3             <= dec_funct3;
        ex_funct7             <= dec_funct7;
        ex_is_lui             <= dec_is_lui;
        ex_is_auipc           <= dec_is_auipc;
        ex_is_jal             <= dec_is_jal;
        ex_is_jalr            <= dec_is_jalr;
        ex_is_branch          <= dec_is_branch;
        ex_is_load            <= dec_is_load;
        ex_is_store           <= dec_is_store;
        ex_is_alu_imm         <= dec_is_alu_imm;
        ex_is_alu_reg         <= dec_is_alu_reg;
        ex_is_system          <= dec_is_system;
        ex_is_fence           <= dec_is_fence;
        ex_is_legal           <= dec_is_legal;
        ex_rs1_val            <= id_rs1_val;
        ex_rs2_val            <= id_rs2_val;
        ex_alu_result_reg     <= 32'h0;
        ex_mem_addr_reg       <= 32'h0;
        ex_mem_rdata_reg      <= 32'h0;
        ex_mem_err            <= 1'b0;
        ex_mem_misaligned     <= 1'b0;
        if_id_valid           <= 1'b0;
      end

    end
  end

`ifndef SYNTHESIS
  import "DPI-C" function void dpi_sisrv_retire_insn(
    input int unsigned pc_val,
    input int unsigned insn_val,
    input int unsigned rd_val,
    input int unsigned wdata_val,
    input byte         wr_en
  );

  always_ff @(posedge clk) begin
    if (rst_n && ex_valid && (ex_state == EX_WB) && instr_retire) begin
      dpi_sisrv_retire_insn(
        ex_pc,
        ex_instr,
        rf_rd_addr,
        rf_rd_data,
        {7'b0, rf_wr_en}
      );
    end
  end
`endif

endmodule
