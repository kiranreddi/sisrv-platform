// sisRvCore.sv — Multi-cycle FSM RV32IM core
// Implements complete RV32IM ISA + M-mode CSRs/traps.
// States: FETCH_REQ -> FETCH_WAIT -> DECODE -> EXECUTE -> MEM_REQ -> MEM_WAIT -> WB

module sisRvCore #(
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000,
    parameter bit          ENABLE_M     = 1'b1,
    parameter bit          ENABLE_C     = 1'b1
)(
    input  logic        clk,
    input  logic        rst_n,

    // Debug halt interface
    input  logic        dbg_halt_req,
    input  logic        dbg_resume_req,
    input  logic        dbg_single_step,
    output logic        dbg_halted,

    // Abstract GPR access while halted (from Debug Module)
    input  logic        dbg_abs_valid,
    output logic        dbg_abs_ready,
    input  logic        dbg_abs_write,
    input  logic [4:0]  dbg_abs_regaddr,
    input  logic [31:0] dbg_abs_wdata,
    output logic [31:0] dbg_abs_rdata,

    // External interrupts (CLINT + PLIC)
    input  logic        ext_msip,
    input  logic        ext_mtip,
    input  logic        ext_meip,

    // corebus request
    output logic        req_valid,
    input  logic        req_ready,
    output logic [31:0] req_addr,
    output logic        req_we,
    output logic [31:0] req_wdata,
    output logic [3:0]  req_wstrb,

    // corebus response
    input  logic        rsp_valid,
    output logic        rsp_ready,
    input  logic [31:0] rsp_rdata,
    input  logic        rsp_err
);

  // ---------------------------------------------------------------
  // FSM states
  // ---------------------------------------------------------------
  typedef enum logic [2:0] {
    S_FETCH_REQ  = 3'd0,
    S_FETCH_WAIT = 3'd1,
    S_DECODE     = 3'd2,
    S_EXECUTE    = 3'd3,
    S_MEM_REQ    = 3'd4,
    S_MEM_WAIT   = 3'd5,
    S_WB         = 3'd6
  } state_t;

  state_t state, state_next;

  // ---------------------------------------------------------------
  // ALU operation encoding (used directly; others via {funct7[5],funct3})
  // ---------------------------------------------------------------
  localparam logic [3:0] ALU_ADD = 4'b0000;
  localparam logic [3:0] ALU_SUB = 4'b1000;

  // ---------------------------------------------------------------
  // PC and instruction register
  // ---------------------------------------------------------------
  logic [31:0] pc, pc_next;
  logic [31:0] fetch_word;
  logic [31:0] instr_raw;
  logic [31:0] instr_reg;
  logic [1:0]  instr_len; // 2=16-bit, 0=32-bit (encoded as 2 or 0 for PC add)
  logic        instr_is_compressed;
  logic [31:0] wb_pc;
  logic [1:0]  wb_instr_len;
  logic        wb_is_compressed;
  logic [31:0] wb_instr_raw;
  logic        wb_illegal_compressed;
  logic [15:0] fetch_upper_hold;
  logic        fetch_need_next_word;

  // ---------------------------------------------------------------
  // Decoder wires
  // ---------------------------------------------------------------
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

  logic [31:0] decomp_instr;
  logic        decomp_illegal;
  logic [31:0] decoded_instr;

  logic        decomp_is_c;

  sisDecompress u_decompress (
    .c_instr         (instr_raw[15:0]),
    .instr_o         (decomp_instr),
    .is_compressed_o (decomp_is_c),
    .illegal_o       (decomp_illegal)
  );

  assign decoded_instr = instr_is_compressed ? decomp_instr : instr_raw;

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

  // WB-stage decode from latched instruction (avoids fetch/decode hazards)
  logic [4:0]  wb_dec_rs1, wb_dec_rs2, wb_dec_rd;
  logic [31:0] wb_dec_imm_i, wb_dec_imm_s, wb_dec_imm_b, wb_dec_imm_j, wb_dec_imm_u;
  logic [2:0]  wb_dec_funct3;
  logic [6:0]  wb_dec_opcode;
  logic [6:0]  wb_dec_funct7;
  logic        wb_dec_is_fence;
  logic        wb_dec_is_jal, wb_dec_is_jalr, wb_dec_is_branch;
  logic        wb_dec_is_load, wb_dec_is_store;
  logic        wb_dec_is_alu_reg, wb_dec_is_alu_imm, wb_dec_is_lui, wb_dec_is_auipc;
  logic        wb_dec_is_system, wb_dec_is_legal;
  logic        wb_dec_is_legal_eff;
  logic        wb_branch_taken;
  logic [31:0] wb_branch_target, wb_jal_target, wb_jalr_target, wb_next_pc_target;
  logic [31:0] wb_pc_next;
  logic        wb_overlap_fetch;

  sisDecode #(
    .ENABLE_M (ENABLE_M),
    .ENABLE_C (ENABLE_C)
  ) u_decode_wb (
    .instr     (instr_reg),
    .rs1       (wb_dec_rs1),
    .rs2       (wb_dec_rs2),
    .rd        (wb_dec_rd),
    .imm_i     (wb_dec_imm_i),
    .imm_s     (wb_dec_imm_s),
    .imm_b     (wb_dec_imm_b),
    .imm_u     (wb_dec_imm_u),
    .imm_j     (wb_dec_imm_j),
    .opcode    (wb_dec_opcode),
    .funct3    (wb_dec_funct3),
    .funct7    (wb_dec_funct7),
    .is_lui    (wb_dec_is_lui),
    .is_auipc  (wb_dec_is_auipc),
    .is_jal    (wb_dec_is_jal),
    .is_jalr   (wb_dec_is_jalr),
    .is_branch (wb_dec_is_branch),
    .is_load   (wb_dec_is_load),
    .is_store  (wb_dec_is_store),
    .is_alu_imm(wb_dec_is_alu_imm),
    .is_alu_reg(wb_dec_is_alu_reg),
    .is_system (wb_dec_is_system),
    .is_fence  (wb_dec_is_fence),
    .is_legal  (wb_dec_is_legal)
  );

  assign wb_dec_is_legal_eff = ENABLE_C ? (wb_dec_is_legal && !wb_illegal_compressed) :
                               (wb_dec_is_legal && !wb_is_compressed);

  always_comb begin
    wb_branch_taken = 1'b0;
    if (wb_dec_is_branch) begin
      case (wb_dec_funct3)
        3'b000: wb_branch_taken = (rs1_val == rs2_val);
        3'b001: wb_branch_taken = (rs1_val != rs2_val);
        3'b100: wb_branch_taken = ($signed(rs1_val) < $signed(rs2_val));
        3'b101: wb_branch_taken = ($signed(rs1_val) >= $signed(rs2_val));
        3'b110: wb_branch_taken = (rs1_val < rs2_val);
        3'b111: wb_branch_taken = (rs1_val >= rs2_val);
        default: wb_branch_taken = 1'b0;
      endcase
    end
  end

  assign wb_branch_target = wb_pc + wb_dec_imm_b;
  assign wb_jal_target    = wb_pc + wb_dec_imm_j;
  assign wb_jalr_target   = (rs1_val + wb_dec_imm_i) & 32'hFFFF_FFFE;

  always_comb begin
    wb_next_pc_target = wb_pc + 32'd4;
    if (wb_dec_is_jal) begin
      wb_next_pc_target = wb_jal_target;
    end else if (wb_dec_is_jalr) begin
      wb_next_pc_target = wb_jalr_target;
    end else if (wb_dec_is_branch && wb_branch_taken) begin
      wb_next_pc_target = wb_branch_target;
    end
  end

  wire wb_instr_addr_misaligned = wb_dec_is_legal_eff &&
                                  (wb_dec_is_jal || wb_dec_is_jalr || (wb_dec_is_branch && wb_branch_taken)) &&
                                  (ENABLE_C ? (wb_next_pc_target[0] != 1'b0) :
                                              (wb_is_compressed ? (wb_next_pc_target[0] != 1'b0) :
                                                                 (wb_next_pc_target[1:0] != 2'b00)));

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
  // Latched register values (captured in DECODE)
  // ---------------------------------------------------------------
  logic [31:0] rs1_val, rs2_val;

  // ---------------------------------------------------------------
  // ALU
  // ---------------------------------------------------------------
  logic [31:0] alu_a, alu_b;
  logic [3:0]  alu_op;
  logic [31:0] alu_result;
  logic        alu_zero;
  logic        dec_is_m_op;
  logic [31:0] m_result;

  sisAlu u_alu (
    .a      (alu_a),
    .b      (alu_b),
    .op     (alu_op),
    .result (alu_result),
    .zero   (alu_zero)
  );

  assign dec_is_m_op = ENABLE_M && dec_is_alu_reg && (dec_funct7 == 7'b0000001);

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
        3'b000: rv32m_result = ss_product[31:0]; // MUL
        3'b001: rv32m_result = ss_product[63:32]; // MULH
        3'b010: rv32m_result = su_product[63:32]; // MULHSU
        3'b011: rv32m_result = uu_product[63:32]; // MULHU
        3'b100: begin // DIV
          if (rhs == 32'h0)
            rv32m_result = 32'hFFFF_FFFF;
          else if ((lhs == 32'h8000_0000) && (rhs == 32'hFFFF_FFFF))
            rv32m_result = 32'h8000_0000;
          else
            rv32m_result = lhs_s / rhs_s;
        end
        3'b101: rv32m_result = (rhs == 32'h0) ? 32'hFFFF_FFFF : (lhs / rhs); // DIVU
        3'b110: begin // REM
          if (rhs == 32'h0)
            rv32m_result = lhs;
          else if ((lhs == 32'h8000_0000) && (rhs == 32'hFFFF_FFFF))
            rv32m_result = 32'h0;
          else
            rv32m_result = lhs_s % rhs_s;
        end
        3'b111: rv32m_result = (rhs == 32'h0) ? lhs : (lhs % rhs); // REMU
        default: rv32m_result = 32'h0;
      endcase
    end
  endfunction

  always_comb begin
    m_result = rv32m_result(rs1_val, rs2_val, dec_funct3);
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
  logic        halted;

  sisCsr #(
    .ENABLE_C (ENABLE_C)
  ) u_csr (
    .clk        (clk),
    .rst_n      (rst_n),
    .csr_addr   (csr_addr_w),
    .csr_wdata  (csr_wdata_w),
    .csr_op     (csr_op_w),
    .csr_wen    (csr_wen_w),
    .csr_rdata  (csr_rdata_w),
    .trap_enter (trap_enter),
    .trap_cause (trap_cause),
    .trap_val   (trap_val),
    .trap_epc   (trap_epc),
    .mret_exec  (mret_exec),
    .instr_retire(instr_retire),
    .ext_msip   (ext_msip),
    .ext_mtip   (ext_mtip),
    .ext_meip   (ext_meip),
    .mtvec_out  (mtvec_out),
    .mepc_out   (mepc_out),
    .irq_pending(irq_pending),
    .irq_cause  (irq_cause)
  );

  assign dbg_halted = halted;

  // ---------------------------------------------------------------
  // Execution results (latched in EXECUTE)
  // ---------------------------------------------------------------
  logic [31:0] alu_result_reg;
  logic [31:0] mem_addr_reg;
  logic        branch_taken;
  logic        fetch_err_reg;
  logic        mem_err_reg;
  logic        mem_misaligned_reg;
  logic        instr_addr_misaligned;
  logic [31:0] branch_target;
  logic [31:0] jal_target;
  logic [31:0] jalr_target;
  logic [31:0] next_pc_target;

  // ---------------------------------------------------------------
  // Memory response data (latched in MEM_WAIT)
  // ---------------------------------------------------------------
  logic [31:0] mem_rdata_reg;

  // ---------------------------------------------------------------
  // ALU input mux (combinational, used in EXECUTE state)
  // ---------------------------------------------------------------
  always_comb begin
    alu_a  = rs1_val;
    alu_b  = rs2_val;
    alu_op = ALU_ADD;

    if (dec_is_alu_reg) begin
      alu_a  = rs1_val;
      alu_b  = rs2_val;
      alu_op = {dec_funct7[5], dec_funct3};
    end else if (dec_is_alu_imm) begin
      alu_a  = rs1_val;
      alu_b  = dec_imm_i;
      // For SRAI, funct7[5] differentiates SRL/SRA
      if (dec_funct3 == 3'b101)
        alu_op = {dec_funct7[5], dec_funct3};
      else
        alu_op = {1'b0, dec_funct3};
    end else if (dec_is_load || dec_is_store) begin
      alu_a  = rs1_val;
      alu_b  = dec_is_store ? dec_imm_s : dec_imm_i;
      alu_op = ALU_ADD;
    end else if (dec_is_branch) begin
      alu_a  = rs1_val;
      alu_b  = rs2_val;
      alu_op = ALU_SUB; // for comparison
    end else if (dec_is_lui) begin
      alu_a  = 32'h0;
      alu_b  = dec_imm_u;
      alu_op = ALU_ADD;
    end else if (dec_is_auipc) begin
      alu_a  = pc;
      alu_b  = dec_imm_u;
      alu_op = ALU_ADD;
    end else if (dec_is_jal || dec_is_jalr) begin
      alu_a  = pc;
      alu_b  = 32'd4;
      alu_op = ALU_ADD; // compute return address = pc + 4
    end
  end

  assign branch_target = pc + dec_imm_b;
  assign jal_target    = pc + dec_imm_j;
  assign jalr_target   = (rs1_val + dec_imm_i) & 32'hFFFF_FFFE;

  always_comb begin
    next_pc_target = pc + 32'd4;
    if (dec_is_jal) begin
      next_pc_target = jal_target;
    end else if (dec_is_jalr) begin
      next_pc_target = jalr_target;
    end else if (dec_is_branch && branch_taken) begin
      next_pc_target = branch_target;
    end
  end

  wire dec_is_legal_eff = ENABLE_C ? (dec_is_legal && !(instr_is_compressed && decomp_illegal)) :
                                     (dec_is_legal && !instr_is_compressed);
  // With C extension IALIGN=16: all branch/jump targets need 2-byte alignment only.
  assign instr_addr_misaligned = dec_is_legal_eff &&
                                 (dec_is_jal || dec_is_jalr || (dec_is_branch && branch_taken)) &&
                                 (ENABLE_C ? (next_pc_target[0] != 1'b0) :
                                             (instr_is_compressed ? (next_pc_target[0] != 1'b0) :
                                                                    (next_pc_target[1:0] != 2'b00)));

  function automatic logic is_mem_misaligned(
      input logic [31:0] addr,
      input logic [2:0]  funct3
  );
    begin
      case (funct3[1:0])
        2'b00: is_mem_misaligned = 1'b0;              // byte
        2'b01: is_mem_misaligned = addr[0];           // halfword
        2'b10: is_mem_misaligned = |addr[1:0];        // word
        default: is_mem_misaligned = 1'b0;
      endcase
    end
  endfunction

  // ---------------------------------------------------------------
  // Branch condition evaluation
  // ---------------------------------------------------------------
  always_comb begin
    branch_taken = 1'b0;
    if (dec_is_branch) begin
      case (dec_funct3)
        3'b000: branch_taken = (rs1_val == rs2_val);                          // BEQ
        3'b001: branch_taken = (rs1_val != rs2_val);                          // BNE
        3'b100: branch_taken = ($signed(rs1_val) < $signed(rs2_val));         // BLT
        3'b101: branch_taken = ($signed(rs1_val) >= $signed(rs2_val));        // BGE
        3'b110: branch_taken = (rs1_val < rs2_val);                           // BLTU
        3'b111: branch_taken = (rs1_val >= rs2_val);                          // BGEU
        default: branch_taken = 1'b0;
      endcase
    end
  end

  // ---------------------------------------------------------------
  // SYSTEM instruction decode helpers
  // ---------------------------------------------------------------
  logic is_ecall, is_ebreak, is_mret, is_csr_op;
  assign is_ecall  = dec_is_system && (dec_funct3 == 3'b000) && (decoded_instr[31:20] == 12'h000);
  assign is_ebreak = dec_is_system && (dec_funct3 == 3'b000) && (decoded_instr[31:20] == 12'h001);
  assign is_mret   = dec_is_system && (dec_funct3 == 3'b000) && (decoded_instr[31:20] == 12'h302);
  assign is_csr_op = dec_is_system && (dec_funct3 != 3'b000);

  logic wb_is_ecall, wb_is_ebreak, wb_is_mret, wb_is_csr_op;
  assign wb_is_ecall  = wb_dec_is_system && (wb_dec_funct3 == 3'b000) && (instr_reg[31:20] == 12'h000);
  assign wb_is_ebreak = wb_dec_is_system && (wb_dec_funct3 == 3'b000) && (instr_reg[31:20] == 12'h001);
  assign wb_is_mret   = wb_dec_is_system && (wb_dec_funct3 == 3'b000) && (instr_reg[31:20] == 12'h302);
  assign wb_is_csr_op = wb_dec_is_system && (wb_dec_funct3 != 3'b000);

  always_comb begin
    wb_pc_next = wb_pc + (wb_instr_len == 2'd2 ? 32'd2 : 32'd4);
    if (fetch_err_reg || mem_err_reg || mem_misaligned_reg || wb_instr_addr_misaligned || !wb_dec_is_legal_eff) begin
      wb_pc_next = mtvec_out;
    end else if (wb_dec_is_jal) begin
      wb_pc_next = wb_jal_target;
    end else if (wb_dec_is_jalr) begin
      wb_pc_next = wb_jalr_target;
    end else if (wb_dec_is_branch && wb_branch_taken) begin
      wb_pc_next = wb_branch_target;
    end else if (wb_is_ecall || wb_is_ebreak) begin
      wb_pc_next = mtvec_out;
    end else if (wb_is_mret) begin
      wb_pc_next = mepc_out;
    end else if (irq_pending && !wb_is_csr_op) begin
      wb_pc_next = mtvec_out;
    end
  end

  assign wb_overlap_fetch = (state == S_WB) && !halted && !dbg_halt_req && !dbg_resume_req && !dbg_single_step;

  // CSR operation type from funct3
  // funct3: 001=CSRRW, 010=CSRRS, 011=CSRRC, 101=CSRRWI, 110=CSRRSI, 111=CSRRCI
  logic [1:0] csr_op_type;
  logic [1:0] wb_csr_op_type;
  always_comb begin
    case (dec_funct3[1:0])
      2'b01: csr_op_type = 2'b01; // RW
      2'b10: csr_op_type = 2'b10; // RS
      2'b11: csr_op_type = 2'b11; // RC
      default: csr_op_type = 2'b00;
    endcase
    case (wb_dec_funct3[1:0])
      2'b01: wb_csr_op_type = 2'b01;
      2'b10: wb_csr_op_type = 2'b10;
      2'b11: wb_csr_op_type = 2'b11;
      default: wb_csr_op_type = 2'b00;
    endcase
  end

  logic [31:0] csr_src_val;
  assign csr_src_val = wb_dec_funct3[2] ? {27'b0, wb_dec_rs1} : rs1_val;

  // ---------------------------------------------------------------
  // Store data and write strobe generation
  // ---------------------------------------------------------------
  logic [31:0] store_data;
  logic [3:0]  store_strb;

  always_comb begin
    store_data = 32'h0;
    store_strb = 4'h0;
    case (dec_funct3[1:0])
      2'b00: begin // SB
        case (alu_result_reg[1:0])
          2'b00: begin store_data = {24'b0, rs2_val[7:0]};       store_strb = 4'b0001; end
          2'b01: begin store_data = {16'b0, rs2_val[7:0], 8'b0}; store_strb = 4'b0010; end
          2'b10: begin store_data = {8'b0, rs2_val[7:0], 16'b0}; store_strb = 4'b0100; end
          2'b11: begin store_data = {rs2_val[7:0], 24'b0};       store_strb = 4'b1000; end
        endcase
      end
      2'b01: begin // SH
        case (alu_result_reg[1])
          1'b0: begin store_data = {16'b0, rs2_val[15:0]};       store_strb = 4'b0011; end
          1'b1: begin store_data = {rs2_val[15:0], 16'b0};       store_strb = 4'b1100; end
        endcase
      end
      2'b10: begin // SW
        store_data = rs2_val;
        store_strb = 4'b1111;
      end
      default: ;
    endcase
  end

  // ---------------------------------------------------------------
  // Load data extraction (sign/zero extension)
  // ---------------------------------------------------------------
  logic [31:0] load_result;

  always_comb begin
    load_result = 32'h0;
    case (dec_funct3)
      3'b000: begin // LB
        case (mem_addr_reg[1:0])
          2'b00: load_result = {{24{mem_rdata_reg[7]}},  mem_rdata_reg[7:0]};
          2'b01: load_result = {{24{mem_rdata_reg[15]}}, mem_rdata_reg[15:8]};
          2'b10: load_result = {{24{mem_rdata_reg[23]}}, mem_rdata_reg[23:16]};
          2'b11: load_result = {{24{mem_rdata_reg[31]}}, mem_rdata_reg[31:24]};
        endcase
      end
      3'b001: begin // LH
        case (mem_addr_reg[1])
          1'b0: load_result = {{16{mem_rdata_reg[15]}}, mem_rdata_reg[15:0]};
          1'b1: load_result = {{16{mem_rdata_reg[31]}}, mem_rdata_reg[31:16]};
        endcase
      end
      3'b010: load_result = mem_rdata_reg; // LW
      3'b100: begin // LBU
        case (mem_addr_reg[1:0])
          2'b00: load_result = {24'b0, mem_rdata_reg[7:0]};
          2'b01: load_result = {24'b0, mem_rdata_reg[15:8]};
          2'b10: load_result = {24'b0, mem_rdata_reg[23:16]};
          2'b11: load_result = {24'b0, mem_rdata_reg[31:24]};
        endcase
      end
      3'b101: begin // LHU
        case (mem_addr_reg[1])
          1'b0: load_result = {16'b0, mem_rdata_reg[15:0]};
          1'b1: load_result = {16'b0, mem_rdata_reg[31:16]};
        endcase
      end
      default: load_result = mem_rdata_reg;
    endcase
  end

  // ---------------------------------------------------------------
  // Corebus output mux
  // ---------------------------------------------------------------
  logic        out_req_valid;
  logic [31:0] out_req_addr;
  logic        out_req_we;
  logic [31:0] out_req_wdata;
  logic [3:0]  out_req_wstrb;
  logic        out_rsp_ready;

  assign req_valid = out_req_valid;
  assign req_addr  = out_req_addr;
  assign req_we    = out_req_we;
  assign req_wdata = out_req_wdata;
  assign req_wstrb = out_req_wstrb;
  assign rsp_ready = out_rsp_ready;

  // ---------------------------------------------------------------
  // Main FSM
  // ---------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S_FETCH_REQ;
      pc    <= RESET_VECTOR;
      instr_reg            <= 32'h0000_0013;
      instr_raw            <= 32'h0000_0013;
      instr_is_compressed  <= 1'b0;
      instr_len            <= 2'd0;
      halted               <= 1'b0;
      rs1_val       <= 32'h0;
      rs2_val       <= 32'h0;
      alu_result_reg <= 32'h0;
      mem_addr_reg  <= 32'h0;
      mem_rdata_reg <= 32'h0;
      fetch_err_reg <= 1'b0;
      mem_err_reg   <= 1'b0;
      mem_misaligned_reg <= 1'b0;
      fetch_upper_hold    <= 16'h0;
      fetch_need_next_word <= 1'b0;
    end else if (dbg_halt_req) begin
      halted <= 1'b1;
    end else if (dbg_resume_req) begin
      halted <= 1'b0;
    end else if (dbg_single_step && state == S_WB && !halted) begin
      halted <= 1'b1;
    end else begin
      case (state)
        // ----- FETCH REQUEST -----
        S_FETCH_REQ: begin
          if (!halted && req_ready) begin
            fetch_err_reg <= 1'b0;
            mem_err_reg   <= 1'b0;
            mem_misaligned_reg <= 1'b0;
            state <= S_FETCH_WAIT;
          end
        end

        // ----- FETCH WAIT (wait for response) -----
        S_FETCH_WAIT: begin
          if (rsp_valid) begin
            fetch_word <= rsp_rdata;
            fetch_err_reg <= rsp_err;
            if (fetch_need_next_word) begin
              instr_raw           <= {rsp_rdata[15:0], fetch_upper_hold};
              instr_is_compressed <= 1'b0;
              instr_len           <= 2'd0;
              fetch_need_next_word <= 1'b0;
              state               <= S_DECODE;
            end else if (pc[1] == 1'b0) begin
              if (ENABLE_C && (rsp_rdata[1:0] != 2'b11)) begin
                instr_raw           <= {16'h0, rsp_rdata[15:0]};
                instr_is_compressed <= 1'b1;
                instr_len           <= 2'd2;
              end else begin
                instr_raw           <= rsp_rdata;
                instr_is_compressed <= 1'b0;
                instr_len           <= 2'd0;
              end
              state <= S_DECODE;
            end else begin
              if (ENABLE_C && (rsp_rdata[17:16] != 2'b11)) begin
                instr_raw           <= {16'h0, rsp_rdata[31:16]};
                instr_is_compressed <= 1'b1;
                instr_len           <= 2'd2;
                state               <= S_DECODE;
              end else begin
                fetch_upper_hold     <= rsp_rdata[31:16];
                fetch_need_next_word <= 1'b1;
                state                <= S_FETCH_REQ;
              end
            end
          end
        end

        // ----- DECODE -----
        S_DECODE: begin
          instr_reg         <= decoded_instr;
          wb_pc             <= pc;
          wb_instr_len      <= instr_len;
          wb_is_compressed  <= instr_is_compressed;
          wb_instr_raw      <= instr_raw;
          wb_illegal_compressed <= instr_is_compressed && decomp_illegal;
          rs1_val <= rf_rs1_data;
          rs2_val <= rf_rs2_data;
          state   <= S_EXECUTE;
        end

        // ----- EXECUTE -----
        S_EXECUTE: begin
          alu_result_reg <= dec_is_m_op ? m_result : alu_result;
          mem_addr_reg   <= alu_result; // used for load/store address
          mem_misaligned_reg <= (dec_is_load || dec_is_store) && is_mem_misaligned(alu_result, dec_funct3);

          if ((dec_is_load || dec_is_store) && !is_mem_misaligned(alu_result, dec_funct3)) begin
            state <= S_MEM_REQ;
          end else begin
            state <= S_WB;
          end
        end

        // ----- MEMORY REQUEST -----
        S_MEM_REQ: begin
          if (req_ready) begin
            state <= S_MEM_WAIT;
          end
        end

        // ----- MEMORY WAIT -----
        S_MEM_WAIT: begin
          if (rsp_valid) begin
            mem_rdata_reg <= rsp_rdata;
            mem_err_reg   <= rsp_err;
            state         <= S_WB;
          end
        end

        // ----- WRITEBACK + PC UPDATE -----
        S_WB: begin
          // PC update (illegal instructions trap before any control-flow effect).
          // When the fabric accepts it, the next fetch request is issued in this
          // same WB cycle and the core advances directly to FETCH_WAIT.
          pc <= wb_pc_next;
          fetch_need_next_word <= 1'b0;
          fetch_upper_hold     <= 16'h0;
          fetch_err_reg        <= 1'b0;
          mem_err_reg          <= 1'b0;
          mem_misaligned_reg   <= 1'b0;

          state <= (wb_overlap_fetch && req_ready) ? S_FETCH_WAIT : S_FETCH_REQ;
        end

        default: state <= S_FETCH_REQ;
      endcase
    end
  end

  // ---------------------------------------------------------------
  // Corebus drive logic (combinational based on state)
  // ---------------------------------------------------------------
  always_comb begin
    out_req_valid = 1'b0;
    out_req_addr  = 32'h0;
    out_req_we    = 1'b0;
    out_req_wdata = 32'h0;
    out_req_wstrb = 4'h0;
    out_rsp_ready = 1'b0;

    case (state)
      S_FETCH_REQ: begin
        out_req_valid = 1'b1;
        out_req_addr  = fetch_need_next_word ? ({pc[31:2], 2'b00} + 32'd4) : {pc[31:2], 2'b00};
        out_req_we    = 1'b0;
        out_req_wstrb = 4'h0;
        out_rsp_ready = 1'b0;
      end
      S_FETCH_WAIT: begin
        out_rsp_ready = 1'b1;
      end
      S_MEM_REQ: begin
        out_req_valid = 1'b1;
        out_req_addr  = alu_result_reg;
        out_req_we    = dec_is_store;
        out_req_wdata = store_data;
        out_req_wstrb = dec_is_store ? store_strb : 4'h0;
        out_rsp_ready = 1'b0;
      end
      S_MEM_WAIT: begin
        out_rsp_ready = 1'b1;
      end
      S_WB: begin
        if (wb_overlap_fetch) begin
          out_req_valid = 1'b1;
          out_req_addr  = {wb_pc_next[31:2], 2'b00};
          out_req_we    = 1'b0;
          out_req_wstrb = 4'h0;
        end
      end
      default: ;
    endcase
  end

  // ---------------------------------------------------------------
  // Register file write logic
  // ---------------------------------------------------------------
  always_comb begin
    rf_wr_en  = 1'b0;
    rf_rd_addr = dec_rd;
    rf_rd_data = 32'h0;

    if (state == S_WB) begin
      rf_rd_addr = wb_dec_rd;
      if (!fetch_err_reg && !mem_err_reg && !mem_misaligned_reg && !wb_instr_addr_misaligned &&
          wb_dec_is_legal_eff && (wb_dec_is_alu_reg || wb_dec_is_alu_imm)) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = alu_result_reg;
      end else if (!fetch_err_reg && !mem_err_reg && !mem_misaligned_reg && !wb_instr_addr_misaligned &&
                   wb_dec_is_legal_eff && (wb_dec_is_lui || wb_dec_is_auipc)) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = alu_result_reg;
      end else if (!fetch_err_reg && !mem_err_reg && !mem_misaligned_reg && !wb_instr_addr_misaligned &&
                   wb_dec_is_legal_eff && (wb_dec_is_jal || wb_dec_is_jalr)) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = alu_result_reg; // pc+4 (return address)
      end else if (!fetch_err_reg && !mem_err_reg && !mem_misaligned_reg && !wb_instr_addr_misaligned &&
                   wb_dec_is_legal_eff && wb_dec_is_load) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = load_result;
      end else if (!fetch_err_reg && !mem_err_reg && !mem_misaligned_reg && !wb_instr_addr_misaligned &&
                   wb_dec_is_legal_eff && wb_is_csr_op) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = csr_rdata_w;
      end
      // stores, branches, ecall, ebreak, fence: no writeback
    end
  end

  // ---------------------------------------------------------------
  // CSR control logic
  // ---------------------------------------------------------------
  always_comb begin
    csr_addr_w  = instr_reg[31:20];
    csr_wdata_w = csr_src_val;
    csr_op_w    = wb_csr_op_type;
    csr_wen_w   = 1'b0;
    trap_enter  = 1'b0;
    trap_cause  = 32'h0;
    trap_val    = 32'h0;
    trap_epc    = wb_pc;
    mret_exec   = 1'b0;
    instr_retire = 1'b0;

    if (state == S_WB) begin
      instr_retire = !(fetch_err_reg || mem_err_reg || mem_misaligned_reg || wb_instr_addr_misaligned || !wb_dec_is_legal_eff ||
                       wb_is_ecall || wb_is_ebreak || irq_pending);

      if (fetch_err_reg) begin
        trap_enter = 1'b1;
        trap_cause = 32'd1; // Instruction access fault
        trap_val   = wb_pc;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (mem_misaligned_reg) begin
        trap_enter = 1'b1;
        trap_cause = wb_dec_is_store ? 32'd6 : 32'd4; // Store/load address misaligned
        trap_val   = mem_addr_reg;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (mem_err_reg) begin
        trap_enter = 1'b1;
        trap_cause = wb_dec_is_store ? 32'd7 : 32'd5; // Store/load access fault
        trap_val   = mem_addr_reg;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_instr_addr_misaligned) begin
        trap_enter = 1'b1;
        trap_cause = 32'd0; // Instruction address misaligned
        trap_val   = wb_next_pc_target;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (!wb_dec_is_legal_eff) begin
        trap_enter = 1'b1;
        trap_cause = 32'd2;
        trap_val   = wb_is_compressed ? {16'h0, wb_instr_raw[15:0]} : wb_instr_raw;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_dec_is_legal_eff && wb_is_csr_op) begin
        csr_wen_w = 1'b1;
      end else if (wb_is_ecall) begin
        trap_enter = 1'b1;
        trap_cause = 32'd11; // Environment call from M-mode
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_is_ebreak) begin
        trap_enter = 1'b1;
        trap_cause = 32'd3; // Breakpoint
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_is_mret) begin
        mret_exec = 1'b1;
      end else if (irq_pending) begin
        trap_enter = 1'b1;
        trap_cause = irq_cause;
        trap_epc   = wb_pc + (wb_instr_len == 2'd2 ? 32'd2 : 32'd4);
        instr_retire = 1'b0;
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
    if (rst_n && state == S_WB && instr_retire) begin
      dpi_sisrv_retire_insn(
        wb_pc,
        instr_reg,
        rf_rd_addr,
        rf_rd_data,
        {7'b0, rf_wr_en}
      );
    end
  end
`endif

endmodule
