// sisDecode.sv — RV32I instruction decoder
// Extracts immediates, register addresses, and control signals.

module sisDecode (
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

  // Extract fields
  assign opcode = instr[6:0];
  assign rd     = instr[11:7];
  assign funct3 = instr[14:12];
  assign rs1    = instr[19:15];
  assign rs2    = instr[24:20];
  assign funct7 = instr[31:25];

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

  // Legality check (basic: known opcode)
  assign is_legal = is_lui | is_auipc | is_jal | is_jalr |
                    is_branch | is_load | is_store |
                    is_alu_imm | is_alu_reg |
                    is_system | is_fence;

endmodule
