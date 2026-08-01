package sis_jtag_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Minimal JTAG bitbang to exercise sisJtagDtm TAP (IDLE → SHIFT-DR → EXIT).
  // Full DMI/DM VIP is a later phase; IR_DMI path needs a richer TAP model.
  class sis_jtag_driver extends uvm_component;
    `uvm_component_utils(sis_jtag_driver)
    virtual sis_jtag_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual sis_jtag_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "sis_jtag_if not set")
    endfunction

    task tck_cycle(bit tms, bit tdi);
      vif.tms <= tms;
      vif.tdi <= tdi;
      vif.tck <= 0;
      repeat (2) @(posedge vif.clk);
      vif.tck <= 1;
      repeat (2) @(posedge vif.clk);
      vif.tck <= 0;
      repeat (2) @(posedge vif.clk);
    endtask

    task smoke();
      wait (vif.rst_n === 1'b1);
      repeat (4) @(posedge vif.clk);
      // Stay in IDLE with TMS=1
      repeat (8) tck_cycle(1'b1, 1'b0);
      // Enter SHIFT-DR (TMS=0), shift a pattern, then EXIT (TMS=1)
      tck_cycle(1'b0, 1'b0);
      for (int i = 0; i < 32; i++)
        tck_cycle(1'b0, i[0]);
      tck_cycle(1'b1, 1'b0); // EXIT → update → IDLE
      repeat (4) tck_cycle(1'b1, 1'b0);
      `uvm_info("JTAG", "JTAG TAP smoke complete", UVM_LOW)
    endtask
  endclass

  class sis_jtag_agent extends uvm_agent;
    `uvm_component_utils(sis_jtag_agent)
    sis_jtag_driver driver;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      driver = sis_jtag_driver::type_id::create("driver", this);
    endfunction
  endclass

endpackage
