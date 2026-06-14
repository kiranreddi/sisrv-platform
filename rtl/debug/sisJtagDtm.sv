// sisJtagDtm.sv — JTAG Debug Transport Module (subset)
// Implements a minimal 5-wire JTAG TAP with DMI access to the Debug Module.

module sisJtagDtm (
    input  logic        clk,
    input  logic        rst_n,

    // JTAG pins
    input  logic        tck,
    input  logic        tms,
    input  logic        tdi,
    output logic        tdo,

    // DMI to Debug Module
    output logic        dmi_req_valid,
    input  logic        dmi_req_ready,
    output logic        dmi_req_write,
    output logic [6:0]  dmi_req_addr,
    output logic [31:0] dmi_req_wdata,
    input  logic        dmi_rsp_valid,
    output logic        dmi_rsp_ready,
    input  logic [31:0] dmi_rsp_rdata
);

  // Synchronize TCK domain signals (simplified: sample on posedge clk when tck toggles)
  logic        tck_sync, tck_prev;
  logic        tms_sync, tdi_sync;
  logic [3:0]  tap_state;
  logic [4:0]  ir;
  logic [40:0] dr;
  logic [5:0]  bit_cnt;
  logic        shift_dr;
  logic        update_dr;
  logic        capture_dr;

  localparam logic [4:0] IR_BYPASS  = 5'h1F;
  localparam logic [4:0] IR_DTMCS   = 5'h10;
  localparam logic [4:0] IR_DMI     = 5'h11;

  // TAP states (simplified encoding)
  localparam logic [3:0] ST_IDLE     = 4'd0;
  localparam logic [3:0] ST_DR_SHIFT = 4'd1;
  localparam logic [3:0] ST_DR_EXIT = 4'd2;
  localparam logic [3:0] ST_IR_SHIFT = 4'd3;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tck_sync  <= 1'b0;
      tck_prev  <= 1'b0;
      tms_sync  <= 1'b0;
      tdi_sync  <= 1'b0;
    end else begin
      tck_prev <= tck_sync;
      tck_sync <= tck;
      tms_sync <= tms;
      tdi_sync <= tdi;
    end
  end

  wire tck_rise = tck_sync && !tck_prev;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tap_state <= ST_IDLE;
      ir        <= IR_BYPASS;
      dr        <= 32'h0;
      bit_cnt   <= 6'd0;
      shift_dr  <= 1'b0;
      update_dr <= 1'b0;
      capture_dr <= 1'b0;
    end else if (tck_rise) begin
      update_dr <= 1'b0;
      capture_dr <= 1'b0;
      shift_dr  <= 1'b0;

      unique case (tap_state)
        ST_IDLE: begin
          if (tms_sync)
            tap_state <= ST_IDLE;
          else
            tap_state <= ST_DR_SHIFT;
          bit_cnt <= 6'd0;
        end
        ST_DR_SHIFT: begin
          shift_dr <= 1'b1;
          dr <= {tdi_sync, dr[31:1]};
          bit_cnt <= bit_cnt + 6'd1;
          if (tms_sync)
            tap_state <= ST_DR_EXIT;
        end
        ST_DR_EXIT: begin
          update_dr <= 1'b1;
          tap_state <= ST_IDLE;
        end
        ST_IR_SHIFT: begin
          ir <= {tdi_sync, ir[4:1]};
          if (tms_sync)
            tap_state <= ST_IDLE;
        end
        default: tap_state <= ST_IDLE;
      endcase
    end
  end

  assign tdo = dr[0];

  // DMI request generation from DR update when IR=DMI
  logic        dmi_pending;
  logic [40:0] dmi_op; // {op[1:0], addr[6:0], data[31:0]}

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dmi_pending   <= 1'b0;
      dmi_op        <= 41'h0;
      dmi_req_valid <= 1'b0;
      dmi_req_write <= 1'b0;
      dmi_req_addr  <= 7'h0;
      dmi_req_wdata <= 32'h0;
    end else begin
      if (update_dr && ir == IR_DMI) begin
        dmi_op        <= {dr[40:34], dr[33:32], dr[31:0]};
        dmi_req_valid <= 1'b1;
        dmi_req_write <= (dr[33:32] == 2'b10);
        dmi_req_addr  <= dr[40:34];
        dmi_req_wdata <= dr[31:0];
      end else if (dmi_req_valid && dmi_req_ready) begin
        dmi_req_valid <= 1'b0;
        dmi_pending   <= 1'b1;
      end else if (dmi_rsp_valid && dmi_rsp_ready) begin
        dmi_pending <= 1'b0;
        dr          <= dmi_rsp_rdata;
      end
    end
  end

  assign dmi_rsp_ready = dmi_pending;

endmodule
