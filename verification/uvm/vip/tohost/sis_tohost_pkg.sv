package sis_tohost_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum { TOHOST_NONE, TOHOST_PASS, TOHOST_FAIL, TOHOST_TIMEOUT } sis_tohost_status_e;

  class sis_tohost_item extends uvm_sequence_item;
    sis_tohost_status_e status;
    bit [31:0]          code;
    int unsigned        cycle;
    `uvm_object_utils_begin(sis_tohost_item)
      `uvm_field_enum(sis_tohost_status_e, status, UVM_ALL_ON)
      `uvm_field_int(code, UVM_ALL_ON)
      `uvm_field_int(cycle, UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name = "sis_tohost_item");
      super.new(name);
    endfunction
  endclass

  class sis_tohost_monitor extends uvm_monitor;
    `uvm_component_utils(sis_tohost_monitor)
    virtual sis_tohost_if vif;
    uvm_analysis_port #(sis_tohost_item) ap;
    int unsigned timeout_cycles;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
      timeout_cycles = 1_000_000;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      void'(uvm_config_db#(int unsigned)::get(this, "", "timeout_cycles", timeout_cycles));
      if (!uvm_config_db#(virtual sis_tohost_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "sis_tohost_if not set")
    endfunction

    task run_phase(uvm_phase phase);
      sis_tohost_item item;
      forever begin
        @(posedge vif.clk);
        if (!vif.rst_n) continue;
        if (vif.tohost_pass || vif.tohost_fail || (vif.cycle >= timeout_cycles)) begin
          item = sis_tohost_item::type_id::create("item");
          item.cycle = vif.cycle;
          item.code  = vif.tohost_code;
          if (vif.tohost_pass)       item.status = TOHOST_PASS;
          else if (vif.tohost_fail)  item.status = TOHOST_FAIL;
          else                       item.status = TOHOST_TIMEOUT;
          ap.write(item);
          return;
        end
      end
    endtask
  endclass

  class sis_tohost_agent extends uvm_agent;
    `uvm_component_utils(sis_tohost_agent)
    sis_tohost_monitor monitor;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      monitor = sis_tohost_monitor::type_id::create("monitor", this);
    endfunction
  endclass

endpackage
