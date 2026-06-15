// sisDecompress.sv — RV32C decompressor

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
  logic [9:0] nzuimm;
  logic [9:0] sp_imm;
  logic [7:0] c_ls_uimm;

  assign quad   = c_instr[1:0];
  assign funct3 = c_instr[15:13];
  assign rd_rs1 = c_instr[11:7];
  assign rdp    = {2'b01, c_instr[4:2]};
  assign rs1p   = {2'b01, c_instr[9:7]};
  assign rs2p   = {2'b01, c_instr[4:2]};
  assign nzuimm = {c_instr[10:7], c_instr[12:11], c_instr[5], c_instr[6], 2'b00};
  assign sp_imm  = {c_instr[12], c_instr[4:3], c_instr[5], c_instr[2], c_instr[6], 4'b0000};
  assign c_ls_uimm = {c_instr[12], c_instr[5], c_instr[10:8], c_instr[6], 2'b00};

  logic [5:0] c_lui_imm6;
  assign c_lui_imm6 = {c_instr[12], c_instr[6:2]};

  logic [31:0] expanded;
  logic        legal;

  always_comb begin
    expanded = 32'h0000_0013;
    legal    = 1'b1;

    unique case (quad)
      2'b00: begin
        unique case (funct3)
          3'b000: begin
            if (nzuimm == 10'd0) legal = 1'b0;
            else expanded = {2'b00, nzuimm[9:2], 4'b0000, 3'b000, rdp, 7'b0010011};
          end
          3'b010:
            expanded = {4'b0, c_ls_uimm, rs1p, 3'b010, rdp, 7'b0000011};
          3'b110:
            expanded = {c_ls_uimm[7:1], rs2p, rs1p, 3'b010, c_ls_uimm[4:0], 7'b0100011};
          default: legal = 1'b0;
        endcase
      end
      2'b01: begin
        unique case (funct3)
          3'b000: begin
            expanded = {{6{c_instr[12]}}, c_instr[12], c_instr[6:2], rd_rs1, 3'b000, rd_rs1, 7'b0010011};
          end
          3'b001:
            expanded = {{9{c_instr[12]}}, c_instr[12], c_instr[8], c_instr[10:9], c_instr[6],
                        c_instr[7], c_instr[2], c_instr[11], c_instr[5:3], 1'b0,
                        5'd1, 7'b1101111};
          3'b010: begin
            if (rd_rs1 == 5'd0) legal = 1'b0;
            else expanded = {{6{c_instr[12]}}, c_instr[12], c_instr[6:2], 5'd0, 3'b000, rd_rs1, 7'b0010011};
          end
          3'b011: begin
            if (rd_rs1 == 5'd2) begin
              if (sp_imm == 10'd0) legal = 1'b0;
              else expanded = {{2{sp_imm[9]}}, sp_imm[9:4], 5'd2, 3'b000, 5'd2, 7'b0010011};
            end else begin
              if (c_lui_imm6 == 6'd0 || rd_rs1 == 5'd2) legal = 1'b0;
              else expanded = {c_lui_imm6, rd_rs1, 7'b0110111};
            end
          end
          3'b100: begin
            unique case (c_instr[11:10])
              2'b00: expanded = {7'b0000000, c_instr[6:2], rs1p, 3'b101, rdp, 7'b0010011};
              2'b01: expanded = {7'b0100000, c_instr[6:2], rs1p, 3'b101, rdp, 7'b0010011};
              2'b10: expanded = {{6{c_instr[12]}}, c_instr[12], c_instr[6:2], rs1p, 3'b111, rdp, 7'b0010011};
              2'b11: begin
                unique case (c_instr[6:5])
                  2'b00: expanded = {7'b0100000, rs2p, rs1p, 3'b000, rdp, 7'b0110011};
                  2'b01: expanded = {7'b0000000, rs2p, rs1p, 3'b100, rdp, 7'b0110011};
                  2'b10: expanded = {7'b0000000, rs2p, rs1p, 3'b110, rdp, 7'b0110011};
                  2'b11: expanded = {7'b0000000, rs2p, rs1p, 3'b111, rdp, 7'b0110011};
                endcase
              end
            endcase
          end
          3'b101:
            expanded = {{10{c_instr[12]}}, c_instr[12], c_instr[8], c_instr[10:9], c_instr[6],
                        c_instr[7], c_instr[2], c_instr[11], c_instr[5:3], 1'b0,
                        5'd0, 7'b1101111};
          3'b110:
            expanded = {{5{c_instr[12]}}, c_instr[12], c_instr[6:5], c_instr[2], c_instr[11:10],
                        c_instr[4:3], 1'b0, rs1p, 3'b000, 5'd0, 7'b1100011};
          3'b111:
            expanded = {{5{c_instr[12]}}, c_instr[12], c_instr[6:5], c_instr[2], c_instr[11:10],
                        c_instr[4:3], 1'b0, rs1p, 3'b001, 5'd0, 7'b1100011};
          default: legal = 1'b0;
        endcase
      end
      2'b10: begin
        unique case (funct3)
          3'b000:
            expanded = {7'b0000000, c_instr[6:2], rd_rs1, 3'b001, rd_rs1, 7'b0010011};
          3'b010:
            expanded = {{4{c_instr[12]}}, c_instr[12], c_instr[6:4], c_instr[8:7], 2'b00,
                        5'd2, 3'b010, rd_rs1, 7'b0000011};
          3'b100: begin
            if (c_instr[15:12] == 4'b1001) begin
              if (c_instr[6:2] == 5'd0) legal = 1'b0;
              else expanded = {7'b0000000, c_instr[6:2], rd_rs1, 3'b000, rd_rs1, 7'b0110011};
            end else if (c_instr[12:11] == 2'b00) begin
              if (rd_rs1 == 5'd0) legal = 1'b0;
              else expanded = {12'h000, rd_rs1, 3'b000, 5'd0, 7'b1100111};
            end else if (c_instr[12:11] == 2'b01) begin
              if (c_instr[6:2] == 5'd0) begin
                if (rd_rs1 == 5'd0) legal = 1'b0;
                else expanded = {12'h000, rd_rs1, 3'b000, 5'd1, 7'b1100111};
              end else begin
                expanded = {7'b0000000, c_instr[6:2], 5'd0, 3'b000, rd_rs1, 7'b0110011};
              end
            end else if (c_instr[12:11] == 2'b10) begin
              if (c_instr[6:2] == 5'd0)
                expanded = {12'h001, 5'd0, 3'b000, 5'd0, 7'b1110011};
              else
                expanded = {7'b0000000, c_instr[6:2], rd_rs1, 3'b000, rd_rs1, 7'b0110011};
            end else legal = 1'b0;
          end
          3'b110:
            expanded = {4'b0, c_instr[8:7], c_instr[12:9], 5'd2, 3'b010, c_instr[6:2], 7'b0100011};
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
