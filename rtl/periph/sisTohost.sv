// sisTohost.sv — PASS/FAIL MMIO device
// Corebus-compatible slave. Write 1 = PASS, 0 = FAIL.

module sisTohost #(
    parameter logic [31:0] BASE_ADDR = 32'h1000_0000
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

    // Status outputs
    output logic        pass,
    output logic        fail,
    output logic [31:0] last_code
);

  logic pending;

  assign req_ready = !pending || rsp_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pass      <= 1'b0;
      fail      <= 1'b0;
      last_code <= 32'h0;
      pending   <= 1'b0;
    end else begin
      if (req_valid && req_ready) begin
        pending <= 1'b1;
        if (req_we && (req_addr == BASE_ADDR)) begin
          last_code <= req_wdata;
          if (req_wdata == 32'h0000_0001) pass <= 1'b1;
          if (req_wdata == 32'h0000_0000) fail <= 1'b1;
        end
      end else if (rsp_valid && rsp_ready) begin
        pending <= 1'b0;
      end
    end
  end

  assign rsp_valid = pending;
  assign rsp_rdata = last_code;
  assign rsp_err   = 1'b0;

endmodule
