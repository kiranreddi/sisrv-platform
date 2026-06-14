// sisPlic.sv — Platform-Level Interrupt Controller (PLIC subset)

module sisPlic #(
    parameter logic [31:0] BASE_ADDR   = 32'h0C00_0000,
    parameter int          NUM_SOURCES = 8
)(
    input  logic        clk,
    input  logic        rst_n,

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

    input  logic [NUM_SOURCES:1] irq_src,
    output logic        meip
);

  localparam logic [31:0] OFF_PRIORITY = 32'h0000_0004;
  localparam logic [31:0] OFF_PENDING  = 32'h0000_1000;
  localparam logic [31:0] OFF_ENABLE   = 32'h0000_2000;
  localparam logic [31:0] OFF_THRESHOLD = 32'h0020_0000;
  localparam logic [31:0] OFF_CLAIM    = 32'h0020_0004;

  logic [7:0] irq_prio [1:NUM_SOURCES];
  logic [NUM_SOURCES:1] gateway_pending;
  logic [NUM_SOURCES:1] enabled;
  logic [7:0] threshold;
  logic [3:0] claimed_id;
  logic       claim_active;

  logic       pending;
  logic [31:0] rdata_reg;

  wire addr_match = (req_addr[31:16] == BASE_ADDR[31:16]);
  wire [31:0] rel = req_addr - BASE_ADDR;

  assign req_ready = !pending || rsp_ready;
  assign rsp_valid = pending;
  assign rsp_rdata = rdata_reg;
  assign rsp_err   = 1'b0;

  // Gateway: latch pending while source is high; clear on claim complete
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gateway_pending <= '0;
    end else begin
      for (int i = 1; i <= NUM_SOURCES; i++) begin
        if (irq_src[i])
          gateway_pending[i] <= 1'b1;
        else if (claim_active && (claimed_id == i[3:0]) && req_valid && req_ready &&
                 addr_match && req_we && (rel == OFF_CLAIM) && (req_wdata[3:0] == claimed_id))
          gateway_pending[i] <= 1'b0;
      end
    end
  end

  logic [3:0] winner_id;
  logic [7:0] winner_pri;
  logic       irq_active;

  always_comb begin
    winner_id  = 4'd0;
    winner_pri = 8'd0;
    for (int i = NUM_SOURCES; i >= 1; i--) begin
      if (enabled[i] && gateway_pending[i] && (irq_prio[i] > winner_pri) &&
          (irq_prio[i] > threshold)) begin
        winner_pri = irq_prio[i];
        winner_id  = i[3:0];
      end
    end
    irq_active = (winner_id != 4'd0);
  end

  assign meip = irq_active && !claim_active;

  function automatic int source_idx(input logic [31:0] offset);
    source_idx = int'(offset[31:2]);
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 1; i <= NUM_SOURCES; i++)
        irq_prio[i] <= 8'd1;
      enabled      <= '0;
      threshold    <= 8'd0;
      claimed_id   <= 4'd0;
      claim_active <= 1'b0;
      pending      <= 1'b0;
      rdata_reg    <= 32'h0;
    end else begin
      if (req_valid && req_ready) begin
        pending <= 1'b1;

        if (addr_match && req_we) begin
          unique case (rel)
            OFF_ENABLE: begin
              for (int i = 1; i <= NUM_SOURCES; i++)
                enabled[i] <= req_wdata[i];
            end
            OFF_THRESHOLD: begin
              if (req_wstrb[0])
                threshold <= req_wdata[7:0];
            end
            OFF_CLAIM: begin
              if (claim_active && (req_wdata[3:0] == claimed_id))
                claim_active <= 1'b0;
            end
            default: begin
              if (rel[1:0] == 2'b00 && rel >= OFF_PRIORITY && rel < OFF_PENDING) begin
                int idx;
                idx = source_idx(rel);
                if (idx >= 1 && idx <= NUM_SOURCES && req_wstrb[0])
                  irq_prio[idx] <= req_wdata[7:0];
              end
            end
          endcase
        end else if (addr_match && !req_we) begin
          unique case (rel)
            OFF_PENDING:  rdata_reg <= {{(32-NUM_SOURCES){1'b0}}, gateway_pending};
            OFF_ENABLE:   rdata_reg <= {{(32-NUM_SOURCES){1'b0}}, enabled};
            OFF_THRESHOLD: rdata_reg <= {24'b0, threshold};
            OFF_CLAIM: begin
              if (!claim_active && irq_active) begin
                rdata_reg    <= {28'b0, winner_id};
                claimed_id   <= winner_id;
                claim_active <= 1'b1;
              end else begin
                rdata_reg <= {28'b0, claimed_id};
              end
            end
            default: begin
              if (rel[1:0] == 2'b00 && rel >= OFF_PRIORITY && rel < OFF_PENDING) begin
                int idx;
                idx = source_idx(rel);
                if (idx >= 1 && idx <= NUM_SOURCES)
                  rdata_reg <= {24'b0, irq_prio[idx]};
                else
                  rdata_reg <= 32'h0;
              end else begin
                rdata_reg <= 32'h0;
              end
            end
          endcase
        end else begin
          rdata_reg <= 32'h0;
        end
      end else if (rsp_valid && rsp_ready) begin
        pending <= 1'b0;
      end
    end
  end

endmodule
