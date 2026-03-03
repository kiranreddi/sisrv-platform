// sisRvCore.sv — Multi-cycle FSM RV32I core
// Implements complete RV32I ISA + M-mode CSRs/traps.
// States: FETCH_REQ -> FETCH_WAIT -> DECODE -> EXECUTE -> MEM_REQ -> MEM_WAIT -> WB

module sisRvCore #(
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000
)(
    input  logic        clk,
    input  logic        rst_n,

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
  logic [31:0] instr_reg;

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

  sisDecode u_decode (
    .instr     (instr_reg),
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
    .rd_data  (rf_rd_data)
  );

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

  sisAlu u_alu (
    .a      (alu_a),
    .b      (alu_b),
    .op     (alu_op),
    .result (alu_result),
    .zero   (alu_zero)
  );

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
  logic [31:0] mtvec_out;
  logic [31:0] mepc_out;

  sisCsr u_csr (
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
    .mtvec_out  (mtvec_out),
    .mepc_out   (mepc_out)
  );

  // ---------------------------------------------------------------
  // Execution results (latched in EXECUTE)
  // ---------------------------------------------------------------
  logic [31:0] alu_result_reg;
  logic [31:0] mem_addr_reg;
  logic        branch_taken;

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
  assign is_ecall  = dec_is_system && (dec_funct3 == 3'b000) && (instr_reg[31:20] == 12'h000);
  assign is_ebreak = dec_is_system && (dec_funct3 == 3'b000) && (instr_reg[31:20] == 12'h001);
  assign is_mret   = dec_is_system && (dec_funct3 == 3'b000) && (instr_reg[31:20] == 12'h302);
  assign is_csr_op = dec_is_system && (dec_funct3 != 3'b000);

  // CSR operation type from funct3
  // funct3: 001=CSRRW, 010=CSRRS, 011=CSRRC, 101=CSRRWI, 110=CSRRSI, 111=CSRRCI
  logic [1:0] csr_op_type;
  always_comb begin
    case (dec_funct3[1:0])
      2'b01: csr_op_type = 2'b01; // RW
      2'b10: csr_op_type = 2'b10; // RS
      2'b11: csr_op_type = 2'b11; // RC
      default: csr_op_type = 2'b00;
    endcase
  end

  // CSR source: immediate (funct3[2]=1) or register
  logic [31:0] csr_src_val;
  assign csr_src_val = dec_funct3[2] ? {27'b0, dec_rs1} : rs1_val;

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
      instr_reg     <= 32'h0000_0013; // NOP (addi x0, x0, 0)
      rs1_val       <= 32'h0;
      rs2_val       <= 32'h0;
      alu_result_reg <= 32'h0;
      mem_addr_reg  <= 32'h0;
      mem_rdata_reg <= 32'h0;
    end else begin
      case (state)
        // ----- FETCH REQUEST -----
        S_FETCH_REQ: begin
          if (req_ready) begin
            state <= S_FETCH_WAIT;
          end
        end

        // ----- FETCH WAIT (wait for response) -----
        S_FETCH_WAIT: begin
          if (rsp_valid) begin
            instr_reg <= rsp_rdata;
            state     <= S_DECODE;
          end
        end

        // ----- DECODE -----
        S_DECODE: begin
          rs1_val <= rf_rs1_data;
          rs2_val <= rf_rs2_data;
          state   <= S_EXECUTE;
        end

        // ----- EXECUTE -----
        S_EXECUTE: begin
          alu_result_reg <= alu_result;
          mem_addr_reg   <= alu_result; // used for load/store address

          if (dec_is_load || dec_is_store) begin
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
            state         <= S_WB;
          end
        end

        // ----- WRITEBACK + PC UPDATE -----
        S_WB: begin
          // PC update
          if (dec_is_jal) begin
            pc <= pc + dec_imm_j;
          end else if (dec_is_jalr) begin
            pc <= (rs1_val + dec_imm_i) & 32'hFFFF_FFFE;
          end else if (dec_is_branch && branch_taken) begin
            pc <= pc + dec_imm_b;
          end else if (is_ecall || is_ebreak) begin
            pc <= mtvec_out;
          end else if (is_mret) begin
            pc <= mepc_out;
          end else if (!dec_is_legal) begin
            // Illegal instruction trap
            pc <= mtvec_out;
          end else begin
            pc <= pc + 32'd4;
          end

          state <= S_FETCH_REQ;
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
        out_req_addr  = pc;
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
      if (dec_is_alu_reg || dec_is_alu_imm) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = alu_result_reg;
      end else if (dec_is_lui || dec_is_auipc) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = alu_result_reg;
      end else if (dec_is_jal || dec_is_jalr) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = alu_result_reg; // pc+4 (return address)
      end else if (dec_is_load) begin
        rf_wr_en  = 1'b1;
        rf_rd_data = load_result;
      end else if (is_csr_op) begin
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
    csr_addr_w  = instr_reg[31:20]; // CSR address from instruction
    csr_wdata_w = csr_src_val;
    csr_op_w    = csr_op_type;
    csr_wen_w   = 1'b0;
    trap_enter  = 1'b0;
    trap_cause  = 32'h0;
    trap_val    = 32'h0;
    trap_epc    = pc;
    mret_exec   = 1'b0;

    if (state == S_WB) begin
      if (is_csr_op) begin
        csr_wen_w = 1'b1;
      end else if (is_ecall) begin
        trap_enter = 1'b1;
        trap_cause = 32'd11; // Environment call from M-mode
        trap_epc   = pc;
      end else if (is_ebreak) begin
        trap_enter = 1'b1;
        trap_cause = 32'd3; // Breakpoint
        trap_epc   = pc;
      end else if (is_mret) begin
        mret_exec = 1'b1;
      end else if (!dec_is_legal && !dec_is_fence) begin
        trap_enter = 1'b1;
        trap_cause = 32'd2; // Illegal instruction
        trap_val   = instr_reg;
        trap_epc   = pc;
      end
    end
  end

endmodule
