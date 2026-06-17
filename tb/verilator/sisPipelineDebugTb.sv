// sisPipelineDebugTb.sv - focused core debug/pipeline wrapper for Verilator.

module sisPipelineDebugTb #(
    parameter ROM_INIT_FILE = "rom.hex",
    parameter logic [31:0] RESET_VECTOR = 32'h0000_0000
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        dbg_halt_req,
    input  logic        dbg_resume_req,
    input  logic        dbg_single_step,
    output logic        dbg_halted,
    input  logic        dbg_abs_valid,
    output logic        dbg_abs_ready,
    input  logic        dbg_abs_write,
    input  logic [4:0]  dbg_abs_regaddr,
    input  logic [31:0] dbg_abs_wdata,
    output logic [31:0] dbg_abs_rdata,

    output logic        tohost_pass,
    output logic        tohost_fail,
    output logic [31:0] tohost_code
);

  localparam logic [31:0] TOHOST_ADDR = 32'h1000_0000;
  localparam int ROM_WORDS = 4096;

  logic        i_req_valid, i_req_ready;
  logic [31:0] i_req_addr;
  logic        i_rsp_valid, i_rsp_ready;
  logic [31:0] i_rsp_rdata;
  logic        i_rsp_err;

  logic        d_req_valid, d_req_ready;
  logic [31:0] d_req_addr;
  logic        d_req_we;
  logic [31:0] d_req_wdata;
  logic [3:0]  d_req_wstrb;
  logic        d_rsp_valid, d_rsp_ready;
  logic [31:0] d_rsp_rdata;
  logic        d_rsp_err;

  logic [31:0] rom [0:ROM_WORDS-1];

  initial begin
    $readmemh(ROM_INIT_FILE, rom);
  end

  sisRvCore #(
    .RESET_VECTOR(RESET_VECTOR),
    .ENABLE_C    (1'b1)
  ) u_core (
    .clk            (clk),
    .rst_n          (rst_n),
    .dbg_halt_req   (dbg_halt_req),
    .dbg_resume_req (dbg_resume_req),
    .dbg_single_step(dbg_single_step),
    .dbg_halted     (dbg_halted),
    .dbg_abs_valid  (dbg_abs_valid),
    .dbg_abs_ready  (dbg_abs_ready),
    .dbg_abs_write  (dbg_abs_write),
    .dbg_abs_regaddr(dbg_abs_regaddr),
    .dbg_abs_wdata  (dbg_abs_wdata),
    .dbg_abs_rdata  (dbg_abs_rdata),
    .ext_msip       (1'b0),
    .ext_mtip       (1'b0),
    .ext_meip       (1'b0),
    .i_req_valid    (i_req_valid),
    .i_req_ready    (i_req_ready),
    .i_req_addr     (i_req_addr),
    .i_rsp_valid    (i_rsp_valid),
    .i_rsp_ready    (i_rsp_ready),
    .i_rsp_rdata    (i_rsp_rdata),
    .i_rsp_err      (i_rsp_err),
    .d_req_valid    (d_req_valid),
    .d_req_ready    (d_req_ready),
    .d_req_addr     (d_req_addr),
    .d_req_we       (d_req_we),
    .d_req_wdata    (d_req_wdata),
    .d_req_wstrb    (d_req_wstrb),
    .d_rsp_valid    (d_rsp_valid),
    .d_rsp_ready    (d_rsp_ready),
    .d_rsp_rdata    (d_rsp_rdata),
    .d_rsp_err      (d_rsp_err)
  );

  wire i_rom_sel = (i_req_addr < (ROM_WORDS * 4));
  wire d_rom_sel = (d_req_addr < (ROM_WORDS * 4));
  wire tohost_sel = (d_req_addr == TOHOST_ADDR);

  assign i_req_ready = !i_rsp_valid || i_rsp_ready;
  assign d_req_ready = !d_rsp_valid || d_rsp_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      i_rsp_valid <= 1'b0;
      i_rsp_rdata <= 32'h0;
      i_rsp_err   <= 1'b0;
      d_rsp_valid <= 1'b0;
      d_rsp_rdata <= 32'h0;
      d_rsp_err   <= 1'b0;
      tohost_pass <= 1'b0;
      tohost_fail <= 1'b0;
      tohost_code <= 32'h0;
    end else begin
      if (i_rsp_valid && i_rsp_ready) begin
        i_rsp_valid <= 1'b0;
      end
      if (d_rsp_valid && d_rsp_ready) begin
        d_rsp_valid <= 1'b0;
      end

      if (i_req_valid && i_req_ready) begin
        i_rsp_valid <= 1'b1;
        i_rsp_rdata <= i_rom_sel ? rom[i_req_addr[13:2]] : 32'h0;
        i_rsp_err   <= !i_rom_sel;
      end

      if (d_req_valid && d_req_ready) begin
        d_rsp_valid <= 1'b1;
        d_rsp_rdata <= 32'h0;
        d_rsp_err   <= 1'b0;

        if (d_req_we && tohost_sel) begin
          tohost_code <= d_req_wdata;
          tohost_pass <= (d_req_wdata != 32'h0);
          tohost_fail <= (d_req_wdata == 32'h0);
        end else if (!d_req_we && d_rom_sel) begin
          d_rsp_rdata <= rom[d_req_addr[13:2]];
        end else if (!d_req_we) begin
          d_rsp_err <= 1'b1;
        end
      end
    end
  end

  wire unused_d_req_wstrb = |d_req_wstrb;

endmodule
