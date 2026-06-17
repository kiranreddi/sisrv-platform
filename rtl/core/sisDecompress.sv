// sisDecompress.sv — RV32C decompressor (RV32IMC profile)

module sisDecompress (
    input  logic [15:0] c_instr,
    output logic [31:0] instr_o,
    output logic        is_compressed_o,
    output logic        illegal_o
);

  logic [1:0] quad;
  logic [2:0] funct3;
  logic [4:0] rd_rs1;
  logic [4:0] rdp, rs1p, rs2p;

  assign quad   = c_instr[1:0];
  assign funct3 = c_instr[15:13];
  assign rd_rs1 = c_instr[11:7];
  assign rdp    = {2'b01, c_instr[4:2]};
  assign rs1p   = {2'b01, c_instr[9:7]};
  assign rs2p   = {2'b01, c_instr[4:2]};

  // Quadrant-0 C.LW / C.SW byte offset (scrambled encoding)
  logic [7:0] c0_ls_uimm;
  assign c0_ls_uimm = ((c_instr >> 7) & 8'h38) | ((c_instr >> 4) & 8'h04) | ((c_instr << 1) & 8'h40);

  // Quadrant-0 C.ADDI4SPN immediate
  logic [9:0] addi4spn_uimm;
  assign addi4spn_uimm = {c_instr[10:7], c_instr[12:11], c_instr[5], c_instr[6], 2'b00};

  // Quadrant-1 6-bit signed immediates (C.ADDI, C.LI, C.LUI, C.ANDI, shifts)
  logic signed [5:0] imm6;
  assign imm6 = {c_instr[12], c_instr[6:2]};

  // Quadrant-1 C.ADDI16SP immediate
  logic [9:0] addi16sp_uimm;
  assign addi16sp_uimm = {c_instr[12], c_instr[4:3], c_instr[5], c_instr[2], c_instr[6], 4'b0000};

  // C.J / C.JAL 12-bit byte offset (bit 0 = 0)
  logic [11:0] cj_imm12;
  assign cj_imm12 = {c_instr[12], c_instr[8], c_instr[10:9], c_instr[6], c_instr[7],
                     c_instr[2], c_instr[11], c_instr[5:3], 1'b0};
  logic [20:0] cj_off;
  assign cj_off = {{9{cj_imm12[11]}}, cj_imm12};

  // C.BEQZ / C.BNEZ branch offset (12-bit, bit 0 = 0; sign at bit 8)
  logic [11:0] cb_imm_pre;
  assign cb_imm_pre = ((c_instr >> 4) & 12'h100) | ((c_instr << 1) & 12'h0C0) |
                       ((c_instr << 3) & 12'h020) | ((c_instr >> 7) & 12'h018) |
                       ((c_instr >> 2) & 12'h006);
  logic signed [11:0] cb_imm_s;
  assign cb_imm_s = cb_imm_pre[8] ? (cb_imm_pre - 12'h200) : cb_imm_pre;
  logic signed [12:0] cb_imm_ext;
  assign cb_imm_ext = {cb_imm_s[11], cb_imm_s};
  logic [31:0] cb_insn_base;
  assign cb_insn_base = ((cb_imm_ext & 13'h1000) << 19) | ((cb_imm_s & 12'h7E0) << 20) |
                        ((cb_imm_s & 12'h01E) << 7) | ((cb_imm_s & 12'h800) >> 4);

  // Quadrant-2 C.LWSP / C.SWSP byte offset
  logic [7:0] lwsp_uimm;
  assign lwsp_uimm = {c_instr[3:2], c_instr[12], c_instr[6:4], 2'b00};
  logic [7:0] swsp_uimm;
  assign swsp_uimm = {c_instr[8:7], c_instr[12:9], 2'b00};

  logic [31:0] expanded;
  logic        legal;

  always_comb begin
    expanded = 32'h0000_0013;
    legal    = 1'b1;

    unique case (quad)
      2'b00: begin
        unique case (funct3)
          3'b000: begin
            if (addi4spn_uimm == 10'd0) legal = 1'b0;
            else expanded = {2'b00, addi4spn_uimm, 5'd2, 3'b000, rdp, 7'b0010011};
          end
          3'b010:
            expanded = {c0_ls_uimm, rs1p, 3'b010, rdp, 7'b0000011};
          3'b110:
            expanded = {5'b00000, c0_ls_uimm[6:5], rs2p, rs1p, 3'b010, c0_ls_uimm[4:0], 7'b0100011};
          default: legal = 1'b0;
        endcase
      end
      2'b01: begin
        unique case (funct3)
          3'b000: begin
            expanded = {{6{imm6[5]}}, imm6, rd_rs1, 3'b000, rd_rs1, 7'b0010011};
          end
          3'b001:
            expanded = {cj_off[20], cj_off[10:1], cj_off[11], cj_off[19:12], 5'd1, 7'b1101111};
          3'b010: begin
            if (rd_rs1 == 5'd0)
              expanded = {{6{imm6[5]}}, imm6, 5'd0, 3'b000, 5'd0, 7'b0010011};
            else
              expanded = {{6{imm6[5]}}, imm6, 5'd0, 3'b000, rd_rs1, 7'b0010011};
          end
          3'b011: begin
            if (rd_rs1 == 5'd2) begin
              if (addi16sp_uimm == 10'd0) legal = 1'b0;
              else expanded = {{2{addi16sp_uimm[9]}}, addi16sp_uimm, 5'd2, 3'b000, 5'd2, 7'b0010011};
            end else begin
              if (imm6 == 6'sd0) legal = 1'b0;
              else if (rd_rs1 == 5'd0)
                expanded = {{14{imm6[5]}}, imm6, 5'd0, 7'b0110111};
              else
                expanded = {{14{imm6[5]}}, imm6, rd_rs1, 7'b0110111};
            end
          end
          3'b100: begin
            unique case (c_instr[11:10])
              2'b00: begin
                if (c_instr[12] != 1'b0 || c_instr[6:2] == 5'd0) legal = 1'b0;
                else expanded = {7'b0000000, c_instr[6:2], rs1p, 3'b101, rs1p, 7'b0010011};
              end
              2'b01: begin
                if (c_instr[12] != 1'b0 || c_instr[6:2] == 5'd0) legal = 1'b0;
                else expanded = {7'b0100000, c_instr[6:2], rs1p, 3'b101, rs1p, 7'b0010011};
              end
              2'b10:
                expanded = {{6{imm6[5]}}, imm6, rs1p, 3'b111, rs1p, 7'b0010011};
              2'b11: begin
                if (c_instr[12] != 1'b0) legal = 1'b0;
                else unique case (c_instr[6:5])
                  2'b00: expanded = {7'b0100000, rs2p, rs1p, 3'b000, rs1p, 7'b0110011};
                  2'b01: expanded = {7'b0000000, rs2p, rs1p, 3'b100, rs1p, 7'b0110011};
                  2'b10: expanded = {7'b0000000, rs2p, rs1p, 3'b110, rs1p, 7'b0110011};
                  2'b11: expanded = {7'b0000000, rs2p, rs1p, 3'b111, rs1p, 7'b0110011};
                endcase
              end
            endcase
          end
          3'b101:
            expanded = {cj_off[20], cj_off[10:1], cj_off[11], cj_off[19:12], 5'd0, 7'b1101111};
          3'b110:
            expanded = cb_insn_base | (rs1p << 15) | (3'b000 << 12) | 7'b1100011;
          3'b111:
            expanded = cb_insn_base | (rs1p << 15) | (3'b001 << 12) | 7'b1100011;
          default: legal = 1'b0;
        endcase
      end
      2'b10: begin
        unique case (funct3)
          3'b000: begin
            if (c_instr[12] != 1'b0 || c_instr[6:2] == 5'd0 || rd_rs1 == 5'd0) legal = 1'b0;
            else expanded = {7'b0000000, c_instr[6:2], rd_rs1, 3'b001, rd_rs1, 7'b0010011};
          end
          3'b010: begin
            if (rd_rs1 == 5'd0) legal = 1'b0;
            else expanded = {lwsp_uimm, 5'd2, 3'b010, rd_rs1, 7'b0000011};
          end
          3'b100: begin
            if (c_instr[12] == 1'b0) begin
              if (c_instr[6:2] == 5'd0) begin
                if (rd_rs1 == 5'd0) legal = 1'b0;
                else expanded = {12'h000, rd_rs1, 3'b000, 5'd0, 7'b1100111};
              end else begin
                expanded = {7'b0000000, c_instr[6:2], 5'd0, 3'b000, rd_rs1, 7'b0110011};
              end
            end else begin
              if (c_instr[6:2] == 5'd0 && rd_rs1 == 5'd0)
                expanded = 32'h0010_0073;
              else if (c_instr[6:2] == 5'd0) begin
                if (rd_rs1 == 5'd0) legal = 1'b0;
                else expanded = {12'h000, rd_rs1, 3'b000, 5'd1, 7'b1100111};
              end else
                expanded = {7'b0000000, c_instr[6:2], rd_rs1, 3'b000, rd_rs1, 7'b0110011};
            end
          end
          3'b110:
            expanded = {4'b0000, swsp_uimm[7:5], c_instr[6:2], 5'd2, 3'b010, swsp_uimm[4:0], 7'b0100011};
          default: legal = 1'b0;
        endcase
      end
      default: legal = 1'b0;
    endcase
  end

  assign is_compressed_o = (quad != 2'b11);
  assign instr_o         = expanded;
  assign illegal_o       = is_compressed_o && !legal;

endmodule
