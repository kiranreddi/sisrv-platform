// sisMemFabric.sv — Simple address decoder / bus router
// Routes corebus requests from CPU to ROM, RAM, or MMIO based on address.
// Single outstanding transaction (only one slave active at a time).
//
// Address map:
//   ROM:  0x0000_0000 - 0x0000_FFFF (64 KB)
//   MMIO: 0x1000_0000 - 0x1000_FFFF (64 KB)
//   RAM:  0x8000_0000 - 0x8003_FFFF (256 KB)

module sisMemFabric (
    input  logic        clk,
    input  logic        rst_n,

    // Master port (from CPU)
    input  logic        m_req_valid,
    output logic        m_req_ready,
    input  logic [31:0] m_req_addr,
    input  logic        m_req_we,
    input  logic [31:0] m_req_wdata,
    input  logic [3:0]  m_req_wstrb,

    output logic        m_rsp_valid,
    input  logic        m_rsp_ready,
    output logic [31:0] m_rsp_rdata,
    output logic        m_rsp_err,

    // Slave 0: ROM
    output logic        s0_req_valid,
    input  logic        s0_req_ready,
    output logic [31:0] s0_req_addr,
    output logic        s0_req_we,
    output logic [31:0] s0_req_wdata,
    output logic [3:0]  s0_req_wstrb,

    input  logic        s0_rsp_valid,
    output logic        s0_rsp_ready,
    input  logic [31:0] s0_rsp_rdata,
    input  logic        s0_rsp_err,

    // Slave 1: RAM
    output logic        s1_req_valid,
    input  logic        s1_req_ready,
    output logic [31:0] s1_req_addr,
    output logic        s1_req_we,
    output logic [31:0] s1_req_wdata,
    output logic [3:0]  s1_req_wstrb,

    input  logic        s1_rsp_valid,
    output logic        s1_rsp_ready,
    input  logic [31:0] s1_rsp_rdata,
    input  logic        s1_rsp_err,

    // Slave 2: MMIO (tohost)
    output logic        s2_req_valid,
    input  logic        s2_req_ready,
    output logic [31:0] s2_req_addr,
    output logic        s2_req_we,
    output logic [31:0] s2_req_wdata,
    output logic [3:0]  s2_req_wstrb,

    input  logic        s2_rsp_valid,
    output logic        s2_rsp_ready,
    input  logic [31:0] s2_rsp_rdata,
    input  logic        s2_rsp_err
);

  // Address decode
  logic sel_rom, sel_ram, sel_mmio;
  assign sel_rom  = (m_req_addr[31:16] == 16'h0000);  // 0x0000_xxxx
  assign sel_ram  = (m_req_addr[31:18] == 14'b10_0000_0000_0000); // 0x8000_0000 - 0x8003_FFFF
  assign sel_mmio = (m_req_addr[31:16] == 16'h1000);  // 0x1000_xxxx

  // Track which slave was selected (for routing response)
  logic [1:0] active_slave;
  logic       has_pending;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active_slave <= 2'd0;
      has_pending  <= 1'b0;
    end else begin
      if (m_req_valid && m_req_ready && !has_pending) begin
        has_pending <= 1'b1;
        if (sel_rom)       active_slave <= 2'd0;
        else if (sel_ram)  active_slave <= 2'd1;
        else if (sel_mmio) active_slave <= 2'd2;
        else               active_slave <= 2'd3; // unmapped
      end else if (m_rsp_valid && m_rsp_ready) begin
        has_pending <= 1'b0;
      end
    end
  end

  // Forward request to selected slave
  // Common signals
  assign s0_req_addr  = m_req_addr;
  assign s0_req_we    = m_req_we;
  assign s0_req_wdata = m_req_wdata;
  assign s0_req_wstrb = m_req_wstrb;

  assign s1_req_addr  = m_req_addr;
  assign s1_req_we    = m_req_we;
  assign s1_req_wdata = m_req_wdata;
  assign s1_req_wstrb = m_req_wstrb;

  assign s2_req_addr  = m_req_addr;
  assign s2_req_we    = m_req_we;
  assign s2_req_wdata = m_req_wdata;
  assign s2_req_wstrb = m_req_wstrb;

  // Valid signals
  assign s0_req_valid = m_req_valid && sel_rom;
  assign s1_req_valid = m_req_valid && sel_ram;
  assign s2_req_valid = m_req_valid && sel_mmio;

  // Ready back to master
  always_comb begin
    if (sel_rom)       m_req_ready = s0_req_ready;
    else if (sel_ram)  m_req_ready = s1_req_ready;
    else if (sel_mmio) m_req_ready = s2_req_ready;
    else               m_req_ready = 1'b1; // unmapped: accept and error
  end

  // Response mux (based on active slave)
  always_comb begin
    case (active_slave)
      2'd0: begin
        m_rsp_valid = s0_rsp_valid;
        m_rsp_rdata = s0_rsp_rdata;
        m_rsp_err   = s0_rsp_err;
      end
      2'd1: begin
        m_rsp_valid = s1_rsp_valid;
        m_rsp_rdata = s1_rsp_rdata;
        m_rsp_err   = s1_rsp_err;
      end
      2'd2: begin
        m_rsp_valid = s2_rsp_valid;
        m_rsp_rdata = s2_rsp_rdata;
        m_rsp_err   = s2_rsp_err;
      end
      default: begin
        m_rsp_valid = has_pending; // error response for unmapped
        m_rsp_rdata = 32'hDEAD_BEEF;
        m_rsp_err   = 1'b1;
      end
    endcase
  end

  // Response ready back to slaves
  assign s0_rsp_ready = m_rsp_ready && (active_slave == 2'd0);
  assign s1_rsp_ready = m_rsp_ready && (active_slave == 2'd1);
  assign s2_rsp_ready = m_rsp_ready && (active_slave == 2'd2);

endmodule
