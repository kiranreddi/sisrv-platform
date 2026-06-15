// sisDm.sv — RISC-V Debug Module (subset, spec 0.13)
// Supports halt/resume, single-step, and abstract GPR access via DMI.

module sisDm #(
    parameter int XLEN = 32
)(
    input  logic        clk,
    input  logic        rst_n,

    // DMI port (from JTAG DTM or simulation backdoor)
    input  logic        dmi_req_valid,
    output logic        dmi_req_ready,
    input  logic        dmi_req_write,
    input  logic [6:0]  dmi_req_addr,
    input  logic [31:0] dmi_req_wdata,
    output logic        dmi_rsp_valid,
    input  logic        dmi_rsp_ready,
    output logic [31:0] dmi_rsp_rdata,

    // Core control
    output logic        halt_req,
    output logic        resume_req,
    output logic        single_step,
    input  logic        core_halted,
    input  logic        core_running,

    // Abstract register access (GPR read/write while halted)
    output logic        abs_valid,
    input  logic        abs_ready,
    output logic        abs_write,
    output logic [4:0]  abs_regaddr,
    output logic [31:0] abs_wdata,
    input  logic [31:0] abs_rdata
);

  // DMI register addresses (byte addresses / 4)
  localparam logic [6:0] DMI_DMCONTROL  = 7'h10;
  localparam logic [6:0] DMI_DMSTATUS   = 7'h11;
  localparam logic [6:0] DMI_ABSTRACTCS = 7'h16;
  localparam logic [6:0] DMI_COMMAND   = 7'h17;
  localparam logic [6:0] DMI_DATA0      = 7'h04;

  logic        dm_active;
  logic        haltreq_r;
  logic        resumereq_r;
  logic        step_r;
  logic [31:0] data0;
  logic [2:0]  abs_state; // 0=idle, 1=busy, 2=done
  logic        abs_cmd_write;
  logic [4:0]  abs_cmd_reg;

  logic        dmi_pending;
  logic [31:0] dmi_rdata_reg;

  assign dmi_req_ready = !dmi_pending || dmi_rsp_ready;
  assign halt_req      = haltreq_r && dm_active;
  assign resume_req    = resumereq_r && dm_active;
  assign single_step   = step_r && dm_active && core_halted;

  assign abs_valid   = (abs_state == 3'd1);
  assign abs_write   = abs_cmd_write;
  assign abs_regaddr = abs_cmd_reg;
  assign abs_wdata   = data0;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dm_active    <= 1'b0;
      haltreq_r    <= 1'b0;
      resumereq_r  <= 1'b0;
      step_r       <= 1'b0;
      data0        <= 32'h0;
      abs_state    <= 3'd0;
      abs_cmd_write <= 1'b0;
      abs_cmd_reg  <= 5'd0;
      dmi_pending  <= 1'b0;
      dmi_rdata_reg <= 32'h0;
    end else begin
      if (abs_state == 3'd1 && abs_ready) begin
        if (abs_cmd_write)
          abs_state <= 3'd2;
        else begin
          data0     <= abs_rdata;
          abs_state <= 3'd2;
        end
      end else if (abs_state == 3'd2) begin
        abs_state <= 3'd0;
      end

      if (dmi_req_valid && dmi_req_ready) begin
        dmi_pending <= 1'b1;
        dmi_rdata_reg <= 32'h0;

        if (dmi_req_write) begin
          unique case (dmi_req_addr)
            DMI_DMCONTROL: begin
              dm_active   <= dmi_req_wdata[0];
              step_r      <= dmi_req_wdata[2];
              haltreq_r   <= dmi_req_wdata[31];
              resumereq_r <= dmi_req_wdata[30];
            end
            DMI_COMMAND: begin
              // cmdtype=0 (access register), regno[15:0] with bit0=1 for GPR
              if (dmi_req_wdata[31:24] == 8'h0) begin
                abs_cmd_write <= dmi_req_wdata[16]; // write bit
                abs_cmd_reg   <= dmi_req_wdata[20:16];
                abs_state     <= 3'd1;
              end
            end
            DMI_DATA0: data0 <= dmi_req_wdata;
            default: ;
          endcase
        end else begin
          unique case (dmi_req_addr)
            DMI_DMCONTROL:  dmi_rdata_reg <= {haltreq_r, resumereq_r, 27'b0, step_r, 1'b0, dm_active};
            DMI_DMSTATUS:   dmi_rdata_reg <= {core_halted, core_running, 30'b0};
            DMI_ABSTRACTCS: dmi_rdata_reg <= {30'b0, abs_state[1:0]};
            DMI_DATA0:      dmi_rdata_reg <= data0;
            default:        dmi_rdata_reg <= 32'h0;
          endcase
        end
      end else if (dmi_rsp_valid && dmi_rsp_ready) begin
        dmi_pending <= 1'b0;
        haltreq_r   <= 1'b0;
        resumereq_r <= 1'b0;
      end
    end
  end

  assign dmi_rsp_valid = dmi_pending;
  assign dmi_rsp_rdata = dmi_rdata_reg;

endmodule
