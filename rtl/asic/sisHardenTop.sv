// sisHardenTop.sv — Sky130 hardenable IP slice (Milestone 8)
//
// Hardens the synthesizable core datapath + AXI4-Lite bridge that Yosys can
// map today. Full sisRvCore / CSR / PMP remain simulation-verified but use SV
// constructs (packed multi-dim ports, int casts) that the open Yosys frontend
// cannot parse yet — see docs/HARDENING.md.
//
// Memories are intentionally omitted (blackbox later via SRAM macros).

module sisHardenTop (
    input  logic        clk,
    input  logic        rst_n,

    // Instruction sample / compressed feed
    input  logic [31:0] instr_i,
    input  logic [15:0] c_instr_i,

    // Regfile debug / write path
    input  logic        wr_en,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    input  logic        dbg_en,
    input  logic        dbg_we,
    input  logic [4:0]  dbg_addr,
    input  logic [31:0] dbg_wdata,
    output logic [31:0] dbg_rdata,

    // Datapath observability
    output logic [31:0] alu_result,
    output logic        alu_zero,
    output logic        decode_legal,
    output logic [31:0] decompressed_instr,
    output logic        is_compressed,
    output logic        decompress_illegal,
    output logic        status,

    // Corebus request into the AXI-Lite bridge
    input  logic        req_valid,
    output logic        req_ready,
    input  logic [31:0] req_addr,
    input  logic        req_we,
    input  logic [31:0] req_wdata,
    input  logic [3:0]  req_wstrb,
    output logic        rsp_valid,
    input  logic        rsp_ready,
    output logic [31:0] rsp_rdata,
    output logic        rsp_err,

    // AXI4-Lite master
    output logic        awvalid,
    input  logic        awready,
    output logic [31:0] awaddr,
    output logic [2:0]  awprot,
    output logic        wvalid,
    input  logic        wready,
    output logic [31:0] wdata,
    output logic [3:0]  wstrb,
    input  logic        bvalid,
    output logic        bready,
    input  logic [1:0]  bresp,
    output logic        arvalid,
    input  logic        arready,
    output logic [31:0] araddr,
    output logic [2:0]  arprot,
    input  logic        rvalid,
    output logic        rready,
    input  logic [31:0] rdata,
    input  logic [1:0]  rresp
);

  logic [4:0]  rs1;
  logic [4:0]  rs2;
  logic [4:0]  rd;
  logic [31:0] imm_i;
  logic [31:0] imm_s;
  logic [31:0] imm_b;
  logic [31:0] imm_u;
  logic [31:0] imm_j;
  logic [6:0]  opcode;
  logic [2:0]  funct3;
  logic [6:0]  funct7;
  logic        is_lui, is_auipc, is_jal, is_jalr, is_branch;
  logic        is_load, is_store, is_alu_imm, is_alu_reg, is_system, is_fence;
  logic        is_atomic;
  logic [4:0]  atomic_funct5;
  logic        aq, rl;
  logic        decode_legal_i;

  logic [31:0] rs1_data;
  logic [31:0] rs2_data;

  // ALU op from funct3/funct7 (subset used for harden smoke)
  logic [3:0] alu_op;
  always_comb begin
    case (funct3)
      3'b000: alu_op = funct7[5] ? 4'b1000 : 4'b0000; // ADD/SUB
      3'b001: alu_op = 4'b0001; // SLL
      3'b010: alu_op = 4'b0010; // SLT
      3'b011: alu_op = 4'b0011; // SLTU
      3'b100: alu_op = 4'b0100; // XOR
      3'b101: alu_op = funct7[5] ? 4'b1101 : 4'b0101; // SRL/SRA
      3'b110: alu_op = 4'b0110; // OR
      3'b111: alu_op = 4'b0111; // AND
      default: alu_op = 4'b0000;
    endcase
  end

  sisDecompress u_decompress (
      .c_instr        (c_instr_i),
      .instr_o        (decompressed_instr),
      .is_compressed_o(is_compressed),
      .illegal_o      (decompress_illegal)
  );

  sisDecode #(
      .ENABLE_M(1'b1),
      .ENABLE_C(1'b1),
      .ENABLE_A(1'b1)
  ) u_decode (
      .instr         (instr_i),
      .rs1           (rs1),
      .rs2           (rs2),
      .rd            (rd),
      .imm_i         (imm_i),
      .imm_s         (imm_s),
      .imm_b         (imm_b),
      .imm_u         (imm_u),
      .imm_j         (imm_j),
      .opcode        (opcode),
      .funct3        (funct3),
      .funct7        (funct7),
      .is_lui        (is_lui),
      .is_auipc      (is_auipc),
      .is_jal        (is_jal),
      .is_jalr       (is_jalr),
      .is_branch     (is_branch),
      .is_load       (is_load),
      .is_store      (is_store),
      .is_alu_imm    (is_alu_imm),
      .is_alu_reg    (is_alu_reg),
      .is_system     (is_system),
      .is_fence      (is_fence),
      .is_atomic     (is_atomic),
      .atomic_funct5 (atomic_funct5),
      .aq            (aq),
      .rl            (rl),
      .is_legal      (decode_legal_i)
  );

  assign decode_legal = decode_legal_i;

  sisRegFile u_regfile (
      .clk       (clk),
      .rs1_addr  (rs1),
      .rs1_data  (rs1_data),
      .rs2_addr  (rs2),
      .rs2_data  (rs2_data),
      .wr_en     (wr_en),
      .rd_addr   (rd_addr),
      .rd_data   (rd_data),
      .dbg_en    (dbg_en),
      .dbg_we    (dbg_we),
      .dbg_addr  (dbg_addr),
      .dbg_wdata (dbg_wdata),
      .dbg_rdata (dbg_rdata)
  );

  sisAlu u_alu (
      .a      (rs1_data),
      .b      (is_alu_imm ? imm_i : rs2_data),
      .op     (alu_op),
      .result (alu_result),
      .zero   (alu_zero)
  );

  sisAxiLiteM u_axil (
      .clk       (clk),
      .rst_n     (rst_n),
      .req_valid (req_valid),
      .req_ready (req_ready),
      .req_addr  (req_addr),
      .req_we    (req_we),
      .req_wdata (req_wdata),
      .req_wstrb (req_wstrb),
      .rsp_valid (rsp_valid),
      .rsp_ready (rsp_ready),
      .rsp_rdata (rsp_rdata),
      .rsp_err   (rsp_err),
      .awvalid   (awvalid),
      .awready   (awready),
      .awaddr    (awaddr),
      .awprot    (awprot),
      .wvalid    (wvalid),
      .wready    (wready),
      .wdata     (wdata),
      .wstrb     (wstrb),
      .bvalid    (bvalid),
      .bready    (bready),
      .bresp     (bresp),
      .arvalid   (arvalid),
      .arready   (arready),
      .araddr    (araddr),
      .arprot    (arprot),
      .rvalid    (rvalid),
      .rready    (rready),
      .rdata     (rdata),
      .rresp     (rresp)
  );

  // Retain otherwise-unused decode side-bands as a single status pin.
  assign status = is_lui | is_auipc | is_jal | is_jalr | is_branch |
                  is_load | is_store | is_alu_reg | is_system | is_fence |
                  is_atomic | aq | rl | (|opcode) | (|rd) | (|imm_s) |
                  (|imm_b) | (|imm_u) | (|imm_j) | (|atomic_funct5);

endmodule
