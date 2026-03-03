module sisTohost #(
    parameter logic [31:0] BASE_ADDR = 32'h1000_0000
)(
    input  logic        clk,
    input  logic        rst_n,

    // simple MMIO (corebus-like) for early milestones
    input  logic        mmio_we,
    input  logic [31:0] mmio_addr,
    input  logic [31:0] mmio_wdata,
    output logic [31:0] mmio_rdata,

    output logic        pass,
    output logic        fail,
    output logic [31:0] last_code
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pass      <= 1'b0;
      fail      <= 1'b0;
      last_code <= 32'h0;
    end else begin
      if (mmio_we && (mmio_addr == BASE_ADDR)) begin
        last_code <= mmio_wdata;
        if (mmio_wdata == 32'h0000_0001) pass <= 1'b1;
        if (mmio_wdata == 32'h0000_0000) fail <= 1'b1;
      end
    end
  end

  assign mmio_rdata = last_code;
endmodule
