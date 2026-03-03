// sisTimer.sv — Machine Timer Peripheral
// Implements MTIME (64-bit free-running counter) and MTIMECMP (64-bit compare).
// Generates MTIP (machine timer interrupt pending) when MTIME >= MTIMECMP.
//
// MMIO registers (relative to base address):
//   +0x00: MTIME_LO     (RW) — lower 32 bits of MTIME
//   +0x04: MTIME_HI     (RW) — upper 32 bits of MTIME
//   +0x08: MTIMECMP_LO  (RW) — lower 32 bits of MTIMECMP
//   +0x0C: MTIMECMP_HI  (RW) — upper 32 bits of MTIMECMP
//
// The timer increments MTIME every clock cycle after reset.
// MTIP output is combinationally set when MTIME >= MTIMECMP.

module sisTimer #(
    parameter logic [31:0] BASE_ADDR = 32'h1000_2000
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

    // Interrupt output
    output logic        mtip      // Machine timer interrupt pending
);

  // Timer registers
  logic [63:0] mtime;
  logic [63:0] mtimecmp;

  // Response tracking
  logic        pending;
  logic [31:0] rdata_reg;

  // Register offsets
  localparam logic [3:0] OFF_MTIME_LO    = 4'h0;
  localparam logic [3:0] OFF_MTIME_HI    = 4'h4;
  localparam logic [3:0] OFF_MTIMECMP_LO = 4'h8;
  localparam logic [3:0] OFF_MTIMECMP_HI = 4'hC;

  // Address decode
  wire [3:0] reg_offset = req_addr[3:0];
  wire addr_match = (req_addr[31:4] == BASE_ADDR[31:4]);

  assign req_ready = !pending || rsp_ready;

  // MTIME increments every cycle; writes/reads handled synchronously
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mtime    <= 64'h0;
      mtimecmp <= 64'hFFFF_FFFF_FFFF_FFFF; // Max value: no interrupt initially
      pending  <= 1'b0;
      rdata_reg <= 32'h0;
    end else begin
      // Free-running counter (always increments)
      mtime <= mtime + 64'd1;

      if (req_valid && req_ready) begin
        pending <= 1'b1;

        if (addr_match && req_we) begin
          // Write
          case (reg_offset)
            OFF_MTIME_LO: begin
              if (req_wstrb[0]) mtime[7:0]   <= req_wdata[7:0];
              if (req_wstrb[1]) mtime[15:8]  <= req_wdata[15:8];
              if (req_wstrb[2]) mtime[23:16] <= req_wdata[23:16];
              if (req_wstrb[3]) mtime[31:24] <= req_wdata[31:24];
            end
            OFF_MTIME_HI: begin
              if (req_wstrb[0]) mtime[39:32] <= req_wdata[7:0];
              if (req_wstrb[1]) mtime[47:40] <= req_wdata[15:8];
              if (req_wstrb[2]) mtime[55:48] <= req_wdata[23:16];
              if (req_wstrb[3]) mtime[63:56] <= req_wdata[31:24];
            end
            OFF_MTIMECMP_LO: begin
              if (req_wstrb[0]) mtimecmp[7:0]   <= req_wdata[7:0];
              if (req_wstrb[1]) mtimecmp[15:8]  <= req_wdata[15:8];
              if (req_wstrb[2]) mtimecmp[23:16] <= req_wdata[23:16];
              if (req_wstrb[3]) mtimecmp[31:24] <= req_wdata[31:24];
            end
            OFF_MTIMECMP_HI: begin
              if (req_wstrb[0]) mtimecmp[39:32] <= req_wdata[7:0];
              if (req_wstrb[1]) mtimecmp[47:40] <= req_wdata[15:8];
              if (req_wstrb[2]) mtimecmp[55:48] <= req_wdata[23:16];
              if (req_wstrb[3]) mtimecmp[63:56] <= req_wdata[31:24];
            end
            default: ;
          endcase
        end

        // Read (combinational output for this cycle, latched)
        if (addr_match && !req_we) begin
          case (reg_offset)
            OFF_MTIME_LO:    rdata_reg <= mtime[31:0];
            OFF_MTIME_HI:    rdata_reg <= mtime[63:32];
            OFF_MTIMECMP_LO: rdata_reg <= mtimecmp[31:0];
            OFF_MTIMECMP_HI: rdata_reg <= mtimecmp[63:32];
            default:         rdata_reg <= 32'h0;
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

  // Interrupt: MTIME >= MTIMECMP
  assign mtip = (mtime >= mtimecmp);

endmodule
