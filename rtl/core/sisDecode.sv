// sisDecode.sv — RV32I instruction decoder
// Extracts immediates, register addresses, and control signals.

module sisDecode #(
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b1,
    parameter bit ENABLE_A = 1'b1
)(
    input  logic [31:0] instr,

    // Register addresses
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,

    // Immediates (sign-extended to 32 bits)
    output logic [31:0] imm_i,
    output logic [31:0] imm_s,
    output logic [31:0] imm_b,
    output logic [31:0] imm_u,
    output logic [31:0] imm_j,

    // Opcode fields
    output logic [6:0]  opcode,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7,

    // Instruction type flags
    output logic        is_lui,
    output logic        is_auipc,
    output logic        is_jal,
    output logic        is_jalr,
    output logic        is_branch,
    output logic        is_load,
    output logic        is_store,
    output logic        is_alu_imm,
    output logic        is_alu_reg,
    output logic        is_system,
    output logic        is_fence,

    // Atomic instruction decode (RV32A)
    output logic        is_atomic,
    output logic [4:0]  atomic_funct5,
    output logic        aq,
    output logic        rl,

    // Decoded control
    output logic        is_legal
);

  // Opcode constants
  localparam logic [6:0] OP_LUI     = 7'b0110111;
  localparam logic [6:0] OP_AUIPC   = 7'b0010111;
  localparam logic [6:0] OP_JAL     = 7'b1101111;
  localparam logic [6:0] OP_JALR    = 7'b1100111;
  localparam logic [6:0] OP_BRANCH  = 7'b1100011;
  localparam logic [6:0] OP_LOAD    = 7'b0000011;
  localparam logic [6:0] OP_STORE   = 7'b0100011;
  localparam logic [6:0] OP_ALU_IMM = 7'b0010011;
  localparam logic [6:0] OP_ALU_REG = 7'b0110011;
  localparam logic [6:0] OP_FENCE   = 7'b0001111;
  localparam logic [6:0] OP_SYSTEM  = 7'b1110011;
  localparam logic [6:0] OP_AMO     = 7'b0101111;

  // Extract fields
  assign opcode = instr[6:0];
  assign rd     = instr[11:7];
  assign funct3 = instr[14:12];
  assign rs1    = instr[19:15];
  assign rs2    = instr[24:20];
  assign funct7 = instr[31:25];

  // Atomic-specific fields
  assign atomic_funct5 = instr[31:27];
  assign aq            = instr[26];
  assign rl            = instr[25];

  // Immediate generation
  assign imm_i = {{20{instr[31]}}, instr[31:20]};
  assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  assign imm_u = {instr[31:12], 12'b0};
  assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

  // Instruction type decode
  assign is_lui     = (opcode == OP_LUI);
  assign is_auipc   = (opcode == OP_AUIPC);
  assign is_jal     = (opcode == OP_JAL);
  assign is_jalr    = (opcode == OP_JALR);
  assign is_branch  = (opcode == OP_BRANCH);
  assign is_load    = (opcode == OP_LOAD);
  assign is_store   = (opcode == OP_STORE);
  assign is_alu_imm = (opcode == OP_ALU_IMM);
  assign is_alu_reg = (opcode == OP_ALU_REG);
  assign is_system  = (opcode == OP_SYSTEM);
  assign is_fence   = (opcode == OP_FENCE);
  assign is_atomic  = (opcode == OP_AMO);

  // RV32I/RV32M encoding legality (opcode + funct3/funct7/system/fence fields)
  logic legal_lui, legal_auipc, legal_jal, legal_jalr;
  logic legal_branch, legal_load, legal_store;
  logic legal_alu_imm, legal_alu_reg;
  logic legal_system, legal_fence;
  logic legal_atomic;

  assign legal_lui   = is_lui;
  assign legal_auipc = is_auipc;
  assign legal_jal   = is_jal;
  assign legal_jalr  = is_jalr && (funct3 == 3'b000);

  assign legal_branch = is_branch && (
      (funct3 == 3'b000) || (funct3 == 3'b001) ||
      (funct3 == 3'b100) || (funct3 == 3'b101) ||
      (funct3 == 3'b110) || (funct3 == 3'b111)
  );

  assign legal_load = is_load && (
      (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010) ||
      (funct3 == 3'b100) || (funct3 == 3'b101)
  );

  assign legal_store = is_store && (
      (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010)
  );

  assign legal_alu_imm = is_alu_imm && (
      (funct3 == 3'b000) || (funct3 == 3'b010) || (funct3 == 3'b011) ||
      (funct3 == 3'b100) || (funct3 == 3'b110) || (funct3 == 3'b111) ||
      ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||
      ((funct3 == 3'b101) && ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)))
  );

  assign legal_alu_reg = is_alu_reg && (
      ((funct3 == 3'b000) && ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) ||
      ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||
      ((funct3 == 3'b010) && (funct7 == 7'b0000000)) ||
      ((funct3 == 3'b011) && (funct7 == 7'b0000000)) ||
      ((funct3 == 3'b100) && (funct7 == 7'b0000000)) ||
      ((funct3 == 3'b101) && ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) ||
      ((funct3 == 3'b110) && (funct7 == 7'b0000000)) ||
      ((funct3 == 3'b111) && (funct7 == 7'b0000000)) ||
      (ENABLE_M && (funct7 == 7'b0000001))
  );

  // ECALL/EBREAK/MRET or CSR ops with valid funct3
  assign legal_system = is_system && (
      ((funct3 == 3'b000) && (
          (instr[31:20] == 12'h000) || // ECALL
          (instr[31:20] == 12'h001) || // EBREAK
          (instr[31:20] == 12'h105) || // WFI
          (instr[31:20] == 12'h302)    // MRET
      )) ||
      (funct3 == 3'b001) || (funct3 == 3'b010) || (funct3 == 3'b011) ||
      (funct3 == 3'b101) || (funct3 == 3'b110) || (funct3 == 3'b111)
  );

  assign legal_fence = is_fence && (funct3 == 3'b000);

  // RV32A atomics: opcode=OP_AMO, funct3=010 (word), funct5 selects operation.
  // aq/rl bits (instr[26:25]) are ordering hints — accepted for any funct5 below.
  // LR.W rs2!=0: spec UNDEF; silently accepted at decode (single-hart, never occurs in practice).
  assign legal_atomic = ENABLE_A && is_atomic && (funct3 == 3'b010) && (
      (atomic_funct5 == 5'b00010) ||  // LR.W
      (atomic_funct5 == 5'b00011) ||  // SC.W
      (atomic_funct5 == 5'b00001) ||  // AMOSWAP.W
      (atomic_funct5 == 5'b00000) ||  // AMOADD.W
      (atomic_funct5 == 5'b00100) ||  // AMOXOR.W
      (atomic_funct5 == 5'b01100) ||  // AMOAND.W
      (atomic_funct5 == 5'b01000) ||  // AMOOR.W
      (atomic_funct5 == 5'b10000) ||  // AMOMIN.W
      (atomic_funct5 == 5'b10100) ||  // AMOMAX.W
      (atomic_funct5 == 5'b11000) ||  // AMOMINU.W
      (atomic_funct5 == 5'b11100)     // AMOMAXU.W
  );

  assign is_legal = legal_lui | legal_auipc | legal_jal | legal_jalr |
                    legal_branch | legal_load | legal_store |
                    legal_alu_imm | legal_alu_reg |
                    legal_system | legal_fence | legal_atomic;

endmodule
