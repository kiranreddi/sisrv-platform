// Unit-level UVM TB for sisDecompress (Verilator + commercial).
module sis_uvm_decompress_tb;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sis_test_pkg::*;

  sis_decompress_if vif ();
  sisDecompress dut (
    .c_instr(vif.c_instr),
    .instr_o(vif.instr_o),
    .is_compressed_o(vif.is_compressed_o),
    .illegal_o(vif.illegal_o)
  );

  initial begin
    uvm_config_db#(virtual sis_decompress_if)::set(null, "*", "vif", vif);
    run_test();
  end
endmodule
