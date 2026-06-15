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

  logic        req_valid;
  logic        req_ready;
  logic [31:0] req_addr;
  logic        req_we;
  logic [31:0] req_wdata;
  logic [3:0]  req_wstrb;
  logic        rsp_valid;
  logic        rsp_ready;
  logic [31:0] rsp_rdata;
  logic        rsp_err;

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
    .req_valid      (req_valid),
    .req_ready      (req_ready),
    .req_addr       (req_addr),
    .req_we         (req_we),
    .req_wdata      (req_wdata),
    .req_wstrb      (req_wstrb),
    .rsp_valid      (rsp_valid),
    .rsp_ready      (rsp_ready),
    .rsp_rdata      (rsp_rdata),
    .rsp_err        (rsp_err)
  );

  wire rom_sel = (req_addr < (ROM_WORDS * 4));
  wire tohost_sel = (req_addr == TOHOST_ADDR);

  assign req_ready = !rsp_valid || rsp_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rsp_valid   <= 1'b0;
      rsp_rdata   <= 32'h0;
      rsp_err     <= 1'b0;
      tohost_pass <= 1'b0;
      tohost_fail <= 1'b0;
      tohost_code <= 32'h0;
    end else begin
      if (rsp_valid && rsp_ready) begin
        rsp_valid <= 1'b0;
      end

      if (req_valid && req_ready) begin
        rsp_valid <= 1'b1;
        rsp_rdata <= 32'h0;
        rsp_err   <= 1'b0;

        if (req_we && tohost_sel) begin
          tohost_code <= req_wdata;
          tohost_pass <= (req_wdata != 32'h0);
          tohost_fail <= (req_wdata == 32'h0);
        end else if (!req_we && rom_sel) begin
          rsp_rdata <= rom[req_addr[13:2]];
        end else if (!req_we) begin
          rsp_err <= 1'b1;
        end
      end
    end
  end

  wire unused_req_wstrb = |req_wstrb;

endmodule
