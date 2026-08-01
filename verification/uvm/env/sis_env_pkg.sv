package sis_env_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sis_decompress_pkg::*;
  import sis_tohost_pkg::*;
  import sis_jtag_pkg::*;

  class sis_decompress_env extends uvm_env;
    `uvm_component_utils(sis_decompress_env)
    sis_decompress_agent      agent;
    sis_decompress_scoreboard scoreboard;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent      = sis_decompress_agent::type_id::create("agent", this);
      scoreboard = sis_decompress_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      agent.monitor.ap.connect(scoreboard.imp);
    endfunction
  endclass

  class sis_platform_env extends uvm_env;
    `uvm_component_utils(sis_platform_env)
    sis_tohost_agent tohost;
    sis_jtag_agent   jtag;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      tohost = sis_tohost_agent::type_id::create("tohost", this);
      jtag   = sis_jtag_agent::type_id::create("jtag", this);
    endfunction
  endclass

endpackage
