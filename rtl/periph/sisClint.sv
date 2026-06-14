// sisClint.sv — RISC-V Core-Local Interruptor (CLINT)
// Standard layout per privileged spec / SiFive convention:
//   BASE + 0x0000: msip[hart]
//   BASE + 0x4000: mtimecmp[hart] (64-bit)
//   BASE + 0xBFF8: mtime (64-bit, shared)
//
// Parameter BASE_ADDR defaults to 0x0200_0000.

module sisClint #(
    parameter logic [31:0] BASE_ADDR = 32'h0200_0000,
    parameter int          NUM_HARTS = 1
)(
    input  logic        clk,
    input  logic        rst_n,

    // Corebus slave
    input  logic        req_valid,
    output logic        req_ready,
    input  logic [31:0] req_addr,
    input  logic        req_we,
    input  logic [31:0] req_wdata,
    input  logic [3:0]  req_wstrb,

    output logic        rsp_valid,
    input  logic        rsp_ready,
    output logic [31:0] rsp_rdata,
    output logic        rsp_err,

    // Interrupt outputs (per hart; only hart 0 used today)
    output logic        mtip,
    output logic        msip
);

  localparam logic [31:0] OFF_MSIP      = 32'h0000;
  localparam logic [31:0] OFF_MTIMECMP  = 32'h4000;
  localparam logic [31:0] OFF_MTIME     = 32'hBFF8;

  logic [63:0] mtime;
  logic [63:0] mtimecmp;
  logic [63:0] mtime_next;
  logic        msip_reg;

  logic        pending;
  logic [31:0] rdata_reg;

  wire addr_match = (req_addr[31:16] == BASE_ADDR[31:16]);
  wire [31:0] rel = req_addr - BASE_ADDR;

  assign req_ready = !pending || rsp_ready;

  // Increment MTIME every cycle; byte writes overlay in the same cycle.
  always_comb begin
    mtime_next = mtime + 64'd1;
    if (req_valid && req_ready && addr_match && req_we) begin
      if (rel == OFF_MTIME) begin
        if (req_wstrb[0]) mtime_next[7:0]   = req_wdata[7:0];
        if (req_wstrb[1]) mtime_next[15:8]  = req_wdata[15:8];
        if (req_wstrb[2]) mtime_next[23:16] = req_wdata[23:16];
        if (req_wstrb[3]) mtime_next[31:24] = req_wdata[31:24];
      end else if (rel == OFF_MTIME + 16'd4) begin
        if (req_wstrb[0]) mtime_next[39:32] = req_wdata[7:0];
        if (req_wstrb[1]) mtime_next[47:40] = req_wdata[15:8];
        if (req_wstrb[2]) mtime_next[55:48] = req_wdata[23:16];
        if (req_wstrb[3]) mtime_next[63:56] = req_wdata[31:24];
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mtime    <= 64'h0;
      mtimecmp <= 64'hFFFF_FFFF_FFFF_FFFF;
      msip_reg <= 1'b0;
      pending  <= 1'b0;
      rdata_reg <= 32'h0;
    end else begin
      mtime <= mtime_next;

      if (req_valid && req_ready) begin
        pending <= 1'b1;
        if (addr_match && req_we) begin
          if (rel == OFF_MSIP && req_wstrb[0])
            msip_reg <= |req_wdata[0];
          else if (rel == OFF_MTIMECMP) begin
            if (req_wstrb[0]) mtimecmp[7:0]   <= req_wdata[7:0];
            if (req_wstrb[1]) mtimecmp[15:8]  <= req_wdata[15:8];
            if (req_wstrb[2]) mtimecmp[23:16] <= req_wdata[23:16];
            if (req_wstrb[3]) mtimecmp[31:24] <= req_wdata[31:24];
          end else if (rel == OFF_MTIMECMP + 16'd4) begin
            if (req_wstrb[0]) mtimecmp[39:32] <= req_wdata[7:0];
            if (req_wstrb[1]) mtimecmp[47:40] <= req_wdata[15:8];
            if (req_wstrb[2]) mtimecmp[55:48] <= req_wdata[23:16];
            if (req_wstrb[3]) mtimecmp[63:56] <= req_wdata[31:24];
          end
        end
        if (addr_match && !req_we) begin
          unique case (rel)
            OFF_MSIP:                    rdata_reg <= {31'b0, msip_reg};
            OFF_MTIMECMP:                rdata_reg <= mtimecmp[31:0];
            OFF_MTIMECMP + 16'd4:        rdata_reg <= mtimecmp[63:32];
            OFF_MTIME:                   rdata_reg <= mtime[31:0];
            OFF_MTIME + 16'd4:           rdata_reg <= mtime[63:32];
            default:                     rdata_reg <= 32'h0;
          endcase
        end else begin
          rdata_reg <= 32'h0;
        end
      end else if (rsp_valid && rsp_ready) begin
        pending <= 1'b0;
      end
    end
  end

  assign rsp_valid = pending;
  assign rsp_rdata = rdata_reg;
  assign rsp_err   = 1'b0;

  assign mtip = (mtime >= mtimecmp);
  assign msip = msip_reg;

endmodule
