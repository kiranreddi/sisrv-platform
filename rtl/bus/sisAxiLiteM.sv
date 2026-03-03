module sisAxiLiteM (
    input  logic clk,
    input  logic rst_n,

    // corebus side
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

    // AXI4-Lite master side
    output logic        awvalid,
    input  logic        awready,
    output logic [31:0] awaddr,
    output logic [2:0]  awprot,

    output logic        wvalid,
    input  logic        wready,
    output logic [31:0] wdata,
    output logic [3:0]  wstrb,

    input  logic        bvalid,
    output logic        bready,
    input  logic [1:0]  bresp,

    output logic        arvalid,
    input  logic        arready,
    output logic [31:0] araddr,
    output logic [2:0]  arprot,

    input  logic        rvalid,
    output logic        rready,
    input  logic [31:0] rdata,
    input  logic [1:0]  rresp
);
  // TODO (Milestone 3): implement AXI4-Lite single-outstanding bridge.
  assign req_ready = 1'b0;
  assign rsp_valid = 1'b0;
  assign rsp_rdata = 32'h0;
  assign rsp_err   = 1'b0;

  assign awvalid = 1'b0;
  assign awaddr  = 32'h0;
  assign awprot  = 3'b000;

  assign wvalid  = 1'b0;
  assign wdata   = 32'h0;
  assign wstrb   = 4'h0;

  assign bready  = 1'b0;

  assign arvalid = 1'b0;
  assign araddr  = 32'h0;
  assign arprot  = 3'b000;

  assign rready  = 1'b0;
endmodule
