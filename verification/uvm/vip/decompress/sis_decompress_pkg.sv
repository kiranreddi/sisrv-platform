package sis_decompress_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class sis_decompress_item extends uvm_sequence_item;
    rand bit [15:0] c_instr;
    bit [31:0]      instr_o;
    bit             is_compressed_o;
    bit             illegal_o;

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
    int unsigned seen;
    int unsigned errors;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      imp = new("imp", this);
    endfunction

    function void write(sis_decompress_item t);
      bit expect_c;
      seen++;
      expect_c = (t.c_instr[1:0] != 2'b11);
      if (t.is_compressed_o !== expect_c) begin
        errors++;
        `uvm_error("DEC_SB",
          $sformatf("c_instr=%04h is_compressed_o=%0d expected=%0d",
                    t.c_instr, t.is_compressed_o, expect_c))
      end
      if (!expect_c && t.illegal_o) begin
        errors++;
        `uvm_error("DEC_SB",
          $sformatf("uncompressed c_instr=%04h raised illegal_o", t.c_instr))
      end
      // Directed golden: c.nop
      if (t.c_instr == 16'h0001) begin
        if (t.instr_o !== 32'h0000_0013 || t.illegal_o) begin
          errors++;
          `uvm_error("DEC_SB",
            $sformatf("c.nop mismatch instr=%08h illegal=%0d", t.instr_o, t.illegal_o))
        end
      end
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info("DEC_SB", $sformatf("seen=%0d errors=%0d", seen, errors), UVM_LOW)
      if (errors != 0)
        `uvm_error("DEC_SB", "decompress scoreboard reported errors")
      if (seen == 0)
        `uvm_error("DEC_SB", "decompress scoreboard saw zero transactions")
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

  class sis_decompress_smoke_seq extends uvm_sequence #(sis_decompress_item);
    `uvm_object_utils(sis_decompress_smoke_seq)
    function new(string name = "sis_decompress_smoke_seq");
      super.new(name);
    endfunction

    task body();
      sis_decompress_item item;
      bit [15:0] directed[$];
      directed = '{
        16'h0001, // c.nop
        16'h0405, // c.addi x8,1
        16'h0000, // illegal addi4spn imm0
        16'h0003, // uncompressed marker
        16'hFFFF
      };
      foreach (directed[i]) begin
        item = sis_decompress_item::type_id::create("item");
        start_item(item);
        item.c_instr = directed[i];
        finish_item(item);
      end
      repeat (64) begin
        item = sis_decompress_item::type_id::create("item");
        start_item(item);
        if (!item.randomize())
          `uvm_fatal("SEQ", "randomize failed")
        finish_item(item);
      end
    endtask
  endclass

endpackage
