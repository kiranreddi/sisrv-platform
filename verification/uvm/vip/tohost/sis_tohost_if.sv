interface sis_tohost_if (input logic clk);
  logic        rst_n;
  logic        tohost_pass;
  logic        tohost_fail;
  logic [31:0] tohost_code;
  int unsigned cycle;
endinterface
