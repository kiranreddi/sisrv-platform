// sisAxiLiteM.sv — AXI4-Lite Master Bridge
// Converts internal corebus requests to AXI4-Lite transactions.
// Single outstanding read + single outstanding write.
// Strict state machine for proper handshake compliance.

module sisAxiLiteM (
    input  logic clk,
    input  logic rst_n,

    // corebus side (slave)
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

  // FSM states
  typedef enum logic [2:0] {
    S_IDLE    = 3'd0,
    S_RD_ADDR = 3'd1,  // AR channel handshake
    S_RD_DATA = 3'd2,  // R channel handshake
    S_WR_ADDR = 3'd3,  // AW + W channel handshake
    S_WR_RESP = 3'd4,  // B channel handshake
    S_RSP     = 3'd5   // Return response to corebus
  } state_t;

  state_t state;

  // Latched request
  logic [31:0] addr_reg;
  logic [31:0] wdata_reg;
  logic [3:0]  wstrb_reg;
  logic        we_reg;

  // Latched response
  logic [31:0] rdata_reg;
  logic        err_reg;

  // Track AW and W completion independently (both must complete for write)
  logic aw_done, w_done;

  // Default outputs
  assign awprot = 3'b000;
  assign arprot = 3'b000;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= S_IDLE;
      addr_reg  <= 32'h0;
      wdata_reg <= 32'h0;
      wstrb_reg <= 4'h0;
      we_reg    <= 1'b0;
      rdata_reg <= 32'h0;
      err_reg   <= 1'b0;
      aw_done   <= 1'b0;
      w_done    <= 1'b0;
    end else begin
      case (state)
        S_IDLE: begin
          if (req_valid && req_ready) begin
            addr_reg  <= req_addr;
            wdata_reg <= req_wdata;
            wstrb_reg <= req_wstrb;
            we_reg    <= req_we;
            if (req_we) begin
              state   <= S_WR_ADDR;
              aw_done <= 1'b0;
              w_done  <= 1'b0;
            end else begin
              state   <= S_RD_ADDR;
            end
          end
        end

        // --- Read path ---
        S_RD_ADDR: begin
          if (arvalid && arready) begin
            state <= S_RD_DATA;
          end
        end

        S_RD_DATA: begin
          if (rvalid && rready) begin
            rdata_reg <= rdata;
            err_reg   <= (rresp != 2'b00);
            state     <= S_RSP;
          end
        end

        // --- Write path ---
        S_WR_ADDR: begin
          if (awvalid && awready) aw_done <= 1'b1;
          if (wvalid && wready)   w_done  <= 1'b1;

          // Move to wait for B once both AW and W are complete
          if ((aw_done || (awvalid && awready)) &&
              (w_done  || (wvalid && wready))) begin
            state <= S_WR_RESP;
          end
        end

        S_WR_RESP: begin
          if (bvalid && bready) begin
            err_reg   <= (bresp != 2'b00);
            rdata_reg <= 32'h0;
            state     <= S_RSP;
          end
        end

        // --- Response to corebus ---
        S_RSP: begin
          if (rsp_valid && rsp_ready) begin
            state <= S_IDLE;
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end

  // Combinational output drive
  assign req_ready = (state == S_IDLE);

  // AXI read address channel
  assign arvalid = (state == S_RD_ADDR);
  assign araddr  = addr_reg;

  // AXI read data channel
  assign rready  = (state == S_RD_DATA);

  // AXI write address channel
  assign awvalid = (state == S_WR_ADDR) && !aw_done;
  assign awaddr  = addr_reg;

  // AXI write data channel
  assign wvalid  = (state == S_WR_ADDR) && !w_done;
  assign wdata   = wdata_reg;
  assign wstrb   = wstrb_reg;

  // AXI write response channel
  assign bready  = (state == S_WR_RESP);

  // Corebus response
  assign rsp_valid = (state == S_RSP);
  assign rsp_rdata = rdata_reg;
  assign rsp_err   = err_reg;

endmodule
