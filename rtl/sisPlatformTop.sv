// sisPlatformTop.sv — Top-level integration
// Connects: CPU core -> Memory Fabric -> ROM, RAM, Tohost
//
// Parameter USE_AXIL:
//   0 = Direct corebus routing via sisMemFabric (default, lower latency)
//   1 = Route through AXI4-Lite bridge -> AXI-Lite slave model

module sisPlatformTop #(
    parameter ROM_INIT_FILE = "rom.hex",
    parameter RAM_INIT_FILE = "",
    parameter int USE_AXIL  = 0,         // 0=corebus, 1=AXI4-Lite path
    parameter int AXIL_STALL_RATE = 0,   // stall injection % for AXI slave (TB only)
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000
)(
    input  logic clk,
    input  logic rst_n,

    // Status outputs (directly accessible by testbench)
    output logic        tohost_pass,
    output logic        tohost_fail,
    output logic [31:0] tohost_code,

    input  logic [31:0] gpio_in,
    output logic [31:0] gpio_out,
    output logic [31:0] gpio_oe,

    input  logic [7:0]  plic_irq,
    input  logic        jtag_tck,
    input  logic        jtag_tms,
    input  logic        jtag_tdi,
    output logic        jtag_tdo,

    output logic        uart_tx_valid,
    output logic [7:0]  uart_tx_data
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
  // Timer / CLINT / PLIC signals
  // ---------------------------------------------------------------
  logic        clint_req_valid, clint_req_ready;
  logic [31:0] clint_req_addr;
  logic        clint_req_we;
  logic [31:0] clint_req_wdata;
  logic [3:0]  clint_req_wstrb;
  logic        clint_rsp_valid, clint_rsp_ready;
  logic [31:0] clint_rsp_rdata;
  logic        clint_rsp_err;
  logic        plic_req_valid, plic_req_ready;
  logic [31:0] plic_req_addr;
  logic        plic_req_we;
  logic [31:0] plic_req_wdata;
  logic [3:0]  plic_req_wstrb;
  logic        plic_rsp_valid, plic_rsp_ready;
  logic [31:0] plic_rsp_rdata;
  logic        plic_rsp_err;
  logic        msip_wire, mtip_wire, meip_wire;
  logic        mtip_clint, msip_clint, meip_plic;
  logic        mtip_axil, msip_axil, meip_axil;

  logic        tohost_req_valid, tohost_req_ready;
  logic        tohost_rsp_valid, tohost_rsp_ready;
  logic [31:0] tohost_rsp_rdata;
  logic        tohost_rsp_err;
  logic        gpio_req_valid, gpio_req_ready;
  logic        gpio_rsp_valid, gpio_rsp_ready;
  logic [31:0] gpio_rsp_rdata;
  logic        gpio_rsp_err;
  logic        uart_req_valid, uart_req_ready;
  logic        uart_rsp_valid, uart_rsp_ready;
  logic [31:0] uart_rsp_rdata;
  logic        uart_rsp_err;

  logic [8:1]  plic_irq_mux;

  // Map TB GPIO + package IRQ pins to PLIC sources 1..8 (1-indexed)
  genvar gi;
  generate
    for (gi = 1; gi <= 8; gi++) begin : gen_plic_irq
      assign plic_irq_mux[gi] = plic_irq[gi-1] | gpio_out[gi];
    end
  endgenerate
  logic        dm_halt_req, dm_resume_req, dm_single_step, core_halted;
  logic        dmi_req_valid, dmi_req_ready, dmi_req_write;
  logic [6:0]  dmi_req_addr;
  logic [31:0] dmi_req_wdata, dmi_rsp_rdata;
  logic        dmi_rsp_valid, dmi_rsp_ready;
  logic        abs_valid, abs_ready, abs_write;
  logic [4:0]  abs_regaddr;
  logic [31:0] abs_wdata, abs_rdata;
  sisRvCore #(
    .RESET_VECTOR(RESET_VECTOR),
    .ENABLE_C    (1'b1)
  ) u_core (
    .clk            (clk),
    .rst_n          (rst_n),
    .dbg_halt_req   (dm_halt_req),
    .dbg_resume_req (dm_resume_req),
    .dbg_single_step(dm_single_step),
    .dbg_halted     (core_halted),
    .dbg_abs_valid  (abs_valid),
    .dbg_abs_ready  (abs_ready),
    .dbg_abs_write  (abs_write),
    .dbg_abs_regaddr(abs_regaddr),
    .dbg_abs_wdata  (abs_wdata),
    .dbg_abs_rdata  (abs_rdata),
    .ext_msip       (msip_wire),
    .ext_mtip       (mtip_wire),
    .ext_meip       (meip_wire),
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
  // CLINT + PLIC + Debug (shared by corebus and AXI paths)
  // ---------------------------------------------------------------
  sisClint u_clint (
    .clk       (clk),
    .rst_n     (rst_n),
    .req_valid (clint_req_valid),
    .req_ready (clint_req_ready),
    .req_addr  (clint_req_addr),
    .req_we    (clint_req_we),
    .req_wdata (clint_req_wdata),
    .req_wstrb (clint_req_wstrb),
    .rsp_valid (clint_rsp_valid),
    .rsp_ready (clint_rsp_ready),
    .rsp_rdata (clint_rsp_rdata),
    .rsp_err   (clint_rsp_err),
    .mtip      (mtip_clint),
    .msip      (msip_clint)
  );

  sisPlic #(
    .NUM_SOURCES(8)
  ) u_plic (
    .clk       (clk),
    .rst_n     (rst_n),
    .req_valid (plic_req_valid),
    .req_ready (plic_req_ready),
    .req_addr  (plic_req_addr),
    .req_we    (plic_req_we),
    .req_wdata (plic_req_wdata),
    .req_wstrb (plic_req_wstrb),
    .rsp_valid (plic_rsp_valid),
    .rsp_ready (plic_rsp_ready),
    .rsp_rdata (plic_rsp_rdata),
    .rsp_err   (plic_rsp_err),
    .irq_src   (plic_irq_mux),
    .meip      (meip_plic)
  );

  sisJtagDtm u_jtag_dtm (
    .clk           (clk),
    .rst_n         (rst_n),
    .tck           (jtag_tck),
    .tms           (jtag_tms),
    .tdi           (jtag_tdi),
    .tdo           (jtag_tdo),
    .dmi_req_valid (dmi_req_valid),
    .dmi_req_ready (dmi_req_ready),
    .dmi_req_write (dmi_req_write),
    .dmi_req_addr  (dmi_req_addr),
    .dmi_req_wdata (dmi_req_wdata),
    .dmi_rsp_valid (dmi_rsp_valid),
    .dmi_rsp_ready (dmi_rsp_ready),
    .dmi_rsp_rdata (dmi_rsp_rdata)
  );

  sisDm u_dm (
    .clk           (clk),
    .rst_n         (rst_n),
    .dmi_req_valid (dmi_req_valid),
    .dmi_req_ready (dmi_req_ready),
    .dmi_req_write (dmi_req_write),
    .dmi_req_addr  (dmi_req_addr),
    .dmi_req_wdata (dmi_req_wdata),
    .dmi_rsp_valid (dmi_rsp_valid),
    .dmi_rsp_ready (dmi_rsp_ready),
    .dmi_rsp_rdata (dmi_rsp_rdata),
    .halt_req      (dm_halt_req),
    .resume_req    (dm_resume_req),
    .single_step   (dm_single_step),
    .core_halted   (core_halted),
    .core_running  (~core_halted),
    .abs_valid     (abs_valid),
    .abs_ready     (abs_ready),
    .abs_write     (abs_write),
    .abs_regaddr   (abs_regaddr),
    .abs_wdata     (abs_wdata),
    .abs_rdata     (abs_rdata)
  );

  // ---------------------------------------------------------------
  // Memory Fabric — generate-selected path
  // ---------------------------------------------------------------
  generate
    if (USE_AXIL == 0) begin : gen_corebus
      wire unused_axil_stall_rate = |AXIL_STALL_RATE;

      // MMIO sub-router: 0x1000_0xxx tohost, 0x1000_3xxx GPIO, 0x1000_4xxx UART
      wire sel_gpio  = (mmio_req_addr[15:12] == 4'h3);
      wire sel_uart  = (mmio_req_addr[15:12] == 4'h4);

      assign tohost_req_valid = mmio_req_valid && !sel_gpio && !sel_uart;
      assign gpio_req_valid   = mmio_req_valid && sel_gpio;
      assign uart_req_valid   = mmio_req_valid && sel_uart;
      assign mmio_req_ready   = sel_gpio ? gpio_req_ready :
                                sel_uart ? uart_req_ready :
                                           tohost_req_ready;

      logic [1:0] mmio_sel_r;
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
          mmio_sel_r <= 2'd0;
        else if (mmio_req_valid && mmio_req_ready)
          mmio_sel_r <= sel_gpio ? 2'd2 : sel_uart ? 2'd3 : 2'd0;
      end

      assign mmio_rsp_valid = (mmio_sel_r == 2'd2) ? gpio_rsp_valid  :
                              (mmio_sel_r == 2'd3) ? uart_rsp_valid  :
                                                      tohost_rsp_valid;
      assign mmio_rsp_rdata = (mmio_sel_r == 2'd2) ? gpio_rsp_rdata  :
                              (mmio_sel_r == 2'd3) ? uart_rsp_rdata  :
                                                      tohost_rsp_rdata;
      assign mmio_rsp_err   = (mmio_sel_r == 2'd2) ? gpio_rsp_err  :
                              (mmio_sel_r == 2'd3) ? uart_rsp_err   :
                                                      tohost_rsp_err;
      assign gpio_rsp_ready   = mmio_rsp_ready && (mmio_sel_r == 2'd2);
      assign uart_rsp_ready   = mmio_rsp_ready && (mmio_sel_r == 2'd3);
      assign tohost_rsp_ready = mmio_rsp_ready && (mmio_sel_r == 2'd0);

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
        .s2_rsp_err  (mmio_rsp_err),

        .s3_req_valid(clint_req_valid),
        .s3_req_ready(clint_req_ready),
        .s3_req_addr (clint_req_addr),
        .s3_req_we   (clint_req_we),
        .s3_req_wdata(clint_req_wdata),
        .s3_req_wstrb(clint_req_wstrb),
        .s3_rsp_valid(clint_rsp_valid),
        .s3_rsp_ready(clint_rsp_ready),
        .s3_rsp_rdata(clint_rsp_rdata),
        .s3_rsp_err  (clint_rsp_err),

        .s4_req_valid(plic_req_valid),
        .s4_req_ready(plic_req_ready),
        .s4_req_addr (plic_req_addr),
        .s4_req_we   (plic_req_we),
        .s4_req_wdata(plic_req_wdata),
        .s4_req_wstrb(plic_req_wstrb),
        .s4_rsp_valid(plic_rsp_valid),
        .s4_rsp_ready(plic_rsp_ready),
        .s4_rsp_rdata(plic_rsp_rdata),
        .s4_rsp_err  (plic_rsp_err)
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
        .DEPTH_WORDS(65536),
        .INIT_FILE  (RAM_INIT_FILE)
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
      // GPIO (corebus path) — via sub-router
      // ---------------------------------------------------------------
      sisGpio #(
        .BASE_ADDR(32'h1000_3000)
      ) u_gpio (
        .clk       (clk),
        .rst_n     (rst_n),
        .req_valid (gpio_req_valid),
        .req_ready (gpio_req_ready),
        .req_addr  (mmio_req_addr),
        .req_we    (mmio_req_we),
        .req_wdata (mmio_req_wdata),
        .req_wstrb (mmio_req_wstrb),
        .rsp_valid (gpio_rsp_valid),
        .rsp_ready (gpio_rsp_ready),
        .rsp_rdata (gpio_rsp_rdata),
        .rsp_err   (gpio_rsp_err),
        .gpio_in   (gpio_in),
        .gpio_out  (gpio_out),
        .gpio_oe   (gpio_oe)
      );

      // ---------------------------------------------------------------
      // UART (corebus path) — via sub-router
      // ---------------------------------------------------------------
      sisUart #(
        .BASE_ADDR(32'h1000_4000)
      ) u_uart (
        .clk           (clk),
        .rst_n         (rst_n),
        .req_valid     (uart_req_valid),
        .req_ready     (uart_req_ready),
        .req_addr      (mmio_req_addr),
        .req_we        (mmio_req_we),
        .req_wdata     (mmio_req_wdata),
        .req_wstrb     (mmio_req_wstrb),
        .rsp_valid     (uart_rsp_valid),
        .rsp_ready     (uart_rsp_ready),
        .rsp_rdata     (uart_rsp_rdata),
        .rsp_err       (uart_rsp_err),
        .uart_tx_valid (uart_tx_valid),
        .uart_tx_data  (uart_tx_data)
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
        .last_code (tohost_code),
        .mtip      (mtip_axil),
        .msip      (msip_axil),
        .meip      (meip_axil),
        .plic_irq  (plic_irq),
        .gpio_in   (gpio_in),
        .gpio_out  (gpio_out),
        .gpio_oe   (gpio_oe),
        .uart_tx_valid (uart_tx_valid),
        .uart_tx_data  (uart_tx_data)
      );

      // Tie off unused corebus slave signals in AXI path
      assign rom_req_valid    = 1'b0;
      assign ram_req_valid    = 1'b0;
      assign rom_rsp_ready    = 1'b0;
      assign ram_rsp_ready    = 1'b0;
      // CLINT/PLIC/MMIO not used on direct corebus in AXI path
      assign clint_req_valid  = 1'b0;
      assign clint_req_addr   = 32'h0;
      assign clint_req_we     = 1'b0;
      assign clint_req_wdata  = 32'h0;
      assign clint_req_wstrb  = 4'h0;
      assign clint_req_ready  = 1'b0;
      assign clint_rsp_ready  = 1'b0;
      assign clint_rsp_valid  = 1'b0;
      assign clint_rsp_rdata  = 32'h0;
      assign clint_rsp_err    = 1'b0;
      assign plic_req_valid   = 1'b0;
      assign plic_req_addr    = 32'h0;
      assign plic_req_we      = 1'b0;
      assign plic_req_wdata   = 32'h0;
      assign plic_req_wstrb   = 4'h0;
      assign plic_req_ready   = 1'b0;
      assign plic_rsp_ready   = 1'b0;
      assign plic_rsp_valid   = 1'b0;
      assign plic_rsp_rdata   = 32'h0;
      assign plic_rsp_err     = 1'b0;
      assign mmio_req_valid   = 1'b0;
      assign mmio_rsp_ready   = 1'b0;
      assign tohost_req_valid = 1'b0;
      assign tohost_rsp_ready = 1'b0;
      assign gpio_req_valid   = 1'b0;
      assign gpio_req_ready   = 1'b0;
      assign gpio_rsp_ready   = 1'b0;
      assign gpio_rsp_valid   = 1'b0;
      assign gpio_rsp_rdata   = 32'h0;
      assign gpio_rsp_err     = 1'b0;
      assign uart_req_valid   = 1'b0;
      assign uart_req_ready   = 1'b0;
      assign uart_rsp_ready   = 1'b0;
      assign uart_rsp_valid   = 1'b0;
      assign uart_rsp_rdata   = 32'h0;
      assign uart_rsp_err     = 1'b0;
      assign mmio_req_ready   = 1'b0;
      assign mmio_rsp_valid   = 1'b0;
      assign mmio_rsp_rdata   = 32'h0;
      assign mmio_rsp_err     = 1'b0;

    end
  endgenerate

  generate
    if (USE_AXIL == 0) begin : gen_irq_mux
      assign mtip_wire = mtip_clint;
      assign msip_wire = msip_clint;
      assign meip_wire = meip_plic;
    end else begin : gen_irq_mux_axil
      assign mtip_wire = mtip_axil;
      assign msip_wire = msip_axil;
      assign meip_wire = meip_axil;
    end
  endgenerate

endmodule
