// sisMemFabric.sv — Address decoder / bus router
// Routes corebus requests to ROM, RAM, CLINT, PLIC, or platform MMIO.
//
// Address map:
//   ROM:   0x0000_0000 - 0x001F_FFFF (2 MB; matches ACT link.ld and sisRom depth)
//   CLINT: 0x0200_0000 - 0x0200_FFFF
//   MMIO:  0x1000_0000 - 0x1000_FFFF (tohost, GPIO, UART)
//   PLIC:  0x0C00_0000 - 0x0C00_FFFF
//   RAM:   0x8000_0000 - 0x8003_FFFF

module sisMemFabric (
    input  logic        clk,
    input  logic        rst_n,

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

    // Slave 2: MMIO
    output logic        s2_req_valid,
    input  logic        s2_req_ready,
    output logic [31:0] s2_req_addr,
    output logic        s2_req_we,
    output logic [31:0] s2_req_wdata,
    output logic [3:0]  s2_req_wstrb,
    input  logic        s2_rsp_valid,
    output logic        s2_rsp_ready,
    input  logic [31:0] s2_rsp_rdata,
    input  logic        s2_rsp_err,

    // Slave 3: CLINT
    output logic        s3_req_valid,
    input  logic        s3_req_ready,
    output logic [31:0] s3_req_addr,
    output logic        s3_req_we,
    output logic [31:0] s3_req_wdata,
    output logic [3:0]  s3_req_wstrb,
    input  logic        s3_rsp_valid,
    output logic        s3_rsp_ready,
    input  logic [31:0] s3_rsp_rdata,
    input  logic        s3_rsp_err,

    // Slave 4: PLIC
    output logic        s4_req_valid,
    input  logic        s4_req_ready,
    output logic [31:0] s4_req_addr,
    output logic        s4_req_we,
    output logic [31:0] s4_req_wdata,
    output logic [3:0]  s4_req_wstrb,
    input  logic        s4_rsp_valid,
    output logic        s4_rsp_ready,
    input  logic [31:0] s4_rsp_rdata,
    input  logic        s4_rsp_err
);

  logic sel_rom, sel_ram, sel_mmio, sel_clint, sel_plic;
  assign sel_rom   = ~|m_req_addr[31:21];
  assign sel_clint = (m_req_addr[31:16] == 16'h0200);
  assign sel_mmio  = (m_req_addr[31:16] == 16'h1000);
  assign sel_plic  = (m_req_addr[31:16] == 16'h0C00);
  assign sel_ram   = (m_req_addr[31:18] == 14'b10_0000_0000_0000);

  logic [2:0] active_slave;
  logic       has_pending;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active_slave <= 3'd0;
      has_pending  <= 1'b0;
    end else begin
      if (m_req_valid && m_req_ready && !has_pending) begin
        has_pending <= 1'b1;
        if (sel_rom)       active_slave <= 3'd0;
        else if (sel_ram)  active_slave <= 3'd1;
        else if (sel_mmio) active_slave <= 3'd2;
        else if (sel_clint) active_slave <= 3'd3;
        else if (sel_plic) active_slave <= 3'd4;
        else               active_slave <= 3'd5;
      end else if (m_rsp_valid && m_rsp_ready) begin
        has_pending <= 1'b0;
      end
    end
  end

  assign s0_req_addr = m_req_addr; assign s0_req_we = m_req_we;
  assign s0_req_wdata = m_req_wdata; assign s0_req_wstrb = m_req_wstrb;
  assign s1_req_addr = m_req_addr; assign s1_req_we = m_req_we;
  assign s1_req_wdata = m_req_wdata; assign s1_req_wstrb = m_req_wstrb;
  assign s2_req_addr = m_req_addr; assign s2_req_we = m_req_we;
  assign s2_req_wdata = m_req_wdata; assign s2_req_wstrb = m_req_wstrb;
  assign s3_req_addr = m_req_addr; assign s3_req_we = m_req_we;
  assign s3_req_wdata = m_req_wdata; assign s3_req_wstrb = m_req_wstrb;
  assign s4_req_addr = m_req_addr; assign s4_req_we = m_req_we;
  assign s4_req_wdata = m_req_wdata; assign s4_req_wstrb = m_req_wstrb;

  assign s0_req_valid = m_req_valid && sel_rom;
  assign s1_req_valid = m_req_valid && sel_ram;
  assign s2_req_valid = m_req_valid && sel_mmio;
  assign s3_req_valid = m_req_valid && sel_clint;
  assign s4_req_valid = m_req_valid && sel_plic;

  always_comb begin
    if (sel_rom)       m_req_ready = s0_req_ready;
    else if (sel_ram)  m_req_ready = s1_req_ready;
    else if (sel_mmio) m_req_ready = s2_req_ready;
    else if (sel_clint) m_req_ready = s3_req_ready;
    else if (sel_plic) m_req_ready = s4_req_ready;
    else               m_req_ready = 1'b1;
  end

  always_comb begin
    unique case (active_slave)
      3'd0: begin m_rsp_valid = s0_rsp_valid; m_rsp_rdata = s0_rsp_rdata; m_rsp_err = s0_rsp_err; end
      3'd1: begin m_rsp_valid = s1_rsp_valid; m_rsp_rdata = s1_rsp_rdata; m_rsp_err = s1_rsp_err; end
      3'd2: begin m_rsp_valid = s2_rsp_valid; m_rsp_rdata = s2_rsp_rdata; m_rsp_err = s2_rsp_err; end
      3'd3: begin m_rsp_valid = s3_rsp_valid; m_rsp_rdata = s3_rsp_rdata; m_rsp_err = s3_rsp_err; end
      3'd4: begin m_rsp_valid = s4_rsp_valid; m_rsp_rdata = s4_rsp_rdata; m_rsp_err = s4_rsp_err; end
      default: begin m_rsp_valid = has_pending; m_rsp_rdata = 32'hDEAD_BEEF; m_rsp_err = 1'b1; end
    endcase
  end

  assign s0_rsp_ready = m_rsp_ready && (active_slave == 3'd0);
  assign s1_rsp_ready = m_rsp_ready && (active_slave == 3'd1);
  assign s2_rsp_ready = m_rsp_ready && (active_slave == 3'd2);
  assign s3_rsp_ready = m_rsp_ready && (active_slave == 3'd3);
  assign s4_rsp_ready = m_rsp_ready && (active_slave == 3'd4);

endmodule
