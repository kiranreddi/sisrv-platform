module sisRvCore (
    input  logic        clk,
    input  logic        rst_n,

    // corebus request
    output logic        req_valid,
    input  logic        req_ready,
    output logic [31:0] req_addr,
    output logic        req_we,
    output logic [31:0] req_wdata,
    output logic [3:0]  req_wstrb,

    // corebus response
    input  logic        rsp_valid,
    output logic        rsp_ready,
    input  logic [31:0] rsp_rdata,
    input  logic        rsp_err
);
  // TODO (Milestone 1): implement multi-cycle RV32I FSM core.
  assign req_valid = 1'b0;
  assign req_addr  = 32'h0;
  assign req_we    = 1'b0;
  assign req_wdata = 32'h0;
  assign req_wstrb = 4'h0;
  assign rsp_ready = 1'b1;
endmodule
