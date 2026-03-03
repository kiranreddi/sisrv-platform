// sisRom.sv — ROM with $readmemh initialization
// Corebus-compatible: single-cycle response for reads.

module sisRom #(
    parameter int DEPTH_WORDS = 16384, // 64KB / 4 = 16384 words
    parameter     INIT_FILE   = ""
)(
    input  logic        clk,
    input  logic        rst_n,

    // Corebus slave
    input  logic        req_valid,
    output logic        req_ready,
    input  logic [31:0] req_addr,
    input  logic        req_we,

    output logic        rsp_valid,
    input  logic        rsp_ready,
    output logic [31:0] rsp_rdata,
    output logic        rsp_err
);

  localparam AW = $clog2(DEPTH_WORDS);

  logic [31:0] mem [0:DEPTH_WORDS-1];

  // Initialize from hex file
  initial begin
    for (int i = 0; i < DEPTH_WORDS; i++) mem[i] = 32'h0000_0013; // NOP
    if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
  end

  // Single-cycle read response
  logic        pending;
  logic [31:0] rdata_reg;

  assign req_ready = !pending || rsp_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending   <= 1'b0;
      rdata_reg <= 32'h0;
    end else begin
      if (req_valid && req_ready && !req_we) begin
        rdata_reg <= mem[req_addr[AW+1:2]];
        pending   <= 1'b1;
      end else if (rsp_valid && rsp_ready) begin
        pending <= 1'b0;
      end
    end
  end

  assign rsp_valid = pending;
  assign rsp_rdata = rdata_reg;
  assign rsp_err   = 1'b0; // ROM never errors

endmodule
