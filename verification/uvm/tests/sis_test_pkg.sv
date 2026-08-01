package sis_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sis_decompress_pkg::*;
  import sis_tohost_pkg::*;
  import sis_jtag_pkg::*;
  import sis_env_pkg::*;

  // Shared base: quiet Verilator UVM_NO_DPI name-check noise; fail the process
  // on UVM_ERROR/FATAL so Make/CI see a non-zero exit.
  class sis_uvm_test_base extends uvm_test;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_root::get().set_report_id_action_hier("UVM/COMP/NAME", UVM_NO_ACTION);
      uvm_root::get().set_report_id_action_hier("UVM/COMP/NAMECHECK", UVM_NO_ACTION);
    endfunction

    function void report_phase(uvm_phase phase);
      uvm_report_server rs;
      int unsigned n_err, n_fatal;
      super.report_phase(phase);
      rs = uvm_report_server::get_server();
      n_err   = rs.get_severity_count(UVM_ERROR);
      n_fatal = rs.get_severity_count(UVM_FATAL);
      if (n_err + n_fatal > 0)
        $fatal(1, "UVM test failed: %0d errors, %0d fatals", n_err, n_fatal);
    endfunction
  endclass

  class sis_decompress_smoke_test extends sis_uvm_test_base;
    `uvm_component_utils(sis_decompress_smoke_test)
    sis_decompress_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = sis_decompress_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      sis_decompress_smoke_seq seq;
      phase.raise_objection(this);
      seq = sis_decompress_smoke_seq::type_id::create("seq");
      seq.start(env.agent.sequencer);
      #10;
      phase.drop_objection(this);
    endtask
  endclass

  class sis_platform_tohost_test extends sis_uvm_test_base;
    `uvm_component_utils(sis_platform_tohost_test)
    sis_platform_env env;
    uvm_analysis_imp #(sis_tohost_item, sis_platform_tohost_test) tohost_imp;
    sis_tohost_status_e result;
    bit got_result;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      got_result = 0;
      result = TOHOST_NONE;
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = sis_platform_env::type_id::create("env", this);
      tohost_imp = new("tohost_imp", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      env.tohost.monitor.ap.connect(tohost_imp);
    endfunction

    function void write(sis_tohost_item t);
      result = t.status;
      got_result = 1;
      `uvm_info("TOHOST",
        $sformatf("status=%s code=0x%08h cycle=%0d", t.status.name(), t.code, t.cycle),
        UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      fork
        env.jtag.driver.smoke();
        begin
          wait (got_result);
          if (result != TOHOST_PASS)
            `uvm_error("TOHOST", $sformatf("platform test ended with %s", result.name()))
        end
      join
      phase.drop_objection(this);
    endtask
  endclass

endpackage
