// sisRvCore.sv - RV32IMC core with an in-order pipeline.
// Stages:
//   IF        - instruction fetch, including RV32C halfword assembly
//   ID        - decode and register read
//   EX/MEM    - execute and data-memory request/response
//   WB        - writeback, CSR/trap retirement
//
// Instruction fetch and data memory use independent corebus-style ports. Each
// port remains single-outstanding.

module sisRvCore #(
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000,
    parameter bit          ENABLE_A     = 1'b1,
    parameter bit          ENABLE_M     = 1'b1,
    parameter bit          ENABLE_C     = 1'b1,
    parameter int          NTRIGGER     = 2,
    parameter bit          ENABLE_U     = 1'b1,
    parameter int          PMP_ENTRIES = 8
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

    output logic        i_req_valid,
    input  logic        i_req_ready,
    output logic [31:0] i_req_addr,
    input  logic        i_rsp_valid,
    output logic        i_rsp_ready,
    input  logic [31:0] i_rsp_rdata,
    input  logic        i_rsp_err,

    output logic        d_req_valid,
    input  logic        d_req_ready,
    output logic [31:0] d_req_addr,
    output logic        d_req_we,
    output logic [31:0] d_req_wdata,
    output logic [3:0]  d_req_wstrb,
    input  logic        d_rsp_valid,
    output logic        d_rsp_ready,
    input  logic [31:0] d_rsp_rdata,
    input  logic        d_rsp_err
);

  localparam logic [3:0] ALU_ADD = 4'b0000;
  localparam logic [3:0] ALU_SUB = 4'b1000;

  typedef enum logic [1:0] {
    IF_REQ        = 2'd0,
    IF_WAIT       = 2'd1,
    IF_SECOND_REQ = 2'd2,
    IF_SECOND_WAIT= 2'd3
  } if_state_t;

  typedef enum logic [2:0] {
    EX_EXEC           = 3'd0,
    EX_MEM_REQ        = 3'd1,
    EX_MEM_WAIT       = 3'd2,
    EX_AMO_STORE_REQ  = 3'd3,
    EX_AMO_STORE_WAIT = 3'd4,
    EX_WB             = 3'd5
  } ex_state_t;

  // ---------------------------------------------------------------
  // IF stage
  // ---------------------------------------------------------------
  if_state_t  if_state;
  logic [31:0] fetch_pc;
  logic [31:0] fetch_req_pc;
  logic [15:0] fetch_upper_hold;
  logic        fetch_err_hold;
  logic        if_discard_rsp;

  // M9 single-word instruction fetch buffer: retains the last fetched word so the
  // second compressed halfword of a word (and the resident low half of a sequential
  // straddling 32-bit instruction) are served without a redundant bus round-trip.
  // Invalidated on any redirect, so a buffered word is always same-privilege and
  // same-instruction-memory as the access that hits it.
  logic        fbuf_valid;
  logic [29:0] fbuf_word_addr;   // PA[31:2] of the buffered word
  logic [31:0] fbuf_data;        // the fetched 32-bit word
  logic        fbuf_err;         // fetch fault (bus err or PMP deny) latched with the word

  // M9 sequential prefetch slot: holds the next sequential word (fbuf word + 1),
  // fetched ahead on otherwise-idle I-bus cycles so back-to-back word fetches do not
  // each pay the IF_REQ->IF_WAIT round trip. On a sequential advance the prefetched
  // word is promoted into fbuf with no demand fetch. Demand fetch has bus priority;
  // single-outstanding is preserved (at most one of {demand, prefetch} in flight).
  logic        pf_valid;         // prefetch slot holds a valid word
  logic [29:0] pf_addr;          // PA[31:2] of the prefetched word
  logic [31:0] pf_data;
  logic        pf_err;
  logic        pf_inflight;      // a prefetch request is outstanding on the I-bus
  logic [29:0] pf_inflight_addr; // word address of the in-flight prefetch
  logic        pf_discard;       // drop the in-flight prefetch response (redirect)

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
  logic        dec_is_atomic;
  logic [4:0]  dec_atomic_funct5;
  logic        dec_aq, dec_rl;

  sisDecode #(
    .ENABLE_A (ENABLE_A),
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
    .is_system     (dec_is_system),
    .is_fence      (dec_is_fence),
    .is_atomic     (dec_is_atomic),
    .atomic_funct5 (dec_atomic_funct5),
    .aq            (dec_aq),
    .rl            (dec_rl),
    .is_legal      (dec_is_legal)
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
  // EX/MEM stage registers
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
  logic        ex_is_atomic;
  logic [4:0]  ex_atomic_funct5;
  logic        ex_aq, ex_rl;
  logic        ex_is_lr, ex_is_sc, ex_is_amo_op;
  logic        ex_sc_succeeds;
  logic        ex_amo_load_done;
  logic        ex_amo_store_to_wb;

  logic [31:0] ex_rs1_val, ex_rs2_val;
  logic [31:0] ex_alu_result_reg;
  logic [31:0] ex_mem_addr_reg;
  logic [31:0] ex_mem_rdata_reg;
  logic        ex_mem_err;
  logic        ex_mem_misaligned;

  // ---------------------------------------------------------------
  // WB/retire stage registers
  // ---------------------------------------------------------------
  logic        wb_valid;
  logic [31:0] wb_pc;
  logic [31:0] wb_instr;
  logic [31:0] wb_raw;
  logic [1:0]  wb_len;
  logic        wb_is_compressed;
  logic        wb_fetch_err;
  logic        wb_illegal_compressed;

  logic [4:0]  wb_rd;
  logic [2:0]  wb_funct3;
  logic        wb_is_lui, wb_is_auipc, wb_is_jal, wb_is_jalr;
  logic        wb_is_load, wb_is_store;
  logic        wb_is_alu_imm, wb_is_alu_reg;
  logic        wb_is_legal;
  logic        wb_is_atomic;
  logic        wb_is_lr, wb_is_sc, wb_is_amo_op;

  logic [31:0] wb_alu_result;
  logic [31:0] wb_mem_addr;
  logic [31:0] wb_mem_rdata;
  logic        wb_mem_err;
  logic        wb_mem_misaligned;
  logic        wb_instr_addr_misaligned;
  logic [31:0] lr_reservation_addr;
  logic        lr_reservation_valid;
  logic [31:0] amo_old_val;
  logic [31:0] wb_amo_old_val;
  logic [31:0] wb_sc_result;
  logic [31:0] amo_new_val;
  logic        wb_dec_is_legal_eff;
  logic        wb_is_ecall, wb_is_ebreak, wb_is_mret, wb_is_csr_op;
  logic        wb_trigger_hit;
  logic [1:0]  wb_csr_op_type;
  logic [31:0] wb_csr_src_val;
  logic [31:0] wb_pc_sequential;
  logic [31:0] wb_next_pc_target;
  logic [31:0] wb_pc_next;
  logic        wb_irq_pending;
  logic [31:0] wb_irq_cause;
  logic [1:0]  ex_priv, wb_priv;
  logic        ex_is_wfi;
  logic        ex_priv_illegal;
  logic        ex_legal_eff;
  logic        ex_pmp_d_fault;
  logic        ex_d_access_raw;
  logic        ex_d_misaligned;
  logic        pmp_d_allow;
  logic        pmp_fetch_allow;
  logic [31:0] fetch_pmp_addr;

  localparam logic [1:0] PRIV_M = 2'b11;
  localparam logic [1:0] PRIV_U = 2'b00;
  logic        halted;
  logic        step_active;
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
    end else if (ex_is_atomic) begin
      alu_a  = ex_rs1_val;  // atomics: address = rs1, no immediate offset
      alu_b  = 32'h0;
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

  // AMO result computation: new memory value = f(old_val, rs2)
  always_comb begin : amo_compute
    amo_new_val = amo_old_val;
    if (ex_is_atomic) begin
      case (ex_atomic_funct5)
        5'b00001: amo_new_val = ex_rs2_val;                                                       // AMOSWAP
        5'b00000: amo_new_val = amo_old_val + ex_rs2_val;                                         // AMOADD
        5'b00100: amo_new_val = amo_old_val ^ ex_rs2_val;                                         // AMOXOR
        5'b01100: amo_new_val = amo_old_val & ex_rs2_val;                                         // AMOAND
        5'b01000: amo_new_val = amo_old_val | ex_rs2_val;                                         // AMOOR
        5'b10000: amo_new_val = ($signed(amo_old_val) < $signed(ex_rs2_val)) ? amo_old_val : ex_rs2_val; // AMOMIN
        5'b10100: amo_new_val = ($signed(amo_old_val) > $signed(ex_rs2_val)) ? amo_old_val : ex_rs2_val; // AMOMAX
        5'b11000: amo_new_val = (amo_old_val < ex_rs2_val) ? amo_old_val : ex_rs2_val;           // AMOMINU
        5'b11100: amo_new_val = (amo_old_val > ex_rs2_val) ? amo_old_val : ex_rs2_val;           // AMOMAXU
        default:  amo_new_val = amo_old_val;
      endcase
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
  logic [1:0]  priv_o;
  logic        mstatus_tw_o;
  logic        mstatus_mprv_o;
  logic [1:0]  mstatus_mpp_o;
  logic [2:0]  mcounteren_o;
  logic [PMP_ENTRIES-1:0][7:0]  pmpcfg_bus;
  logic [PMP_ENTRIES-1:0][31:0] pmpaddr_bus;
  logic [NTRIGGER-1:0][31:0]    trig_tdata1;
  logic [NTRIGGER-1:0][31:0]    trig_tdata2;
  logic [NTRIGGER-1:0]          trig_hit_set;

  sisCsr #(
    .ENABLE_A     (ENABLE_A),
    .ENABLE_C     (ENABLE_C),
    .ENABLE_U     (ENABLE_U),
    .PMP_ENTRIES  (PMP_ENTRIES),
    .NTRIGGER     (NTRIGGER)
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
    .irq_cause   (irq_cause),
    .priv_o      (priv_o),
    .mstatus_tw_o(mstatus_tw_o),
    .mstatus_mprv_o(mstatus_mprv_o),
    .mstatus_mpp_o(mstatus_mpp_o),
    .mcounteren_o(mcounteren_o),
    .pmpcfg_o    (pmpcfg_bus),
    .pmpaddr_o   (pmpaddr_bus),
    .trig_tdata1_o(trig_tdata1),
    .trig_tdata2_o(trig_tdata2),
    .trig_hit_set (trig_hit_set)
  );

  logic [1:0] d_pmp_priv;
  always_comb begin
    if (priv_o == PRIV_M) begin
      if (mstatus_mprv_o)
        d_pmp_priv = mstatus_mpp_o;
      else
        d_pmp_priv = PRIV_M;
    end else begin
      d_pmp_priv = priv_o;
    end
  end

  // PMP-check the word whose response is being consumed this cycle: the straddle
  // second word (SECOND_WAIT), the demand word (WAIT), or — when a prefetch response
  // lands — the prefetched word. Single-outstanding makes these mutually exclusive.
  assign fetch_pmp_addr = (if_state == IF_SECOND_WAIT) ? ({fetch_req_pc[31:2], 2'b00} + 32'd4) :
                          (if_state == IF_WAIT)        ? {fetch_req_pc[31:2], 2'b00} :
                          pf_inflight                  ? {pf_inflight_addr, 2'b00} :
                                                         {fetch_req_pc[31:2], 2'b00};

  logic [31:0] pmp_d_addr;

  assign pmp_d_addr = ((ex_state == EX_EXEC) && ex_valid) ? alu_result : ex_alu_result_reg;

  sisPmp #(
    .PMP_ENTRIES(PMP_ENTRIES)
  ) u_pmp_d (
    .pmpcfg  (pmpcfg_bus),
    .pmpaddr (pmpaddr_bus),
    .addr    (pmp_d_addr),
    .priv    (d_pmp_priv),
    .req_r   (ex_is_load || ex_is_lr || ex_is_amo_op),
    .req_w   (ex_is_store || ex_is_sc || ex_is_amo_op),
    .req_x   (1'b0),
    .allow   (pmp_d_allow)
  );

  sisPmp #(
    .PMP_ENTRIES(PMP_ENTRIES)
  ) u_pmp_i (
    .pmpcfg  (pmpcfg_bus),
    .pmpaddr (pmpaddr_bus),
    .addr    (fetch_pmp_addr),
    .priv    (priv_o),
    .req_r   (1'b0),
    .req_w   (1'b0),
    .req_x   (1'b1),
    .allow   (pmp_fetch_allow)
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
  logic [31:0] mtvec_base;
  logic        mtvec_vectored;
  logic [31:0] mtvec_irq_vector;
  logic        ex_redirect;
  logic [1:0]  ex_csr_op_type;
  logic [31:0] ex_csr_src_val;
  logic [31:0] wb_load_result;
  logic [31:0] store_data;
  logic [3:0]  store_strb;
  logic [31:0] wb_result;
  logic        wb_writes_rd;
  logic        ex_mem_access;
  logic        ex_mem_requesting;
  logic        ex_exec_to_wb;
  logic        ex_mem_to_wb;
  logic        ex_to_wb_fire;
  logic [31:0] ex_mem_req_addr;
  logic [31:0] ex_complete_alu_result;
  logic [31:0] ex_complete_mem_addr;
  logic [31:0] ex_complete_mem_rdata;
  logic        ex_complete_mem_err;
  logic        ex_complete_mem_misaligned;
  logic        ex_forward_valid;
  logic [31:0] ex_forward_result;
  logic        id_depends_ex_rd;
  logic        id_ex_hazard;

  assign ex_pc_sequential = ex_pc + ((ex_len == 2'd2) ? 32'd2 : 32'd4);
  assign ex_is_ecall  = ex_is_system && (ex_funct3 == 3'b000) && (ex_instr[31:20] == 12'h000);
  assign ex_is_ebreak = ex_is_system && (ex_funct3 == 3'b000) && (ex_instr[31:20] == 12'h001);
  assign ex_is_mret   = ex_is_system && (ex_funct3 == 3'b000) && (ex_instr[31:20] == 12'h302);
  assign ex_is_wfi    = ex_is_system && (ex_funct3 == 3'b000) && (ex_instr[31:20] == 12'h105);
  assign ex_is_csr_op = ex_is_system && (ex_funct3 != 3'b000);
  assign ex_dec_is_legal_eff = ENABLE_C ? (ex_is_legal && !ex_illegal_compressed) :
                                          (ex_is_legal && !ex_is_compressed);

  wire [1:0] ex_csr_req_priv = ex_instr[29:28];
  wire       ex_csr_writes = ex_is_csr_op &&
                             ((ex_instr[31:30] == 2'b01) ||
                              ((ex_rs1 != 5'd0) && (ex_instr[31:30] != 2'b01)));
  wire       ex_csr_ro_viol = ex_is_csr_op && (ex_instr[31:30] == 2'b11) && ex_csr_writes;
  wire       ex_csr_priv_viol = ENABLE_U && ex_is_csr_op &&
                                ((ex_csr_req_priv == 2'b11 && ex_priv != PRIV_M) ||
                                 (ex_csr_req_priv == 2'b01) ||
                                 (ex_csr_req_priv == 2'b10));
  wire [11:0] ex_csr_addr_f = ex_instr[31:20];
  wire       ex_mcounteren_block = ENABLE_U && ex_is_csr_op && (ex_priv == PRIV_U) &&
                                   ((((ex_csr_addr_f == 12'hC00) || (ex_csr_addr_f == 12'hC80)) &&
                                     !mcounteren_o[0]) ||
                                    (((ex_csr_addr_f == 12'hC02) || (ex_csr_addr_f == 12'hC82)) &&
                                     !mcounteren_o[2]));

  assign ex_priv_illegal = ENABLE_U &&
                           ((ex_is_mret && (ex_priv != PRIV_M)) ||
                            (ex_is_wfi && (ex_priv != PRIV_M) && mstatus_tw_o) ||
                            ex_csr_priv_viol || ex_csr_ro_viol || ex_mcounteren_block);
  assign ex_legal_eff = ex_dec_is_legal_eff && !ex_priv_illegal;

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

  assign ex_instr_addr_misaligned = ex_legal_eff &&
                                    (ex_is_jal || ex_is_jalr || (ex_is_branch && ex_branch_taken)) &&
                                    (ENABLE_C ? (ex_next_pc_target[0] != 1'b0) :
                                                (ex_is_compressed ? (ex_next_pc_target[0] != 1'b0) :
                                                                    (ex_next_pc_target[1:0] != 2'b00)));

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

  // Atomic sub-type helpers
  assign ex_is_lr     = ex_is_atomic && (ex_atomic_funct5 == 5'b00010);
  assign ex_is_sc     = ex_is_atomic && (ex_atomic_funct5 == 5'b00011);
  assign ex_is_amo_op = ex_is_atomic && !ex_is_lr && !ex_is_sc;
  assign ex_sc_succeeds = ex_is_sc && lr_reservation_valid &&
                          (lr_reservation_addr == ex_rs1_val);
  // Fires the cycle the AMO load completes; bus mux must switch to write in same cycle
  assign ex_amo_load_done = ex_is_amo_op && (ex_state == EX_MEM_WAIT) && data_rsp_fire;

  assign ex_d_access_raw = ex_is_load || ex_is_store || ex_is_lr ||
                           (ex_is_sc && ex_sc_succeeds) || ex_is_amo_op;
  assign ex_pmp_d_fault  = ex_d_access_raw &&
                           !is_mem_misaligned(alu_result, ex_funct3) && !pmp_d_allow;
  // Debug trigger match (type-2 mcontrol, equality, action=0 -> breakpoint exception).
  // execute: PC == tdata2; load/store: access address == tdata2; gated by m/u priv bits.
  // A firing trigger behaves like a breakpoint before the instruction commits.
  logic ex_trigger_hit;
  always_comb begin
    ex_trigger_hit = 1'b0;
    trig_hit_set   = '0;
    if (ex_valid && (ex_state == EX_EXEC) && ex_dec_is_legal_eff) begin
      for (int t = 0; t < NTRIGGER; t = t + 1) begin
        automatic logic m_load  = trig_tdata1[t][0];
        automatic logic m_store = trig_tdata1[t][1];
        automatic logic m_exec  = trig_tdata1[t][2];
        automatic logic en_u    = trig_tdata1[t][3];
        automatic logic en_m    = trig_tdata1[t][6];
        automatic logic priv_ok = (en_m && (ex_priv == PRIV_M)) ||
                                  (en_u && (ex_priv == PRIV_U));
        automatic logic is_store_acc = ex_is_store || ex_is_sc || ex_is_amo_op;
        if (priv_ok) begin
          if (m_exec && (ex_pc == trig_tdata2[t])) begin
            ex_trigger_hit = 1'b1; trig_hit_set[t] = 1'b1;
          end
          if (m_load && ex_is_load && (alu_result == trig_tdata2[t])) begin
            ex_trigger_hit = 1'b1; trig_hit_set[t] = 1'b1;
          end
          if (m_store && is_store_acc && (alu_result == trig_tdata2[t])) begin
            ex_trigger_hit = 1'b1; trig_hit_set[t] = 1'b1;
          end
        end
      end
    end
  end
  // A firing trigger suppresses the memory access (it traps instead).
  assign ex_mem_access   = ex_d_access_raw && !ex_trigger_hit &&
                           !is_mem_misaligned(alu_result, ex_funct3) && pmp_d_allow;
  assign ex_mem_requesting = ex_valid &&
                             (((ex_state == EX_EXEC) && ex_mem_access) ||
                              (ex_state == EX_MEM_REQ) ||
                              (ex_state == EX_AMO_STORE_REQ));
  assign ex_exec_to_wb       = ex_valid && (ex_state == EX_EXEC) && !ex_mem_access;
  assign ex_mem_to_wb        = ex_valid && (ex_state == EX_MEM_WAIT) && data_rsp_fire && !ex_is_amo_op;
  assign ex_amo_store_to_wb  = ex_valid && (ex_state == EX_AMO_STORE_WAIT) && data_rsp_fire;
  assign ex_to_wb_fire       = ex_exec_to_wb || ex_mem_to_wb || ex_amo_store_to_wb;
  assign ex_mem_req_addr = ((ex_state == EX_EXEC) && ex_mem_access) ? alu_result : ex_alu_result_reg;

  assign ex_complete_alu_result     = ex_exec_to_wb ? (ex_is_m_op ? m_result : alu_result) : ex_alu_result_reg;
  assign ex_complete_mem_addr       = ex_exec_to_wb ? alu_result : ex_mem_addr_reg;
  assign ex_complete_mem_rdata      = ex_mem_to_wb ? d_rsp_rdata : ex_mem_rdata_reg;
  assign ex_complete_mem_err        = (ex_exec_to_wb && ex_pmp_d_fault) ? 1'b1 :
                                      ex_mem_to_wb       ? d_rsp_err :
                                      ex_amo_store_to_wb ? d_rsp_err : ex_mem_err;
  assign ex_complete_mem_misaligned = ex_exec_to_wb ?
                                      ((ex_is_load || ex_is_store || ex_is_atomic) &&
                                       is_mem_misaligned(alu_result, ex_funct3)) :
                                      ex_mem_misaligned;

  assign mtvec_base       = {mtvec_out[31:2], 2'b00};
  assign mtvec_vectored   = mtvec_out[0];
  assign mtvec_irq_vector = mtvec_base + {25'b0, irq_cause[4:0], 2'b00};

  always_comb begin
    ex_pc_next = ex_pc_sequential;
    if (ex_trigger_hit || ex_fetch_err || ex_complete_mem_err || ex_complete_mem_misaligned ||
        ex_instr_addr_misaligned || !ex_legal_eff) begin
      ex_pc_next = mtvec_base;   // exceptions always go to BASE (spec: even in vectored mode)
    end else if (irq_pending && !ex_is_csr_op) begin
      ex_pc_next = mtvec_vectored ? mtvec_irq_vector : mtvec_base;
    end else if (ex_is_jal) begin
      ex_pc_next = ex_jal_target;
    end else if (ex_is_jalr) begin
      ex_pc_next = ex_jalr_target;
    end else if (ex_is_branch && ex_branch_taken) begin
      ex_pc_next = ex_branch_target;
    end else if (ex_is_ecall || ex_is_ebreak) begin
      ex_pc_next = mtvec_base;   // synchronous exception: BASE only
    end else if (ex_is_mret) begin
      ex_pc_next = mepc_out;
    end
  end

  assign ex_redirect = ex_to_wb_fire && !wb_single_step_stop &&
                       (ex_trigger_hit ||
                        ex_fetch_err || ex_complete_mem_err || ex_complete_mem_misaligned ||
                        ex_instr_addr_misaligned || !ex_legal_eff ||
                        ex_is_jal || ex_is_jalr || (ex_is_branch && ex_branch_taken) ||
                        ex_is_ecall || ex_is_ebreak || ex_is_mret ||
                        (irq_pending && !ex_is_csr_op));

  always_comb begin
    store_data = 32'h0;
    store_strb = 4'h0;
    case (ex_funct3[1:0])
      2'b00: begin
        case (ex_mem_req_addr[1:0])
          2'b00: begin store_data = {24'b0, ex_rs2_val[7:0]};       store_strb = 4'b0001; end
          2'b01: begin store_data = {16'b0, ex_rs2_val[7:0], 8'b0}; store_strb = 4'b0010; end
          2'b10: begin store_data = {8'b0, ex_rs2_val[7:0], 16'b0}; store_strb = 4'b0100; end
          2'b11: begin store_data = {ex_rs2_val[7:0], 24'b0};       store_strb = 4'b1000; end
        endcase
      end
      2'b01: begin
        case (ex_mem_req_addr[1])
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
    wb_load_result = 32'h0;
    case (wb_funct3)
      3'b000: begin
        case (wb_mem_addr[1:0])
          2'b00: wb_load_result = {{24{wb_mem_rdata[7]}},  wb_mem_rdata[7:0]};
          2'b01: wb_load_result = {{24{wb_mem_rdata[15]}}, wb_mem_rdata[15:8]};
          2'b10: wb_load_result = {{24{wb_mem_rdata[23]}}, wb_mem_rdata[23:16]};
          2'b11: wb_load_result = {{24{wb_mem_rdata[31]}}, wb_mem_rdata[31:24]};
        endcase
      end
      3'b001: begin
        case (wb_mem_addr[1])
          1'b0: wb_load_result = {{16{wb_mem_rdata[15]}}, wb_mem_rdata[15:0]};
          1'b1: wb_load_result = {{16{wb_mem_rdata[31]}}, wb_mem_rdata[31:16]};
        endcase
      end
      3'b010: wb_load_result = wb_mem_rdata;
      3'b100: begin
        case (wb_mem_addr[1:0])
          2'b00: wb_load_result = {24'b0, wb_mem_rdata[7:0]};
          2'b01: wb_load_result = {24'b0, wb_mem_rdata[15:8]};
          2'b10: wb_load_result = {24'b0, wb_mem_rdata[23:16]};
          2'b11: wb_load_result = {24'b0, wb_mem_rdata[31:24]};
        endcase
      end
      3'b101: begin
        case (wb_mem_addr[1])
          1'b0: wb_load_result = {16'b0, wb_mem_rdata[15:0]};
          1'b1: wb_load_result = {16'b0, wb_mem_rdata[31:16]};
        endcase
      end
      default: wb_load_result = wb_mem_rdata;
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

  assign ex_csr_src_val = ex_funct3[2] ? {27'b0, ex_rs1} : ex_rs1_val;

  always_comb begin
    wb_result = wb_alu_result;
    if (wb_is_load || wb_is_lr) begin
      wb_result = wb_load_result;    // LR.W: funct3=010 word load, same path as LW
    end else if (wb_is_csr_op) begin
      wb_result = csr_rdata_w;
    end else if (wb_is_sc) begin
      wb_result = wb_sc_result;      // SC.W: 0=success, 1=failure
    end else if (wb_is_amo_op) begin
      wb_result = wb_amo_old_val;    // AMO: return old memory value to rd
    end
  end

  assign wb_writes_rd = wb_valid && !wb_trigger_hit &&
                        !wb_fetch_err && !wb_mem_err && !wb_mem_misaligned &&
                        !wb_instr_addr_misaligned && wb_dec_is_legal_eff &&
                        (wb_is_alu_reg || wb_is_alu_imm || wb_is_lui ||
                         wb_is_auipc || wb_is_jal || wb_is_jalr ||
                         wb_is_load || wb_is_csr_op ||
                         wb_is_lr || wb_is_sc || wb_is_amo_op);

  assign ex_forward_valid = ex_valid && (ex_state == EX_EXEC) && !ex_trigger_hit &&
                            !ex_fetch_err && !ex_instr_addr_misaligned &&
                            ex_dec_is_legal_eff && !ex_is_load && !ex_is_store &&
                            !ex_is_atomic && !ex_is_csr_op &&
                            (ex_is_alu_reg || ex_is_alu_imm || ex_is_lui ||
                             ex_is_auipc || ex_is_jal || ex_is_jalr);
  assign ex_forward_result = ex_is_m_op ? m_result : alu_result;

  assign id_depends_ex_rd = if_id_valid && ex_valid && (ex_rd != 5'd0) &&
                            ((ex_rd == dec_rs1) || (ex_rd == dec_rs2));
  assign id_ex_hazard = id_depends_ex_rd && !ex_forward_valid;

  // ID reads see WB and same-cycle EX completion through these bypasses.
  logic [31:0] id_rs1_val, id_rs2_val;
  always_comb begin
    id_rs1_val = rf_rs1_data;
    id_rs2_val = rf_rs2_data;
    if (wb_writes_rd && (wb_rd != 5'd0) && (wb_rd == dec_rs1)) begin
      id_rs1_val = wb_result;
    end
    if (wb_writes_rd && (wb_rd != 5'd0) && (wb_rd == dec_rs2)) begin
      id_rs2_val = wb_result;
    end
    if (ex_forward_valid && (ex_rd != 5'd0) && (ex_rd == dec_rs1)) begin
      id_rs1_val = ex_forward_result;
    end
    if (ex_forward_valid && (ex_rd != 5'd0) && (ex_rd == dec_rs2)) begin
      id_rs2_val = ex_forward_result;
    end
  end

  // ---------------------------------------------------------------
  // Corebus arbitration
  // ---------------------------------------------------------------
  logic data_req_active;
  logic if_req_active;
  logic data_req_fire;
  logic if_req_fire;
  logic pf_req_fire;
  logic data_rsp_fire;
  logic if_rsp_fire;

  assign data_req_active = ex_mem_requesting;

  // Fetch-buffer / prefetch hits: the word the PC needs is already resident.
  wire        fbuf_hit  = fbuf_valid && (fbuf_word_addr == fetch_pc[31:2]);
  wire        pfbuf_hit = pf_valid   && (pf_addr        == fetch_pc[31:2]);
  wire        buf_hit   = fbuf_hit || pfbuf_hit;
  wire        if_can_accept_fetch = !halted && !dbg_halt_req && (!dbg_single_step || step_active) &&
                                    !wb_single_step_stop && !ex_redirect &&
                                    (!if_id_valid || id_to_ex_fire);
  // Serve the instruction from a resident word this cycle (no demand bus request).
  wire        if_serve_buf = if_can_accept_fetch && (if_state == IF_REQ) && buf_hit;

  // Demand fetch only on a full miss (or for the straddle second word).
  assign if_req_active   = if_can_accept_fetch &&
                           (((if_state == IF_REQ) && !buf_hit) || (if_state == IF_SECOND_REQ));

  // Sequential prefetch: target the word after the one the PC is in. Issue it on
  // I-bus cycles the demand path isn't using, when it isn't already resident/in-flight.
  wire [29:0] pf_target  = fetch_pc[31:2] + 30'd1;
  wire        pf_want     = if_can_accept_fetch && !pf_inflight &&
                            !(pf_valid && (pf_addr == pf_target)) &&
                            !(fbuf_valid && (fbuf_word_addr == pf_target));
  // Demand has bus priority; prefetch only in the normal fetch states (never while a
  // straddle second-word fetch is being resolved, which keeps response routing simple).
  wire        pf_issue    = pf_want && !if_req_active &&
                            ((if_state == IF_REQ) || (if_state == IF_WAIT));
  // A prefetch response is the in-flight one whenever the demand FSM isn't waiting.
  wire        pf_rsp_fire = pf_inflight && i_rsp_valid &&
                            (if_state != IF_WAIT) && (if_state != IF_SECOND_WAIT);

  always_comb begin
    // Demand fetch (priority) or, on idle bus cycles, the sequential prefetch.
    i_req_valid = if_req_active || pf_issue;
    if (if_req_active)
      i_req_addr = (if_state == IF_SECOND_REQ) ? ({fetch_req_pc[31:2], 2'b00} + 32'd4) :
                                                 {fetch_pc[31:2], 2'b00};
    else
      i_req_addr = {pf_target, 2'b00};

    d_req_valid = data_req_active;
    d_req_addr  = ex_mem_req_addr;
    d_req_we    = ex_is_store;
    d_req_wdata = store_data;
    d_req_wstrb = ex_is_store ? store_strb : 4'h0;

    // Atomic instruction bus overrides
    if (ex_is_atomic) begin
      if (ex_state == EX_AMO_STORE_REQ || ex_state == EX_AMO_STORE_WAIT) begin
        // AMO phase 2: write modified value back to same address
        d_req_we    = 1'b1;
        d_req_wdata = amo_new_val;
        d_req_wstrb = 4'b1111;
      end else begin
        // LR.W / AMO phase 1: issue read; SC.W success: issue write of rs2
        d_req_we    = ex_is_sc;
        d_req_wdata = ex_rs2_val;   // SC.W writes rs2 to memory
        d_req_wstrb = ex_is_sc ? 4'b1111 : 4'h0;
      end
    end
  end

  assign i_rsp_ready   = (if_state == IF_WAIT) || (if_state == IF_SECOND_WAIT) || pf_inflight;
  assign d_rsp_ready   = ex_valid && ((ex_state == EX_MEM_WAIT) || (ex_state == EX_AMO_STORE_WAIT));
  assign data_req_fire = data_req_active && d_req_ready;
  assign if_req_fire   = if_req_active && i_req_ready;
  assign pf_req_fire   = pf_issue && i_req_ready;   // prefetch request accepted
  assign data_rsp_fire = d_rsp_valid && d_rsp_ready;
  assign if_rsp_fire   = i_rsp_valid && (if_state == IF_WAIT || if_state == IF_SECOND_WAIT);

  // A full instruction word is available to decode this cycle, from either a bus
  // response (IF_WAIT) or a resident-word hit (IF_REQ, fbuf or prefetch). Exclusive.
  wire        if_word_ready = (if_rsp_fire && !if_discard_rsp && (if_state == IF_WAIT)) || if_serve_buf;
  wire [31:0] if_serve_data = fbuf_hit ? fbuf_data : pf_data;   // prefer fbuf on a tie
  wire        if_serve_err  = fbuf_hit ? fbuf_err  : pf_err;
  wire [31:0] if_word_data  = if_serve_buf ? if_serve_data : i_rsp_rdata;
  wire        if_word_err   = if_serve_buf ? if_serve_err  : (i_rsp_err || !pmp_fetch_allow);
  wire [31:0] if_word_pc    = if_serve_buf ? fetch_pc      : fetch_req_pc;
  // Serving from the prefetch slot (not fbuf) promotes that word into fbuf this cycle.
  wire        if_serve_pf   = if_serve_buf && !fbuf_hit && pfbuf_hit;
  // A current word actually emits an instruction into if_id (vs. the straddle first
  // half, which only kicks off the second fetch and emits nothing this cycle).
  wire        if_word_emits = if_word_ready &&
                              (if_word_err || (if_word_pc[1] == 1'b0) ||
                               (ENABLE_C && (if_word_data[17:16] != 2'b11)));
  // The IF stage places a new instruction into if_id this cycle (bus, buffer, or
  // straddle second half). With the fetch buffer the IF stage can issue back-to-back
  // with id_to_ex_fire, so this guards the if_id_valid clear from clobbering it.
  wire        if_produces   = if_word_emits ||
                              (if_rsp_fire && !if_discard_rsp && (if_state == IF_SECOND_WAIT));

  // ---------------------------------------------------------------
  // Register file write logic
  // ---------------------------------------------------------------
  always_comb begin
    rf_wr_en   = wb_writes_rd;
    rf_rd_addr = wb_rd;
    rf_rd_data = wb_result;
  end

  // ---------------------------------------------------------------
  // CSR control logic
  // ---------------------------------------------------------------
  always_comb begin
    csr_addr_w   = wb_instr[31:20];
    csr_wdata_w  = wb_csr_src_val;
    csr_op_w     = wb_csr_op_type;
    csr_wen_w    = 1'b0;
    trap_enter   = 1'b0;
    trap_cause   = 32'h0;
    trap_val     = 32'h0;
    trap_epc     = wb_pc;
    mret_exec    = 1'b0;
    instr_retire = 1'b0;

    if (wb_valid) begin
      instr_retire = !(wb_fetch_err || wb_trigger_hit || wb_mem_err || wb_mem_misaligned ||
                       wb_instr_addr_misaligned || !wb_dec_is_legal_eff ||
                       wb_is_ecall || wb_is_ebreak || (wb_irq_pending && !wb_is_csr_op));

      if (wb_fetch_err) begin
        trap_enter = 1'b1;
        trap_cause = 32'd1;
        trap_val   = wb_pc;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_trigger_hit) begin
        // Hardware trigger (mcontrol) -> breakpoint exception before the instruction.
        trap_enter = 1'b1;
        trap_cause = 32'd3;
        trap_val   = 32'h0;        // Debug 0.13: mtval = 0 for mcontrol breakpoints
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_mem_misaligned) begin
        trap_enter = 1'b1;
        trap_cause = wb_is_store ? 32'd6 : 32'd4;
        trap_val   = wb_mem_addr;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_mem_err) begin
        trap_enter = 1'b1;
        trap_cause = (wb_is_store || wb_is_amo_op || wb_is_sc) ? 32'd7 : 32'd5;
        trap_val   = wb_mem_addr;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_instr_addr_misaligned) begin
        trap_enter = 1'b1;
        trap_cause = 32'd0;
        trap_val   = wb_next_pc_target;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (!wb_dec_is_legal_eff) begin
        trap_enter = 1'b1;
        trap_cause = 32'd2;
        trap_val   = wb_is_compressed ? {16'h0, wb_raw[15:0]} : wb_raw;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_is_csr_op) begin
        csr_wen_w = 1'b1;
      end else if (wb_is_ecall) begin
        trap_enter = 1'b1;
        trap_cause = (wb_priv == PRIV_M) ? 32'd11 : 32'd8;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_is_ebreak) begin
        trap_enter = 1'b1;
        trap_cause = 32'd3;
        trap_epc   = wb_pc;
        instr_retire = 1'b0;
      end else if (wb_is_mret) begin
        mret_exec = 1'b1;
      end else if (wb_irq_pending && !wb_is_csr_op) begin
        trap_enter = 1'b1;
        trap_cause = wb_irq_cause;
        trap_epc   = wb_next_pc_target;
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

  assign ex_can_accept = !ex_valid || ex_to_wb_fire;
  assign id_to_ex_fire = if_id_valid && ex_can_accept && !ex_redirect &&
                         !id_ex_hazard &&
                         !wb_single_step_stop &&
                         !halted && !dbg_halt_req && (!dbg_single_step || step_active);
  assign wb_single_step_stop = step_active && wb_valid && instr_retire;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      if_state         <= IF_REQ;
      fetch_pc         <= RESET_VECTOR;
      fetch_req_pc     <= RESET_VECTOR;
      fetch_upper_hold <= 16'h0;
      fetch_err_hold   <= 1'b0;
      if_discard_rsp   <= 1'b0;
      fbuf_valid       <= 1'b0;
      fbuf_word_addr   <= 30'h0;
      fbuf_data        <= 32'h0;
      fbuf_err         <= 1'b0;
      pf_valid         <= 1'b0;
      pf_addr          <= 30'h0;
      pf_data          <= 32'h0;
      pf_err           <= 1'b0;
      pf_inflight      <= 1'b0;
      pf_inflight_addr <= 30'h0;
      pf_discard       <= 1'b0;

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
      ex_is_atomic          <= 1'b0;
      ex_atomic_funct5      <= 5'h0;
      ex_aq                 <= 1'b0;
      ex_rl                 <= 1'b0;
      lr_reservation_valid  <= 1'b0;
      lr_reservation_addr   <= 32'h0;
      amo_old_val           <= 32'h0;

      wb_valid                <= 1'b0;
      wb_pc                   <= 32'h0;
      wb_instr                <= 32'h0000_0013;
      wb_raw                  <= 32'h0000_0013;
      wb_len                  <= 2'd0;
      wb_is_compressed        <= 1'b0;
      wb_fetch_err            <= 1'b0;
      wb_illegal_compressed   <= 1'b0;
      wb_rd                   <= 5'd0;
      wb_funct3               <= 3'h0;
      wb_is_lui               <= 1'b0;
      wb_is_auipc             <= 1'b0;
      wb_is_jal               <= 1'b0;
      wb_is_jalr              <= 1'b0;
      wb_is_load              <= 1'b0;
      wb_is_store             <= 1'b0;
      wb_is_alu_imm           <= 1'b0;
      wb_is_alu_reg           <= 1'b0;
      wb_is_legal             <= 1'b0;
      wb_is_atomic            <= 1'b0;
      wb_is_lr                <= 1'b0;
      wb_is_sc                <= 1'b0;
      wb_is_amo_op            <= 1'b0;
      wb_amo_old_val          <= 32'h0;
      wb_sc_result            <= 32'h0;
      wb_alu_result           <= 32'h0;
      wb_mem_addr             <= 32'h0;
      wb_mem_rdata            <= 32'h0;
      wb_mem_err              <= 1'b0;
      wb_mem_misaligned       <= 1'b0;
      wb_instr_addr_misaligned <= 1'b0;
      wb_dec_is_legal_eff     <= 1'b0;
      wb_is_ecall             <= 1'b0;
      wb_is_ebreak            <= 1'b0;
      wb_trigger_hit          <= 1'b0;
      wb_is_mret              <= 1'b0;
      wb_is_csr_op            <= 1'b0;
      wb_csr_op_type          <= 2'b00;
      wb_csr_src_val          <= 32'h0;
      wb_pc_sequential        <= 32'h0;
      wb_next_pc_target       <= 32'h0;
      wb_pc_next              <= 32'h0;
      wb_irq_pending          <= 1'b0;
      wb_irq_cause            <= 32'h0;

      halted                <= 1'b0;
      step_active           <= 1'b0;
    end else begin
      wb_valid <= 1'b0;

      if (dbg_halt_req) begin
        halted      <= 1'b1;
        step_active <= 1'b0;
      end else if (dbg_resume_req) begin
        step_active <= halted && dbg_single_step;
        halted      <= 1'b0;
      end else if (wb_single_step_stop) begin
        halted      <= 1'b1;
        step_active <= 1'b0;
      end

      if (if_req_fire) begin
        if (if_state == IF_REQ) begin
          fetch_req_pc <= fetch_pc;
          if_state     <= IF_WAIT;
        end else begin
          if_state     <= IF_SECOND_WAIT;
        end
      end

      // Prefetch request accepted on an idle bus cycle.
      if (pf_req_fire) begin
        pf_inflight      <= 1'b1;
        pf_inflight_addr <= pf_target;
      end

      // Prefetch response: fill the prefetch slot (or drop it if a redirect intervened).
      if (pf_rsp_fire) begin
        pf_inflight <= 1'b0;
        if (pf_discard) begin
          pf_discard <= 1'b0;
        end else begin
          pf_valid <= 1'b1;
          pf_addr  <= pf_inflight_addr;
          pf_data  <= i_rsp_rdata;
          pf_err   <= i_rsp_err || !pmp_fetch_allow;
        end
      end

      // Promote the prefetched word into fbuf when it is served (sequential advance).
      if (if_serve_pf) begin
        fbuf_valid     <= 1'b1;
        fbuf_word_addr <= pf_addr;
        fbuf_data      <= pf_data;
        fbuf_err       <= pf_err;
        pf_valid       <= 1'b0;
      end

      // Discard an in-flight bus response that a redirect invalidated.
      if (if_rsp_fire && if_discard_rsp) begin
        if_discard_rsp <= 1'b0;
        if_state       <= IF_REQ;
      end

      // Fill the fetch buffer from every consumed (non-discarded) bus response.
      if (if_rsp_fire && !if_discard_rsp) begin
        fbuf_valid     <= 1'b1;
        fbuf_data      <= i_rsp_rdata;
        fbuf_err       <= i_rsp_err || !pmp_fetch_allow;
        fbuf_word_addr <= (if_state == IF_SECOND_WAIT) ? (fetch_req_pc[31:2] + 30'd1)
                                                       : fetch_req_pc[31:2];
      end

      // Assemble an instruction from the current word — bus response (IF_WAIT) or
      // a fetch-buffer hit (IF_REQ). if_word_* select the source.
      if (if_word_ready) begin
        fetch_err_hold <= if_word_err;
        if (if_word_err) begin
          if_id_valid         <= 1'b1;
          if_id_pc            <= if_word_pc;
          if_id_raw           <= 32'h0000_0013;
          if_id_len           <= 2'd0;
          if_id_is_compressed <= 1'b0;
          if_id_fetch_err     <= 1'b1;
          fetch_pc            <= if_word_pc + 32'd4;
          if_state            <= IF_REQ;
        end else if (if_word_pc[1] == 1'b0) begin
          if (ENABLE_C && (if_word_data[1:0] != 2'b11)) begin
            if_id_valid         <= 1'b1;
            if_id_pc            <= if_word_pc;
            if_id_raw           <= {16'h0, if_word_data[15:0]};
            if_id_len           <= 2'd2;
            if_id_is_compressed <= 1'b1;
            if_id_fetch_err     <= 1'b0;
            fetch_pc            <= if_word_pc + 32'd2;
          end else begin
            if_id_valid         <= 1'b1;
            if_id_pc            <= if_word_pc;
            if_id_raw           <= if_word_data;
            if_id_len           <= 2'd0;
            if_id_is_compressed <= 1'b0;
            if_id_fetch_err     <= 1'b0;
            fetch_pc            <= if_word_pc + 32'd4;
          end
          if_state <= IF_REQ;
        end else begin
          if (ENABLE_C && (if_word_data[17:16] != 2'b11)) begin
            if_id_valid         <= 1'b1;
            if_id_pc            <= if_word_pc;
            if_id_raw           <= {16'h0, if_word_data[31:16]};
            if_id_len           <= 2'd2;
            if_id_is_compressed <= 1'b1;
            if_id_fetch_err     <= 1'b0;
            fetch_pc            <= if_word_pc + 32'd2;
            if_state            <= IF_REQ;
          end else begin
            // Straddling 32-bit instruction: hold the resident low half and fetch
            // the next word. fetch_req_pc anchors the IF_SECOND_REQ address.
            fetch_upper_hold <= if_word_data[31:16];
            fetch_req_pc     <= if_word_pc;
            if_state         <= IF_SECOND_REQ;
          end
        end
      end

      // Second half of a straddling 32-bit instruction arrives from the bus.
      if (if_rsp_fire && !if_discard_rsp && (if_state == IF_SECOND_WAIT)) begin
        if_id_valid         <= 1'b1;
        if_id_pc            <= fetch_req_pc;
        if_id_raw           <= {i_rsp_rdata[15:0], fetch_upper_hold};
        if_id_len           <= 2'd0;
        if_id_is_compressed <= 1'b0;
        if_id_fetch_err     <= fetch_err_hold || i_rsp_err || !pmp_fetch_allow;
        fetch_pc            <= fetch_req_pc + 32'd4;
        fetch_upper_hold    <= 16'h0;
        fetch_err_hold      <= 1'b0;
        if_state            <= IF_REQ;
      end

	      if (ex_valid) begin
	        case (ex_state)
	          EX_EXEC: begin
	            ex_alu_result_reg <= ex_is_m_op ? m_result : alu_result;
	            ex_mem_addr_reg   <= alu_result;
	            ex_mem_misaligned <= (ex_is_load || ex_is_store) && is_mem_misaligned(alu_result, ex_funct3);
	            ex_mem_err        <= 1'b0;
	            if (ex_mem_access) begin
	              ex_state <= data_req_fire ? EX_MEM_WAIT : EX_MEM_REQ;
	            end else if (ex_to_wb_fire) begin
	              ex_valid <= 1'b0;
	            end
	          end

	          EX_MEM_REQ: begin
	            if (data_req_fire) begin
	              ex_state <= EX_MEM_WAIT;
	            end
	          end

	          EX_MEM_WAIT: begin
	            if (data_rsp_fire) begin
	              ex_mem_rdata_reg <= d_rsp_rdata;
	              ex_mem_err       <= d_rsp_err;
	              if (ex_is_atomic && !d_rsp_err) begin
	                if (ex_is_lr) begin
	                  lr_reservation_valid <= 1'b1;
	                  lr_reservation_addr  <= ex_alu_result_reg;
	                  ex_valid             <= 1'b0;
	                end else if (ex_is_amo_op) begin
	                  amo_old_val <= d_rsp_rdata;
	                  ex_state    <= EX_AMO_STORE_REQ;  // always wait 1 cycle for amo_old_val to settle
	                end else begin
	                  // SC.W successful store response
	                  lr_reservation_valid <= 1'b0;
	                  ex_valid             <= 1'b0;
	                end
	              end else begin
	                if (ex_is_sc) lr_reservation_valid <= 1'b0;
	                ex_valid <= 1'b0;
	              end
	            end
	          end

	          EX_AMO_STORE_REQ: begin
	            if (data_req_fire) ex_state <= EX_AMO_STORE_WAIT;
	          end

	          EX_AMO_STORE_WAIT: begin
	            if (data_rsp_fire) begin
	              ex_mem_err <= d_rsp_err;
	              ex_valid   <= 1'b0;
	            end
	          end

	          EX_WB: begin
	            ex_valid <= 1'b0;
	          end

	          default: ex_state <= EX_EXEC;
	        endcase
	      end

	      if (ex_to_wb_fire) begin
	        wb_valid                <= 1'b1;
        wb_pc                   <= ex_pc;
        wb_instr                <= ex_instr;
        wb_raw                  <= ex_raw;
        wb_len                  <= ex_len;
        wb_is_compressed        <= ex_is_compressed;
        wb_fetch_err            <= ex_fetch_err;
        wb_illegal_compressed   <= ex_illegal_compressed;
        wb_rd                   <= ex_rd;
        wb_funct3               <= ex_funct3;
        wb_is_lui               <= ex_is_lui;
        wb_is_auipc             <= ex_is_auipc;
        wb_is_jal               <= ex_is_jal;
        wb_is_jalr              <= ex_is_jalr;
        wb_is_load              <= ex_is_load;
        wb_is_store             <= ex_is_store;
        wb_is_alu_imm           <= ex_is_alu_imm;
        wb_is_alu_reg           <= ex_is_alu_reg;
        wb_is_legal             <= ex_is_legal;
        wb_is_atomic            <= ex_is_atomic;
        wb_is_lr                <= ex_is_lr;
        wb_is_sc                <= ex_is_sc;
        wb_is_amo_op            <= ex_is_amo_op;
        wb_amo_old_val          <= amo_old_val;
        wb_sc_result            <= ex_sc_succeeds ? 32'h0 : 32'h1;
        wb_alu_result           <= ex_complete_alu_result;
        wb_mem_addr             <= ex_complete_mem_addr;
        wb_mem_rdata            <= ex_complete_mem_rdata;
        wb_mem_err              <= ex_complete_mem_err;
        wb_mem_misaligned       <= ex_complete_mem_misaligned;
        wb_instr_addr_misaligned <= ex_instr_addr_misaligned;
        wb_dec_is_legal_eff     <= ex_legal_eff;
        wb_is_ecall             <= ex_is_ecall;
        wb_is_ebreak            <= ex_is_ebreak;
        wb_trigger_hit          <= ex_trigger_hit;
        wb_is_mret              <= ex_is_mret;
        wb_is_csr_op            <= ex_is_csr_op;
        wb_csr_op_type          <= ex_csr_op_type;
        wb_csr_src_val          <= ex_csr_src_val;
        wb_pc_sequential        <= ex_pc_sequential;
        wb_next_pc_target       <= ex_next_pc_target;
        wb_pc_next              <= ex_pc_next;
        wb_irq_pending          <= irq_pending;
        wb_irq_cause            <= irq_cause;
        wb_priv                 <= ex_priv;
      end

	      if (ex_redirect) begin
	        lr_reservation_valid <= 1'b0;  // spec: reservation cleared on any trap/interrupt
	        fetch_pc         <= ex_pc_next;
	        if_id_valid      <= 1'b0;
	        ex_valid         <= 1'b0;
	        ex_state         <= EX_EXEC;
	        fetch_upper_hold <= 16'h0;
        fetch_err_hold   <= 1'b0;
        fbuf_valid       <= 1'b0;  // privilege/target may change — drop the buffered word
        pf_valid         <= 1'b0;  // drop the prefetched word (wrong path / stale privilege)
        if (pf_inflight && !pf_rsp_fire) pf_discard <= 1'b1;  // drop the in-flight prefetch
        if (((if_state == IF_WAIT) || (if_state == IF_SECOND_WAIT)) && !if_rsp_fire) begin
          if_discard_rsp <= 1'b1;
        end else begin
          if_discard_rsp <= 1'b0;
          if_state <= IF_REQ;
        end
      end

      if (wb_single_step_stop) begin
        fetch_pc         <= wb_pc_next;
        wb_valid         <= 1'b0;
        ex_valid         <= 1'b0;
        ex_state         <= EX_EXEC;
        if_id_valid      <= 1'b0;
        fetch_upper_hold <= 16'h0;
        fetch_err_hold   <= 1'b0;
        fbuf_valid       <= 1'b0;
        pf_valid         <= 1'b0;
        if (pf_inflight && !pf_rsp_fire) pf_discard <= 1'b1;
        if (((if_state == IF_WAIT) || (if_state == IF_SECOND_WAIT)) && !if_rsp_fire) begin
          if_discard_rsp <= 1'b1;
        end else begin
          if_discard_rsp <= 1'b0;
          if_state       <= IF_REQ;
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
        ex_is_atomic          <= dec_is_atomic;
        ex_atomic_funct5      <= dec_atomic_funct5;
        ex_aq                 <= dec_aq;
        ex_rl                 <= dec_rl;
        ex_priv               <= priv_o;
        ex_rs1_val            <= id_rs1_val;
        ex_rs2_val            <= id_rs2_val;
        ex_alu_result_reg     <= 32'h0;
        ex_mem_addr_reg       <= 32'h0;
        ex_mem_rdata_reg      <= 32'h0;
        ex_mem_err            <= 1'b0;
        ex_mem_misaligned     <= 1'b0;
        if (!if_produces) if_id_valid <= 1'b0;  // don't clobber a same-cycle IF issue
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
    if (rst_n && wb_valid && instr_retire) begin
      dpi_sisrv_retire_insn(
        wb_pc,
        wb_instr,
        rf_rd_addr,
        rf_rd_data,
        {7'b0, rf_wr_en}
      );
    end
  end
`endif

endmodule
