module sisTbTop;
  localparam logic [31:0] RESET_VECTOR = 32'h0000_0000;
  localparam int DEFAULT_TIMEOUT_CYCLES = 1_000_000;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic [31:0] gpio_in = '0;
  logic [7:0] plic_irq = '0;
  logic jtag_tck = 1'b0;
  logic jtag_tms = 1'b0;
  logic jtag_tdi = 1'b0;
  logic jtag_tdo;
  logic [31:0] gpio_out;
  logic [31:0] gpio_oe;
  logic uart_tx_valid;
  logic [7:0] uart_tx_data;
  logic tohost_pass;
  logic tohost_fail;
  logic [31:0] tohost_code;
  integer timeout_cycles;
  integer cycle;
  string rom_hex;
  string ram_hex;
  string commit_log;
  integer commit_fd;

  always #5 clk = ~clk;

  sisPlatformTop #(
    .ROM_INIT_FILE("rom.hex"),
    .RAM_INIT_FILE("ram.hex"),
    .USE_AXIL(0),
    .RESET_VECTOR(RESET_VECTOR)
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

  initial begin
    timeout_cycles = DEFAULT_TIMEOUT_CYCLES;
    if (!$value$plusargs("ROM_HEX=%s", rom_hex)) rom_hex = "rom.hex";
    if (!$value$plusargs("RAM_HEX=%s", ram_hex)) ram_hex = "ram.hex";
    void'($value$plusargs("TIMEOUT_CYCLES=%d", timeout_cycles));
    if ($value$plusargs("COMMIT_LOG=%s", commit_log)) begin
      commit_fd = $fopen(commit_log, "w");
      if (!commit_fd) $fatal(2, "Unable to open COMMIT_LOG=%s", commit_log);
    end else begin
      commit_fd = 0;
    end
    if (rom_hex != "rom.hex")
      $display("ROM_HEX=%s (staged as rom.hex for the parameterized DUT)", rom_hex);
    if (ram_hex != "ram.hex")
      $display("RAM_HEX=%s (staged as ram.hex for the parameterized DUT)", ram_hex);
    repeat (5) @(posedge clk);
    rst_n <= 1'b1;
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      cycle <= 0;
    end else begin
      cycle <= cycle + 1;
      if (commit_fd) $fdisplay(commit_fd, "%0d", cycle);
      if (tohost_pass) begin
        $display("*** PASS *** (tohost=0x%08x) at cycle %0d", tohost_code, cycle);
        if (commit_fd) $fclose(commit_fd);
        $finish(0);
      end
      if (tohost_fail) begin
        $display("*** FAIL *** (tohost=0x%08x) at cycle %0d", tohost_code, cycle);
        if (commit_fd) $fclose(commit_fd);
        $fatal(1);
      end
      if (cycle >= timeout_cycles) begin
        $display("*** TIMEOUT *** at cycle %0d", cycle);
        if (commit_fd) $fclose(commit_fd);
        $fatal(1);
      end
    end
  end
endmodule
