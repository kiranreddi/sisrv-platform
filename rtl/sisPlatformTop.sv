// sisPlatformTop.sv — Top-level integration
// Connects: CPU core -> Memory Fabric -> ROM, RAM, Tohost

module sisPlatformTop #(
    parameter ROM_INIT_FILE = "rom.hex"
)(
    input  logic clk,
    input  logic rst_n,

    // Status outputs (directly accessible by testbench)
    output logic        tohost_pass,
    output logic        tohost_fail,
    output logic [31:0] tohost_code
);

  // ---------------------------------------------------------------
  // Core <-> Fabric corebus signals
  // ---------------------------------------------------------------
  logic        core_req_valid;
  logic        core_req_ready;
  logic [31:0] core_req_addr;
  logic        core_req_we;
  logic [31:0] core_req_wdata;
  logic [3:0]  core_req_wstrb;

  logic        core_rsp_valid;
  logic        core_rsp_ready;
  logic [31:0] core_rsp_rdata;
  logic        core_rsp_err;

  // ---------------------------------------------------------------
  // Fabric <-> ROM
  // ---------------------------------------------------------------
  logic        rom_req_valid, rom_req_ready;
  logic [31:0] rom_req_addr;
  logic        rom_req_we;
  logic [31:0] rom_req_wdata;
  logic [3:0]  rom_req_wstrb;
  logic        rom_rsp_valid, rom_rsp_ready;
  logic [31:0] rom_rsp_rdata;
  logic        rom_rsp_err;

  // ---------------------------------------------------------------
  // Fabric <-> RAM
  // ---------------------------------------------------------------
  logic        ram_req_valid, ram_req_ready;
  logic [31:0] ram_req_addr;
  logic        ram_req_we;
  logic [31:0] ram_req_wdata;
  logic [3:0]  ram_req_wstrb;
  logic        ram_rsp_valid, ram_rsp_ready;
  logic [31:0] ram_rsp_rdata;
  logic        ram_rsp_err;

  // ---------------------------------------------------------------
  // Fabric <-> Tohost (MMIO)
  // ---------------------------------------------------------------
  logic        mmio_req_valid, mmio_req_ready;
  logic [31:0] mmio_req_addr;
  logic        mmio_req_we;
  logic [31:0] mmio_req_wdata;
  logic [3:0]  mmio_req_wstrb;
  logic        mmio_rsp_valid, mmio_rsp_ready;
  logic [31:0] mmio_rsp_rdata;
  logic        mmio_rsp_err;

  // ---------------------------------------------------------------
  // CPU Core
  // ---------------------------------------------------------------
  sisRvCore #(
    .RESET_VECTOR(32'h0000_0000)
  ) u_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .req_valid (core_req_valid),
    .req_ready (core_req_ready),
    .req_addr  (core_req_addr),
    .req_we    (core_req_we),
    .req_wdata (core_req_wdata),
    .req_wstrb (core_req_wstrb),
    .rsp_valid (core_rsp_valid),
    .rsp_ready (core_rsp_ready),
    .rsp_rdata (core_rsp_rdata),
    .rsp_err   (core_rsp_err)
  );

  // ---------------------------------------------------------------
  // Memory Fabric
  // ---------------------------------------------------------------
  sisMemFabric u_fabric (
    .clk         (clk),
    .rst_n       (rst_n),

    .m_req_valid (core_req_valid),
    .m_req_ready (core_req_ready),
    .m_req_addr  (core_req_addr),
    .m_req_we    (core_req_we),
    .m_req_wdata (core_req_wdata),
    .m_req_wstrb (core_req_wstrb),
    .m_rsp_valid (core_rsp_valid),
    .m_rsp_ready (core_rsp_ready),
    .m_rsp_rdata (core_rsp_rdata),
    .m_rsp_err   (core_rsp_err),

    .s0_req_valid(rom_req_valid),
    .s0_req_ready(rom_req_ready),
    .s0_req_addr (rom_req_addr),
    .s0_req_we   (rom_req_we),
    .s0_req_wdata(rom_req_wdata),
    .s0_req_wstrb(rom_req_wstrb),
    .s0_rsp_valid(rom_rsp_valid),
    .s0_rsp_ready(rom_rsp_ready),
    .s0_rsp_rdata(rom_rsp_rdata),
    .s0_rsp_err  (rom_rsp_err),

    .s1_req_valid(ram_req_valid),
    .s1_req_ready(ram_req_ready),
    .s1_req_addr (ram_req_addr),
    .s1_req_we   (ram_req_we),
    .s1_req_wdata(ram_req_wdata),
    .s1_req_wstrb(ram_req_wstrb),
    .s1_rsp_valid(ram_rsp_valid),
    .s1_rsp_ready(ram_rsp_ready),
    .s1_rsp_rdata(ram_rsp_rdata),
    .s1_rsp_err  (ram_rsp_err),

    .s2_req_valid(mmio_req_valid),
    .s2_req_ready(mmio_req_ready),
    .s2_req_addr (mmio_req_addr),
    .s2_req_we   (mmio_req_we),
    .s2_req_wdata(mmio_req_wdata),
    .s2_req_wstrb(mmio_req_wstrb),
    .s2_rsp_valid(mmio_rsp_valid),
    .s2_rsp_ready(mmio_rsp_ready),
    .s2_rsp_rdata(mmio_rsp_rdata),
    .s2_rsp_err  (mmio_rsp_err)
  );

  // ---------------------------------------------------------------
  // ROM
  // ---------------------------------------------------------------
  sisRom #(
    .DEPTH_WORDS(16384),
    .INIT_FILE  (ROM_INIT_FILE)
  ) u_rom (
    .clk       (clk),
    .rst_n     (rst_n),
    .req_valid (rom_req_valid),
    .req_ready (rom_req_ready),
    .req_addr  (rom_req_addr),
    .req_we    (rom_req_we),
    .rsp_valid (rom_rsp_valid),
    .rsp_ready (rom_rsp_ready),
    .rsp_rdata (rom_rsp_rdata),
    .rsp_err   (rom_rsp_err)
  );

  // ---------------------------------------------------------------
  // RAM
  // ---------------------------------------------------------------
  sisRam #(
    .DEPTH_WORDS(65536)
  ) u_ram (
    .clk       (clk),
    .rst_n     (rst_n),
    .req_valid (ram_req_valid),
    .req_ready (ram_req_ready),
    .req_addr  (ram_req_addr),
    .req_we    (ram_req_we),
    .req_wdata (ram_req_wdata),
    .req_wstrb (ram_req_wstrb),
    .rsp_valid (ram_rsp_valid),
    .rsp_ready (ram_rsp_ready),
    .rsp_rdata (ram_rsp_rdata),
    .rsp_err   (ram_rsp_err)
  );

  // ---------------------------------------------------------------
  // Tohost MMIO
  // ---------------------------------------------------------------
  sisTohost #(
    .BASE_ADDR(32'h1000_0000)
  ) u_tohost (
    .clk       (clk),
    .rst_n     (rst_n),
    .req_valid (mmio_req_valid),
    .req_ready (mmio_req_ready),
    .req_addr  (mmio_req_addr),
    .req_we    (mmio_req_we),
    .req_wdata (mmio_req_wdata),
    .req_wstrb (mmio_req_wstrb),
    .rsp_valid (mmio_rsp_valid),
    .rsp_ready (mmio_rsp_ready),
    .rsp_rdata (mmio_rsp_rdata),
    .rsp_err   (mmio_rsp_err),
    .pass      (tohost_pass),
    .fail      (tohost_fail),
    .last_code (tohost_code)
  );

endmodule
