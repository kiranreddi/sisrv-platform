package sis_decompress_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // -----------------------------------------------------------------------
  // Transaction
  // -----------------------------------------------------------------------
  class sis_decompress_item extends uvm_sequence_item;
    // Not `rand` + constraints: Verilator needs an external SAT solver (z3)
    // for constraint randomize. Sequences use $urandom instead.
    bit [15:0] c_instr;
    bit [31:0] instr_o;
    bit        is_compressed_o;
    bit        illegal_o;

    `uvm_object_utils_begin(sis_decompress_item)
      `uvm_field_int(c_instr, UVM_ALL_ON)
      `uvm_field_int(instr_o, UVM_ALL_ON)
      `uvm_field_int(is_compressed_o, UVM_ALL_ON)
      `uvm_field_int(illegal_o, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "sis_decompress_item");
      super.new(name);
    endfunction
  endclass

  // -----------------------------------------------------------------------
  // Combinational reference model (mirrors rtl/core/sisDecompress.sv)
  // -----------------------------------------------------------------------
  function automatic void sis_decompress_ref(
      input  bit [15:0] c_instr,
      output bit [31:0] instr_o,
      output bit        is_compressed_o,
      output bit        illegal_o
  );
    bit [1:0]  quad;
    bit [2:0]  funct3;
    bit [4:0]  rd_rs1, rdp, rs1p, rs2p;
    bit [7:0]  c0_ls_uimm, lwsp_uimm, swsp_uimm;
    bit [9:0]  addi4spn_uimm, addi16sp_uimm;
    bit signed [5:0] imm6;
    bit [11:0] cj_imm12;
    bit [20:0] cj_off;
    bit [11:0] cb_imm_pre;
    bit signed [11:0] cb_imm_s;
    bit signed [12:0] cb_imm_ext;
    bit [31:0] cb_insn_base;
    bit [31:0] expanded;
    bit        legal;

    quad   = c_instr[1:0];
    funct3 = c_instr[15:13];
    rd_rs1 = c_instr[11:7];
    rdp    = {2'b01, c_instr[4:2]};
    rs1p   = {2'b01, c_instr[9:7]};
    rs2p   = {2'b01, c_instr[4:2]};
    c0_ls_uimm = ((c_instr >> 7) & 8'h38) | ((c_instr >> 4) & 8'h04) | ((c_instr << 1) & 8'h40);
    addi4spn_uimm = {c_instr[10:7], c_instr[12:11], c_instr[5], c_instr[6], 2'b00};
    imm6 = {c_instr[12], c_instr[6:2]};
    addi16sp_uimm = {c_instr[12], c_instr[4:3], c_instr[5], c_instr[2], c_instr[6], 4'b0000};
    cj_imm12 = {c_instr[12], c_instr[8], c_instr[10:9], c_instr[6], c_instr[7],
                c_instr[2], c_instr[11], c_instr[5:3], 1'b0};
    cj_off = {{9{cj_imm12[11]}}, cj_imm12};
    cb_imm_pre = ((c_instr >> 4) & 12'h100) | ((c_instr << 1) & 12'h0C0) |
                 ((c_instr << 3) & 12'h020) | ((c_instr >> 7) & 12'h018) |
                 ((c_instr >> 2) & 12'h006);
    cb_imm_s = cb_imm_pre[8] ? (cb_imm_pre - 12'h200) : cb_imm_pre;
    cb_imm_ext = {cb_imm_s[11], cb_imm_s};
    cb_insn_base = ((cb_imm_ext & 13'h1000) << 19) | ((cb_imm_s & 12'h7E0) << 20) |
                   ((cb_imm_s & 12'h01E) << 7) | ((cb_imm_s & 12'h800) >> 4);
    lwsp_uimm = {c_instr[3:2], c_instr[12], c_instr[6:4], 2'b00};
    swsp_uimm = {c_instr[8:7], c_instr[12:9], 2'b00};

    expanded = 32'h0000_0013;
    legal    = 1'b1;

    case (quad)
      2'b00: begin
        case (funct3)
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
        case (funct3)
          3'b000:
            expanded = {{6{imm6[5]}}, imm6, rd_rs1, 3'b000, rd_rs1, 7'b0010011};
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
            case (c_instr[11:10])
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
                else case (c_instr[6:5])
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
        case (funct3)
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
              end else
                expanded = {7'b0000000, c_instr[6:2], 5'd0, 3'b000, rd_rs1, 7'b0110011};
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

    is_compressed_o = (quad != 2'b11);
    instr_o         = expanded;
    illegal_o       = is_compressed_o && !legal;
  endfunction

  // -----------------------------------------------------------------------
  // Agent pieces
  // -----------------------------------------------------------------------
  class sis_decompress_sequencer extends uvm_sequencer #(sis_decompress_item);
    `uvm_component_utils(sis_decompress_sequencer)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class sis_decompress_driver extends uvm_driver #(sis_decompress_item);
    `uvm_component_utils(sis_decompress_driver)
    virtual sis_decompress_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual sis_decompress_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "sis_decompress_if not set")
    endfunction

    task run_phase(uvm_phase phase);
      vif.c_instr <= '0;
      forever begin
        sis_decompress_item req;
        seq_item_port.get_next_item(req);
        vif.c_instr <= req.c_instr;
        #1;
        req.instr_o         = vif.instr_o;
        req.is_compressed_o = vif.is_compressed_o;
        req.illegal_o       = vif.illegal_o;
        seq_item_port.item_done();
      end
    endtask
  endclass

  class sis_decompress_monitor extends uvm_monitor;
    `uvm_component_utils(sis_decompress_monitor)
    virtual sis_decompress_if vif;
    uvm_analysis_port #(sis_decompress_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual sis_decompress_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "sis_decompress_if not set")
    endfunction

    task run_phase(uvm_phase phase);
      sis_decompress_item item;
      bit [15:0] last;
      bit        have_last;
      have_last = 0;
      forever begin
        #1;
        if (!have_last || vif.c_instr !== last) begin
          item = sis_decompress_item::type_id::create("item");
          item.c_instr         = vif.c_instr;
          item.instr_o         = vif.instr_o;
          item.is_compressed_o = vif.is_compressed_o;
          item.illegal_o       = vif.illegal_o;
          ap.write(item);
          last = vif.c_instr;
          have_last = 1;
        end
      end
    endtask
  endclass

  class sis_decompress_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(sis_decompress_scoreboard)
    uvm_analysis_imp #(sis_decompress_item, sis_decompress_scoreboard) imp;
    int unsigned seen, errors;
    // Lightweight functional bins (Verilator has no covergroups)
    int unsigned bin_quad[4];
    int unsigned bin_illegal, bin_legal_c, bin_uncompressed;
    int unsigned bin_funct3[8];

    function new(string name, uvm_component parent);
      super.new(name, parent);
      imp = new("imp", this);
    endfunction

    function void write(sis_decompress_item t);
      bit [31:0] exp_instr;
      bit        exp_c, exp_ill;
      bit [1:0]  q;
      seen++;
      sis_decompress_ref(t.c_instr, exp_instr, exp_c, exp_ill);
      q = t.c_instr[1:0];
      bin_quad[q]++;
      if (!exp_c) bin_uncompressed++;
      else if (exp_ill) bin_illegal++;
      else begin
        bin_legal_c++;
        bin_funct3[t.c_instr[15:13]]++;
      end

      if (t.is_compressed_o !== exp_c || t.illegal_o !== exp_ill ||
          (exp_c && !exp_ill && t.instr_o !== exp_instr)) begin
        errors++;
        `uvm_error("DEC_SB",
          $sformatf("mismatch c=%04h got{c=%0d ill=%0d i=%08h} exp{c=%0d ill=%0d i=%08h}",
                    t.c_instr, t.is_compressed_o, t.illegal_o, t.instr_o,
                    exp_c, exp_ill, exp_instr))
      end
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info("DEC_SB", $sformatf("seen=%0d errors=%0d", seen, errors), UVM_LOW)
      `uvm_info("DEC_FC",
        $sformatf("bins legal_c=%0d illegal=%0d uncomp=%0d quad={%0d,%0d,%0d,%0d} funct3={%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d}",
                  bin_legal_c, bin_illegal, bin_uncompressed,
                  bin_quad[0], bin_quad[1], bin_quad[2], bin_quad[3],
                  bin_funct3[0], bin_funct3[1], bin_funct3[2], bin_funct3[3],
                  bin_funct3[4], bin_funct3[5], bin_funct3[6], bin_funct3[7]),
        UVM_LOW)
      if (errors != 0)
        `uvm_error("DEC_SB", "decompress scoreboard reported errors")
      if (seen == 0)
        `uvm_error("DEC_SB", "decompress scoreboard saw zero transactions")
      if (bin_quad[0] == 0 || bin_quad[1] == 0 || bin_quad[2] == 0 || bin_quad[3] == 0)
        `uvm_error("DEC_FC", "missing quadrant bin coverage")
      if (bin_illegal == 0 || bin_legal_c == 0 || bin_uncompressed == 0)
        `uvm_error("DEC_FC", "missing legal/illegal/uncompressed bin")
    endfunction
  endclass

  class sis_decompress_agent extends uvm_agent;
    `uvm_component_utils(sis_decompress_agent)
    sis_decompress_driver    driver;
    sis_decompress_monitor   monitor;
    sis_decompress_sequencer sequencer;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      monitor = sis_decompress_monitor::type_id::create("monitor", this);
      if (get_is_active() == UVM_ACTIVE) begin
        driver    = sis_decompress_driver::type_id::create("driver", this);
        sequencer = sis_decompress_sequencer::type_id::create("sequencer", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      if (get_is_active() == UVM_ACTIVE)
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

  // -----------------------------------------------------------------------
  // Sequences — directed branch coverage of every unique case in sisDecompress
  // -----------------------------------------------------------------------
  class sis_decompress_smoke_seq extends uvm_sequence #(sis_decompress_item);
    `uvm_object_utils(sis_decompress_smoke_seq)
    function new(string name = "sis_decompress_smoke_seq");
      super.new(name);
    endfunction

    task send_c(bit [15:0] c);
      sis_decompress_item item;
      item = sis_decompress_item::type_id::create("item");
      start_item(item);
      item.c_instr = c;
      finish_item(item);
    endtask

    task body();
      bit [15:0] directed[$];
      directed = '{
        // Q0
        16'h0000, // illegal c.addi4spn imm0
        16'h1000, // c.addi4spn
        16'h4180, // c.lw
        16'hC180, // c.sw
        16'h2000, // Q0 illegal funct3=001
        16'h6000, // Q0 illegal funct3=011
        // Q1
        16'h0001, // c.nop
        16'h0405, // c.addi x8,1
        16'h2001, // c.jal
        16'h4081, // c.li x1
        16'h4001, // c.li x0 path
        16'h7101, // c.addi16sp nonzero
        16'h6101, // c.addi16sp imm0 => illegal (rd=x2)
        16'h6085, // c.lui x1 nonzero
        16'h6001, // c.lui imm0 => illegal (rd!=x2) — hits legal=0 branch
        16'h6081, // c.lui x1 imm0 => illegal
        16'h8005, // c.srli shamt=1
        16'h8405, // c.srai shamt=1
        16'h8805, // c.andi
        16'h8C01, // c.sub
        16'h8C21, // c.xor
        16'h8C41, // c.or
        16'h8C61, // c.and
        16'hA001, // c.j
        16'hC001, // c.beqz
        16'hE001, // c.bnez
        16'h8001, // c.srli shamt0 illegal
        16'h9001, // c.srli reserved bit12 illegal
        // Q2
        16'h0086, // c.slli x1,1
        16'h0002, // c.slli illegal (rd/shamt)
        16'h4082, // c.lwsp x1
        16'h4002, // c.lwsp x0 illegal
        16'h8082, // c.jr x1
        16'h8086, // c.mv x1,x1
        16'h9002, // c.ebreak
        16'h9082, // c.jalr x1
        16'h9086, // c.add x1,x1
        16'h8002, // c.jr x0 illegal
        16'hC006, // c.swsp
        16'h2002, // Q2 illegal funct3
        // Uncompressed
        16'h0003,
        16'hFFFF
      };

      foreach (directed[i]) send_c(directed[i]);

      // Quadrant sweeps + free random (no constraint solver)
      for (int q = 0; q < 4; q++) begin
        repeat (128) begin
          sis_decompress_item item;
          item = sis_decompress_item::type_id::create("item");
          start_item(item);
          item.c_instr = {$urandom, $urandom};
          item.c_instr[1:0] = q[1:0];
          finish_item(item);
        end
      end
      repeat (512) begin
        sis_decompress_item item;
        item = sis_decompress_item::type_id::create("item");
        start_item(item);
        item.c_instr = {$urandom, $urandom};
        finish_item(item);
      end
    endtask
  endclass

endpackage
