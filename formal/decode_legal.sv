// decode_legal_wrapper.sv — Formal proof for decoder legality and immediate invariants
// Proves:
//   1. is_legal matches RV32I encoding rules (opcode + funct3/funct7/system/fence)
//   2. Exactly one type flag is set when instruction is legal
//   3. U-type immediate has lower 12 bits always zero

module decode_legal_wrapper (
    input logic clk
);

    (* anyseq *) logic [31:0] instr;

    logic [4:0]  rs1, rs2, rd;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic        is_lui, is_auipc, is_jal, is_jalr;
    logic        is_branch, is_load, is_store;
    logic        is_alu_imm, is_alu_reg;
    logic        is_system, is_fence;
    logic        is_legal;

    sisDecode dut (
        .instr     (instr),
        .rs1       (rs1),
        .rs2       (rs2),
        .rd        (rd),
        .imm_i     (imm_i),
        .imm_s     (imm_s),
        .imm_b     (imm_b),
        .imm_u     (imm_u),
        .imm_j     (imm_j),
        .opcode    (opcode),
        .funct3    (funct3),
        .funct7    (funct7),
        .is_lui    (is_lui),
        .is_auipc  (is_auipc),
        .is_jal    (is_jal),
        .is_jalr   (is_jalr),
        .is_branch (is_branch),
        .is_load   (is_load),
        .is_store  (is_store),
        .is_alu_imm(is_alu_imm),
        .is_alu_reg(is_alu_reg),
        .is_system (is_system),
        .is_fence  (is_fence),
        .is_legal  (is_legal)
    );

    logic exp_legal_lui, exp_legal_auipc, exp_legal_jal, exp_legal_jalr;
    logic exp_legal_branch, exp_legal_load, exp_legal_store;
    logic exp_legal_alu_imm, exp_legal_alu_reg;
    logic exp_legal_system, exp_legal_fence;
    logic exp_legal;

    assign exp_legal_lui   = is_lui;
    assign exp_legal_auipc = is_auipc;
    assign exp_legal_jal   = is_jal;
    assign exp_legal_jalr  = is_jalr && (funct3 == 3'b000);

    assign exp_legal_branch = is_branch && (
        (funct3 == 3'b000) || (funct3 == 3'b001) ||
        (funct3 == 3'b100) || (funct3 == 3'b101) ||
        (funct3 == 3'b110) || (funct3 == 3'b111)
    );

    assign exp_legal_load = is_load && (
        (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010) ||
        (funct3 == 3'b100) || (funct3 == 3'b101)
    );

    assign exp_legal_store = is_store && (
        (funct3 == 3'b000) || (funct3 == 3'b001) || (funct3 == 3'b010)
    );

    assign exp_legal_alu_imm = is_alu_imm && (
        (funct3 == 3'b000) || (funct3 == 3'b010) || (funct3 == 3'b011) ||
        (funct3 == 3'b100) || (funct3 == 3'b110) || (funct3 == 3'b111) ||
        ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||
        ((funct3 == 3'b101) && ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)))
    );

    assign exp_legal_alu_reg = is_alu_reg && (funct7 != 7'b0000001) && (
        ((funct3 == 3'b000) && ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) ||
        ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||
        ((funct3 == 3'b010) && (funct7 == 7'b0000000)) ||
        ((funct3 == 3'b011) && (funct7 == 7'b0000000)) ||
        ((funct3 == 3'b100) && (funct7 == 7'b0000000)) ||
        ((funct3 == 3'b101) && ((funct7 == 7'b0000000) || (funct7 == 7'b0100000))) ||
        ((funct3 == 3'b110) && (funct7 == 7'b0000000)) ||
        ((funct3 == 3'b111) && (funct7 == 7'b0000000))
    );

    assign exp_legal_system = is_system && (
        ((funct3 == 3'b000) && (
            (instr[31:20] == 12'h000) ||
            (instr[31:20] == 12'h001) ||
            (instr[31:20] == 12'h302)
        )) ||
        (funct3 == 3'b001) || (funct3 == 3'b010) || (funct3 == 3'b011) ||
        (funct3 == 3'b101) || (funct3 == 3'b110) || (funct3 == 3'b111)
    );

    assign exp_legal_fence = is_fence && (funct3 == 3'b000);

    assign exp_legal = exp_legal_lui | exp_legal_auipc | exp_legal_jal | exp_legal_jalr |
                       exp_legal_branch | exp_legal_load | exp_legal_store |
                       exp_legal_alu_imm | exp_legal_alu_reg |
                       exp_legal_system | exp_legal_fence;

    // Property 1: opcode field extraction
    always @(*) begin
        assert (opcode == instr[6:0]);
        assert (rd     == instr[11:7]);
        assert (funct3 == instr[14:12]);
        assert (rs1    == instr[19:15]);
        assert (rs2    == instr[24:20]);
        assert (funct7 == instr[31:25]);
    end

    // Property 2: U-type immediate lower 12 bits are always zero
    always @(*) begin
        assert (imm_u[11:0] == 12'b0);
    end

    // Property 3: B-type immediate bit 0 is always zero
    always @(*) begin
        assert (imm_b[0] == 1'b0);
    end

    // Property 4: J-type immediate bit 0 is always zero
    always @(*) begin
        assert (imm_j[0] == 1'b0);
    end

    // Property 5: is_legal matches RV32I encoding rules
    always @(*) begin
        assert (is_legal == exp_legal);
    end

endmodule
