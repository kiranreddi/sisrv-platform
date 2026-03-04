// sisRam.sv — RAM with optional $readmemh initialization
// Corebus-compatible: single-cycle response for reads and writes.
// Supports byte-level write strobes.

module sisRam #(
    parameter int DEPTH_WORDS = 65536, // 256KB / 4 = 65536 words
    parameter     INIT_FILE   = ""
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
    output logic        rsp_err
);

  localparam AW = $clog2(DEPTH_WORDS);

  logic [31:0] mem [0:DEPTH_WORDS-1];

  // Note: initial blocks are sim-only. For synthesis, RAM contents are
  // undefined at power-on (SRAM macro) or zero-initialized (FPGA BRAM).
  initial begin
    for (int i = 0; i < DEPTH_WORDS; i++) mem[i] = 32'h0;
`ifndef SYNTHESIS
    if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
`endif
  end

  // Single-cycle response
  logic        pending;
  logic [31:0] rdata_reg;

  assign req_ready = !pending || rsp_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending   <= 1'b0;
      rdata_reg <= 32'h0;
    end else begin
      if (req_valid && req_ready) begin
        if (req_we) begin
          // Byte-level write
          if (req_wstrb[0]) mem[req_addr[AW+1:2]][7:0]   <= req_wdata[7:0];
          if (req_wstrb[1]) mem[req_addr[AW+1:2]][15:8]  <= req_wdata[15:8];
          if (req_wstrb[2]) mem[req_addr[AW+1:2]][23:16] <= req_wdata[23:16];
          if (req_wstrb[3]) mem[req_addr[AW+1:2]][31:24] <= req_wdata[31:24];
        end
        rdata_reg <= mem[req_addr[AW+1:2]];
        pending   <= 1'b1;
      end else if (rsp_valid && rsp_ready) begin
        pending <= 1'b0;
      end
    end
  end

  assign rsp_valid = pending;
  assign rsp_rdata = rdata_reg;
  assign rsp_err   = 1'b0;

endmodule
