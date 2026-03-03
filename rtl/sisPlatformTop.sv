// sisPlatformTop.sv — Top-level integration
// Connects: CPU core -> Memory Fabric -> ROM, RAM, Tohost
//
// Parameter USE_AXIL:
//   0 = Direct corebus routing via sisMemFabric (default, lower latency)
//   1 = Route through AXI4-Lite bridge -> AXI-Lite slave model

module sisPlatformTop #(
    parameter ROM_INIT_FILE = "rom.hex",
    parameter USE_AXIL      = 0,         // 0=corebus, 1=AXI4-Lite path
    parameter AXIL_STALL_RATE = 0        // stall injection % for AXI slave (TB only)
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
  // Timer MMIO signals
  // ---------------------------------------------------------------
  logic        timer_req_valid, timer_req_ready;
  logic [31:0] timer_req_addr;
  logic        timer_req_we;
  logic [31:0] timer_req_wdata;
  logic [3:0]  timer_req_wstrb;
  logic        timer_rsp_valid, timer_rsp_ready;
  logic [31:0] timer_rsp_rdata;
  logic        timer_rsp_err;
  logic        tohost_req_valid, tohost_req_ready;
  logic        tohost_rsp_valid, tohost_rsp_ready;
  logic [31:0] tohost_rsp_rdata;
  logic        tohost_rsp_err;
  logic        mtip_wire;

  // ---------------------------------------------------------------
  // CPU Core
  // ---------------------------------------------------------------
  sisRvCore #(
    .RESET_VECTOR(32'h0000_0000)
  ) u_core (
    .clk       (clk),
    .rst_n     (rst_n),
    .ext_mtip  (mtip_wire),
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
  // Memory Fabric — generate-selected path
  // ---------------------------------------------------------------
  generate
    if (USE_AXIL == 0) begin : gen_corebus
      // ---------------------------------------------------------------
      // MMIO sub-router: tohost (0x1000_0xxx) vs timer (0x1000_2xxx)
      // ---------------------------------------------------------------
      wire sel_timer = (mmio_req_addr[15:12] == 4'h2); // 0x1000_2xxx

      assign tohost_req_valid = mmio_req_valid && !sel_timer;
      assign timer_req_valid  = mmio_req_valid && sel_timer;
      assign timer_req_addr   = mmio_req_addr;
      assign timer_req_we     = mmio_req_we;
      assign timer_req_wdata  = mmio_req_wdata;
      assign timer_req_wstrb  = mmio_req_wstrb;
      assign mmio_req_ready   = sel_timer ? timer_req_ready : tohost_req_ready;

      // MMIO response mux
      logic mmio_sel_timer_r;
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
          mmio_sel_timer_r <= 1'b0;
        else if (mmio_req_valid && mmio_req_ready)
          mmio_sel_timer_r <= sel_timer;
      end

      assign mmio_rsp_valid = mmio_sel_timer_r ? timer_rsp_valid : tohost_rsp_valid;
      assign mmio_rsp_rdata = mmio_sel_timer_r ? timer_rsp_rdata : tohost_rsp_rdata;
      assign mmio_rsp_err   = mmio_sel_timer_r ? timer_rsp_err   : tohost_rsp_err;
      assign timer_rsp_ready  = mmio_rsp_ready && mmio_sel_timer_r;
      assign tohost_rsp_ready = mmio_rsp_ready && !mmio_sel_timer_r;

      // ---------------------------------------------------------------
      // Direct corebus routing (default)
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
      // ROM (corebus path)
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
      // RAM (corebus path)
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
      // Tohost MMIO (corebus path) — via sub-router
      // ---------------------------------------------------------------
      sisTohost #(
        .BASE_ADDR(32'h1000_0000)
      ) u_tohost (
        .clk       (clk),
        .rst_n     (rst_n),
        .req_valid (tohost_req_valid),
        .req_ready (tohost_req_ready),
        .req_addr  (mmio_req_addr),
        .req_we    (mmio_req_we),
        .req_wdata (mmio_req_wdata),
        .req_wstrb (mmio_req_wstrb),
        .rsp_valid (tohost_rsp_valid),
        .rsp_ready (tohost_rsp_ready),
        .rsp_rdata (tohost_rsp_rdata),
        .rsp_err   (tohost_rsp_err),
        .pass      (tohost_pass),
        .fail      (tohost_fail),
        .last_code (tohost_code)
      );

      // ---------------------------------------------------------------
      // Timer (corebus path) — via sub-router
      // ---------------------------------------------------------------
      sisTimer #(
        .BASE_ADDR(32'h1000_2000)
      ) u_timer (
        .clk       (clk),
        .rst_n     (rst_n),
        .req_valid (timer_req_valid),
        .req_ready (timer_req_ready),
        .req_addr  (timer_req_addr),
        .req_we    (timer_req_we),
        .req_wdata (timer_req_wdata),
        .req_wstrb (timer_req_wstrb),
        .rsp_valid (timer_rsp_valid),
        .rsp_ready (timer_rsp_ready),
        .rsp_rdata (timer_rsp_rdata),
        .rsp_err   (timer_rsp_err),
        .mtip      (mtip_wire)
      );

    end else begin : gen_axilite
      // ---------------------------------------------------------------
      // AXI4-Lite path: core -> bridge -> AXI-Lite slave model
      // ---------------------------------------------------------------

      // AXI4-Lite signals between bridge and slave
      logic        axi_awvalid, axi_awready;
      logic [31:0] axi_awaddr;
      logic [2:0]  axi_awprot;
      logic        axi_wvalid, axi_wready;
      logic [31:0] axi_wdata;
      logic [3:0]  axi_wstrb;
      logic        axi_bvalid, axi_bready;
      logic [1:0]  axi_bresp;
      logic        axi_arvalid, axi_arready;
      logic [31:0] axi_araddr;
      logic [2:0]  axi_arprot;
      logic        axi_rvalid, axi_rready;
      logic [31:0] axi_rdata;
      logic [1:0]  axi_rresp;

      sisAxiLiteM u_axil_bridge (
        .clk       (clk),
        .rst_n     (rst_n),
        // Corebus side
        .req_valid (core_req_valid),
        .req_ready (core_req_ready),
        .req_addr  (core_req_addr),
        .req_we    (core_req_we),
        .req_wdata (core_req_wdata),
        .req_wstrb (core_req_wstrb),
        .rsp_valid (core_rsp_valid),
        .rsp_ready (core_rsp_ready),
        .rsp_rdata (core_rsp_rdata),
        .rsp_err   (core_rsp_err),
        // AXI4-Lite master side
        .awvalid   (axi_awvalid),
        .awready   (axi_awready),
        .awaddr    (axi_awaddr),
        .awprot    (axi_awprot),
        .wvalid    (axi_wvalid),
        .wready    (axi_wready),
        .wdata     (axi_wdata),
        .wstrb     (axi_wstrb),
        .bvalid    (axi_bvalid),
        .bready    (axi_bready),
        .bresp     (axi_bresp),
        .arvalid   (axi_arvalid),
        .arready   (axi_arready),
        .araddr    (axi_araddr),
        .arprot    (axi_arprot),
        .rvalid    (axi_rvalid),
        .rready    (axi_rready),
        .rdata     (axi_rdata),
        .rresp     (axi_rresp)
      );

      sisAxiLiteSlave #(
        .ROM_DEPTH_WORDS(16384),
        .RAM_DEPTH_WORDS(65536),
        .ROM_INIT_FILE  (ROM_INIT_FILE),
        .STALL_RATE     (AXIL_STALL_RATE)
      ) u_axil_slave (
        .clk       (clk),
        .rst_n     (rst_n),
        .awvalid   (axi_awvalid),
        .awready   (axi_awready),
        .awaddr    (axi_awaddr),
        .awprot    (axi_awprot),
        .wvalid    (axi_wvalid),
        .wready    (axi_wready),
        .wdata     (axi_wdata),
        .wstrb     (axi_wstrb),
        .bvalid    (axi_bvalid),
        .bready    (axi_bready),
        .bresp     (axi_bresp),
        .arvalid   (axi_arvalid),
        .arready   (axi_arready),
        .araddr    (axi_araddr),
        .arprot    (axi_arprot),
        .rvalid    (axi_rvalid),
        .rready    (axi_rready),
        .rdata     (axi_rdata),
        .rresp     (axi_rresp),
        .pass      (tohost_pass),
        .fail      (tohost_fail),
        .last_code (tohost_code)
      );

      // Tie off unused corebus slave signals in AXI path
      assign rom_req_valid    = 1'b0;
      assign ram_req_valid    = 1'b0;
      assign rom_rsp_ready    = 1'b0;
      assign ram_rsp_ready    = 1'b0;
      // No timer in AXI path (timer not modeled in AXI slave yet)
      assign mtip_wire        = 1'b0;
      // MMIO sub-router: tie off all signals (not used in AXI path)
      assign mmio_req_valid   = 1'b0;
      assign mmio_rsp_ready   = 1'b0;
      assign timer_req_valid  = 1'b0;
      assign timer_req_addr   = 32'h0;
      assign timer_req_we     = 1'b0;
      assign timer_req_wdata  = 32'h0;
      assign timer_req_wstrb  = 4'h0;
      assign timer_rsp_ready  = 1'b0;
      assign tohost_req_valid = 1'b0;
      assign tohost_rsp_ready = 1'b0;
      assign mmio_req_ready   = 1'b0;
      assign mmio_rsp_valid   = 1'b0;
      assign mmio_rsp_rdata   = 32'h0;
      assign mmio_rsp_err     = 1'b0;

    end
  endgenerate

endmodule
