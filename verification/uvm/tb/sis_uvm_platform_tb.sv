// Platform-level UVM TB around sisPlatformTop (wraps the same DUT as sisTbTop).
module sis_uvm_platform_tb;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import sis_test_pkg::*;

  localparam int DEFAULT_TIMEOUT_CYCLES = 1_000_000;

  logic clk;
  logic rst_n;
  logic [31:0] gpio_in;
  logic [7:0]  plic_irq;
  logic        jtag_tck, jtag_tms, jtag_tdi, jtag_tdo;
  logic [31:0] gpio_out, gpio_oe;
  logic        uart_tx_valid;
  logic [7:0]  uart_tx_data;
  logic        tohost_pass, tohost_fail;
  logic [31:0] tohost_code;
  int unsigned timeout_cycles;
  int unsigned cycle;
  string rom_hex, ram_hex;

  sis_tohost_if th_if (.clk(clk));

  initial clk = 0;
  always #5 clk = ~clk;

  assign th_if.rst_n        = rst_n;
  assign th_if.tohost_pass  = tohost_pass;
  assign th_if.tohost_fail  = tohost_fail;
  assign th_if.tohost_code  = tohost_code;
  assign th_if.cycle        = cycle;

  sisPlatformTop #(
    .ROM_INIT_FILE("rom.hex"),
    .RAM_INIT_FILE("ram.hex"),
    .USE_AXIL(0),
    .RESET_VECTOR(32'h0000_0000)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .tohost_pass(tohost_pass),
    .tohost_fail(tohost_fail),
    .tohost_code(tohost_code),
    .gpio_in(gpio_in),
    .gpio_out(gpio_out),
    .gpio_oe(gpio_oe),
    .plic_irq(plic_irq),
    .jtag_tck(jtag_tck),
    .jtag_tms(jtag_tms),
    .jtag_tdi(jtag_tdi),
    .jtag_tdo(jtag_tdo),
    .uart_tx_valid(uart_tx_valid),
    .uart_tx_data(uart_tx_data)
  );

  // UVM requires run_test() at time 0; drive reset in a separate process.
  initial begin
    gpio_in = '0;
    plic_irq = '0;
    jtag_tck = 0;
    jtag_tms = 0;
    jtag_tdi = 0;
    cycle = 0;
    timeout_cycles = DEFAULT_TIMEOUT_CYCLES;
    if (!$value$plusargs("ROM_HEX=%s", rom_hex)) rom_hex = "rom.hex";
    if (!$value$plusargs("RAM_HEX=%s", ram_hex)) ram_hex = "ram.hex";
    void'($value$plusargs("TIMEOUT_CYCLES=%d", timeout_cycles));
    uvm_config_db#(virtual sis_tohost_if)::set(null, "*", "vif", th_if);
    uvm_config_db#(int unsigned)::set(null, "*", "timeout_cycles", timeout_cycles);
    run_test();
  end

  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  always @(posedge clk) begin
    if (!rst_n) cycle <= 0;
    else        cycle <= cycle + 1;
  end
endmodule
