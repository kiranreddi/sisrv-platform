// sisAxiLiteSlave.sv — AXI4-Lite Slave Memory Model (Testbench only)
// Combined ROM/RAM/MMIO/timer slave with configurable random stall injection.
// Used to verify the AXI4-Lite bridge path end-to-end.
//
// Address map (same as corebus):
//   ROM:  0x0000_0000 - 0x0000_FFFF (64 KB)
//   MMIO: 0x1000_0000 - 0x1000_FFFF (64 KB)
//   Timer: 0x1000_2000 - 0x1000_200F (MTIME/MTIMECMP)
//   GPIO:  0x1000_3000 - 0x1000_3010 (DATA/DIR/IN/SET/CLR)
//   UART:  0x1000_4000 - 0x1000_4010 (TXDATA/RXDATA/STATUS/CTRL/BAUDDIV)
//   RAM:  0x8000_0000 - 0x8003_FFFF (256 KB)

module sisAxiLiteSlave #(
    parameter int ROM_DEPTH_WORDS = 524288,
    parameter int RAM_DEPTH_WORDS = 65536,
    parameter     ROM_INIT_FILE   = "",
    parameter int STALL_RATE      = 0     // 0-100: % chance of stalling each channel
)(
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite slave interface
    // Write address channel
    input  logic        awvalid,
    output logic        awready,
    input  logic [31:0] awaddr,
    input  logic [2:0]  awprot,

    // Write data channel
    input  logic        wvalid,
    output logic        wready,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,

    // Write response channel
    output logic        bvalid,
    input  logic        bready,
    output logic [1:0]  bresp,

    // Read address channel
    input  logic        arvalid,
    output logic        arready,
    input  logic [31:0] araddr,
    input  logic [2:0]  arprot,

    // Read data channel
    output logic        rvalid,
    input  logic        rready,
    output logic [31:0] rdata,
    output logic [1:0]  rresp,

    // Status outputs (tohost)
    output logic        pass,
    output logic        fail,
    output logic [31:0] last_code,
    output logic        mtip,
    output logic        msip,
    output logic        meip,
    input  logic [7:0]  plic_irq,
    input  logic [31:0] gpio_in,
    output logic [31:0] gpio_out,
    output logic [31:0] gpio_oe,
    output logic        uart_tx_valid,
    output logic [7:0]  uart_tx_data
);

  // ---------------------------------------------------------------
  // Memory arrays
  // ---------------------------------------------------------------
  localparam ROM_AW = $clog2(ROM_DEPTH_WORDS);
  localparam RAM_AW = $clog2(RAM_DEPTH_WORDS);
  // Clamp invalid stall percentages so READY/VALID behavior remains bounded.
  localparam int STALL_RATE_MIN = (STALL_RATE < 0) ? 0 : STALL_RATE;
  localparam int STALL_RATE_CLAMPED = (STALL_RATE_MIN > 100) ? 100 : STALL_RATE_MIN;

  logic [31:0] rom [0:ROM_DEPTH_WORDS-1];
  logic [31:0] ram [0:RAM_DEPTH_WORDS-1];

`ifndef SYNTHESIS
  export "DPI-C" function dpi_sisrv_ram_read_word;
  function int unsigned dpi_sisrv_ram_read_word(input int unsigned word_idx);
    if (word_idx < RAM_DEPTH_WORDS)
      return ram[word_idx];
    else
      return 0;
  endfunction
`endif

  logic        msip_reg;
  logic [63:0] mtime;
  logic [63:0] mtimecmp;
  logic [63:0] mtime_next;
  logic [31:0] uart_ctrl;
  logic [31:0] uart_bauddiv;
  logic [7:0]  uart_last_tx;
  logic [7:0]  uart_rx_data;
  logic        uart_rx_valid;

  typedef enum logic [2:0] {
    WR_IDLE,
    WR_GOT_AW,
    WR_GOT_W,
    WR_EXEC,
    WR_WAIT,
    WR_RESP
  } wr_state_t;
  wr_state_t wr_state;
  logic [31:0] wr_addr_reg;
  logic [31:0] wr_data_reg;
  logic [3:0]  wr_strb_reg;
  logic [1:0]  wr_resp_reg;
  logic [3:0]  wr_stall_cnt;

  // PLIC subset (inline; matches rtl/periph/sisPlic.sv register layout)
  localparam logic [31:0] PLIC_OFF_PRIORITY  = 32'h0000_0004;
  localparam logic [31:0] PLIC_OFF_PENDING   = 32'h0000_1000;
  localparam logic [31:0] PLIC_OFF_ENABLE    = 32'h0000_2000;
  localparam logic [31:0] PLIC_OFF_THRESHOLD = 32'h0020_0000;
  localparam logic [31:0] PLIC_OFF_CLAIM     = 32'h0020_0004;

  logic [7:0]  plic_prio [1:8];
  logic [8:1]  plic_pending;
  logic [8:1]  plic_enabled;
  logic [7:0]  plic_threshold;
  logic [3:0]  plic_claim_id;
  logic        plic_claim_active;
  logic [3:0]  plic_winner_id;
  logic [7:0]  plic_winner_pri;
  logic        plic_irq_active;
  logic        plic_meip;

  function automatic int plic_source_idx(input logic [31:0] offset);
    plic_source_idx = int'(offset[31:2]);
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      plic_pending      <= '0;
      plic_claim_active <= 1'b0;
      plic_claim_id     <= 4'd0;
    end else begin
      for (int i = 1; i <= 8; i++) begin
        if (plic_irq[i] | gpio_out[i])
          plic_pending[i] <= 1'b1;
        else if (plic_claim_active && (plic_claim_id == i[3:0]) && wr_state == WR_EXEC &&
                 is_plic(wr_addr_reg) && (wr_addr_reg - 32'h0C00_0000 == PLIC_OFF_CLAIM) &&
                 (wr_data_reg[3:0] == plic_claim_id))
          plic_pending[i] <= 1'b0;
      end
    end
  end

  always_comb begin
    plic_winner_id  = 4'd0;
    plic_winner_pri = 8'd0;
    for (int i = 8; i >= 1; i--) begin
      if (plic_enabled[i] && plic_pending[i] && (plic_prio[i] > plic_winner_pri) &&
          (plic_prio[i] > plic_threshold)) begin
        plic_winner_pri = plic_prio[i];
        plic_winner_id  = i[3:0];
      end
    end
    plic_irq_active = (plic_winner_id != 4'd0);
    plic_meip       = plic_irq_active && !plic_claim_active;
  end

  function automatic logic [31:0] plic_read(input [31:0] addr);
    logic [31:0] rel;
    int idx;
    begin
      rel = addr - 32'h0C00_0000;
      unique case (rel)
        PLIC_OFF_PENDING:  return {{24{1'b0}}, plic_pending[8:1]};
        PLIC_OFF_ENABLE:   return {{24{1'b0}}, plic_enabled[8:1]};
        PLIC_OFF_THRESHOLD: return {24'b0, plic_threshold};
        PLIC_OFF_CLAIM: begin
          if (!plic_claim_active && plic_irq_active)
            return {28'b0, plic_winner_id};
          return {28'b0, plic_claim_id};
        end
        default: begin
          if (rel[1:0] == 2'b00 && rel >= PLIC_OFF_PRIORITY && rel < PLIC_OFF_PENDING) begin
            idx = plic_source_idx(rel);
            if (idx >= 1 && idx <= 8)
              return {24'b0, plic_prio[idx]};
          end
          return 32'h0;
        end
      endcase
    end
  endfunction

  // Initialize memories
  initial begin
    for (int i = 0; i < ROM_DEPTH_WORDS; i++) rom[i] = 32'h0000_0013; // NOP
    for (int i = 0; i < RAM_DEPTH_WORDS; i++) ram[i] = 32'h0;
    if (ROM_INIT_FILE != "") $readmemh(ROM_INIT_FILE, rom);
  end

  // ---------------------------------------------------------------
  // Independent per-channel LFSRs for truly independent stall injection
  // Each AXI channel (AR, R, AW, W, B) gets its own LFSR with a
  // different seed so stalls are uncorrelated across channels.
  // ---------------------------------------------------------------
  logic [15:0] lfsr_ar, lfsr_r, lfsr_aw, lfsr_w, lfsr_b;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lfsr_ar <= 16'hACE1;
      lfsr_r  <= 16'hBEEF;
      lfsr_aw <= 16'hCAFE;
      lfsr_w  <= 16'hDEAD;
      lfsr_b  <= 16'hF00D;
    end else begin
      lfsr_ar <= {lfsr_ar[14:0], lfsr_ar[15] ^ lfsr_ar[13] ^ lfsr_ar[12] ^ lfsr_ar[10]};
      lfsr_r  <= {lfsr_r[14:0],  lfsr_r[15]  ^ lfsr_r[13]  ^ lfsr_r[12]  ^ lfsr_r[10]};
      lfsr_aw <= {lfsr_aw[14:0], lfsr_aw[15] ^ lfsr_aw[13] ^ lfsr_aw[12] ^ lfsr_aw[10]};
      lfsr_w  <= {lfsr_w[14:0],  lfsr_w[15]  ^ lfsr_w[13]  ^ lfsr_w[12]  ^ lfsr_w[10]};
      lfsr_b  <= {lfsr_b[14:0],  lfsr_b[15]  ^ lfsr_b[13]  ^ lfsr_b[12]  ^ lfsr_b[10]};
    end
  end

  function automatic logic should_stall;
    input [15:0] lfsr_val;
    logic [7:0] sample;
    logic [7:0] threshold;
    begin
      sample = {1'b0, lfsr_val[6:0]};
      threshold = STALL_RATE_CLAMPED[7:0];
      return (sample < threshold);
    end
  endfunction

  // ---------------------------------------------------------------
  // Address decode
  // ---------------------------------------------------------------
  function automatic logic is_rom(input [31:0] addr);
    return (addr[31:16] == 16'h0000);
  endfunction

  function automatic logic is_ram(input [31:0] addr);
    return (addr[31:18] == 14'b10_0000_0000_0000);
  endfunction

  function automatic logic is_mmio(input [31:0] addr);
    return (addr[31:16] == 16'h1000);
  endfunction

  function automatic logic is_clint(input [31:0] addr);
    return (addr[31:16] == 16'h0200);
  endfunction

  function automatic logic is_plic(input [31:0] addr);
    return (addr[31:16] == 16'h0C00);
  endfunction

  function automatic logic is_timer(input [31:0] addr);
    return is_clint(addr);
  endfunction

  function automatic logic is_gpio(input [31:0] addr);
    return (addr[31:5] == 27'h0800180);
  endfunction

  function automatic logic is_uart(input [31:0] addr);
    return (addr[31:5] == 27'h0800200);
  endfunction

  function automatic logic [31:0] apply_wstrb(
    input logic [31:0] old_data,
    input logic [31:0] new_data,
    input logic [3:0]  strb
  );
    logic [31:0] merged;
    begin
      merged = old_data;
      if (strb[0]) merged[7:0]   = new_data[7:0];
      if (strb[1]) merged[15:8]  = new_data[15:8];
      if (strb[2]) merged[23:16] = new_data[23:16];
      if (strb[3]) merged[31:24] = new_data[31:24];
      return merged;
    end
  endfunction

  // ---------------------------------------------------------------
  // Read path FSM
  // ---------------------------------------------------------------
  typedef enum logic [1:0] {
    RD_IDLE,
    RD_WAIT,    // stall delay
    RD_RESP
  } rd_state_t;

  rd_state_t rd_state;
  logic [31:0] rd_addr_reg;
  logic [31:0] rd_data_reg;
  logic [1:0]  rd_resp_reg;
  logic [3:0]  rd_stall_cnt;

  // Combinational memory read
  function automatic logic [31:0] mem_read(input [31:0] addr);
    if (is_rom(addr))
      return rom[addr[ROM_AW+1:2]];
    else if (is_ram(addr))
      return ram[addr[RAM_AW+1:2]];
    else if (is_clint(addr)) begin
      unique case (addr[15:0])
        16'h0000: mem_read = {31'b0, msip_reg};
        16'h4000: mem_read = mtimecmp[31:0];
        16'h4004: mem_read = mtimecmp[63:32];
        16'hBFF8: mem_read = mtime[31:0];
        16'hBFFC: mem_read = mtime[63:32];
        default:  mem_read = 32'h0;
      endcase
    end
    else if (is_gpio(addr)) begin
      case (addr[4:0])
        5'h00: return gpio_out;
        5'h04: return gpio_oe;
        5'h08: return gpio_in;
        default: return 32'h0;
      endcase
    end
    else if (is_uart(addr)) begin
      case (addr[4:0])
        5'h00: return {24'h0, uart_last_tx};
        5'h04: return {24'h0, uart_rx_data};
        5'h08: return {30'h0, uart_rx_valid, 1'b1};
        5'h0C: return uart_ctrl;
        5'h10: return uart_bauddiv;
        default: return 32'h0;
      endcase
    end
    else if (is_mmio(addr))
      return last_code;
    else if (is_plic(addr))
      return plic_read(addr);
    else
      return 32'hDEAD_BEEF;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_state     <= RD_IDLE;
      rd_addr_reg  <= 32'h0;
      rd_data_reg  <= 32'h0;
      rd_resp_reg  <= 2'b00;
      rd_stall_cnt <= 4'd0;
    end else begin
      case (rd_state)
        RD_IDLE: begin
          if (arvalid && arready) begin
            rd_addr_reg <= araddr;
            if (should_stall(lfsr_r)) begin
              rd_state     <= RD_WAIT;
              rd_stall_cnt <= lfsr_r[3:0] & 4'hF;
            end else begin
              rd_data_reg <= mem_read(araddr);
              if (is_plic(araddr) && ((araddr - 32'h0C00_0000) == PLIC_OFF_CLAIM) &&
                  !plic_claim_active && plic_irq_active) begin
                plic_claim_id     <= plic_winner_id;
                plic_claim_active <= 1'b1;
              end
              rd_resp_reg <= (is_rom(araddr) || is_ram(araddr) || is_clint(araddr) || is_plic(araddr) || is_gpio(araddr) || is_uart(araddr) || is_mmio(araddr)) ? 2'b00 : 2'b11;
              rd_state    <= RD_RESP;
            end
          end
        end

        RD_WAIT: begin
          if (rd_stall_cnt == 0) begin
            rd_data_reg <= mem_read(rd_addr_reg);
            if (is_plic(rd_addr_reg) && ((rd_addr_reg - 32'h0C00_0000) == PLIC_OFF_CLAIM) &&
                !plic_claim_active && plic_irq_active) begin
              plic_claim_id     <= plic_winner_id;
              plic_claim_active <= 1'b1;
            end
            rd_resp_reg <= (is_rom(rd_addr_reg) || is_ram(rd_addr_reg) || is_clint(rd_addr_reg) || is_plic(rd_addr_reg) || is_gpio(rd_addr_reg) || is_uart(rd_addr_reg) || is_mmio(rd_addr_reg)) ? 2'b00 : 2'b11;
            rd_state    <= RD_RESP;
          end else begin
            rd_stall_cnt <= rd_stall_cnt - 1;
          end
        end

        RD_RESP: begin
          if (rvalid && rready) begin
            rd_state <= RD_IDLE;
          end
        end

        default: rd_state <= RD_IDLE;
      endcase
    end
  end

  assign arready = (rd_state == RD_IDLE) && !should_stall(lfsr_ar);
  assign rvalid  = (rd_state == RD_RESP);
  assign rdata   = rd_data_reg;
  assign rresp   = rd_resp_reg;

  // ---------------------------------------------------------------
  // Write path FSM
  // ---------------------------------------------------------------
  always_comb begin
    mtime_next = mtime + 64'd1;
    if (wr_state == WR_EXEC && is_clint(wr_addr_reg)) begin
      unique case (wr_addr_reg[15:0])
        16'hBFF8: mtime_next[31:0]  = apply_wstrb(mtime_next[31:0], wr_data_reg, wr_strb_reg);
        16'hBFFC: mtime_next[63:32] = apply_wstrb(mtime_next[63:32], wr_data_reg, wr_strb_reg);
        default: ;
      endcase
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_state     <= WR_IDLE;
      wr_addr_reg  <= 32'h0;
      wr_data_reg  <= 32'h0;
      wr_strb_reg  <= 4'h0;
      wr_resp_reg  <= 2'b00;
      wr_stall_cnt <= 4'd0;
      pass         <= 1'b0;
      fail         <= 1'b0;
      last_code    <= 32'h0;
      msip_reg     <= 1'b0;
      mtimecmp     <= 64'hFFFF_FFFF_FFFF_FFFF;
      for (int i = 1; i <= 8; i++)
        plic_prio[i] <= 8'd1;
      plic_enabled      <= '0;
      plic_threshold    <= 8'd0;
      plic_claim_id     <= 4'd0;
      plic_claim_active <= 1'b0;
      gpio_out     <= 32'h0;
      gpio_oe      <= 32'h0;
      uart_ctrl     <= 32'h1;
      uart_bauddiv  <= 32'h0;
      uart_last_tx  <= 8'h00;
      uart_rx_data  <= 8'h00;
      uart_rx_valid <= 1'b0;
      uart_tx_valid <= 1'b0;
      uart_tx_data  <= 8'h00;
    end else begin
      mtime <= mtime_next;
      uart_tx_valid <= 1'b0;

      if ((rd_state == RD_IDLE && arvalid && arready && !should_stall(lfsr_r) && is_uart(araddr) && araddr[4:0] == 5'h04) ||
          (rd_state == RD_WAIT && rd_stall_cnt == 0 && is_uart(rd_addr_reg) && rd_addr_reg[4:0] == 5'h04)) begin
        uart_rx_valid <= 1'b0;
      end

      case (wr_state)
        WR_IDLE: begin
          if (awvalid && awready && wvalid && wready) begin
            wr_addr_reg <= awaddr;
            wr_data_reg <= wdata;
            wr_strb_reg <= wstrb;
            wr_state    <= WR_EXEC;
          end else if (awvalid && awready) begin
            wr_addr_reg <= awaddr;
            wr_state    <= WR_GOT_AW;
          end else if (wvalid && wready) begin
            wr_data_reg <= wdata;
            wr_strb_reg <= wstrb;
            wr_state    <= WR_GOT_W;
          end
        end

        WR_GOT_AW: begin
          if (wvalid && wready) begin
            wr_data_reg <= wdata;
            wr_strb_reg <= wstrb;
            wr_state    <= WR_EXEC;
          end
        end

        WR_GOT_W: begin
          if (awvalid && awready) begin
            wr_addr_reg <= awaddr;
            wr_state    <= WR_EXEC;
          end
        end

        WR_EXEC: begin
          // Execute the write
          if (is_ram(wr_addr_reg)) begin
            if (wr_strb_reg[0]) ram[wr_addr_reg[RAM_AW+1:2]][7:0]   <= wr_data_reg[7:0];
            if (wr_strb_reg[1]) ram[wr_addr_reg[RAM_AW+1:2]][15:8]  <= wr_data_reg[15:8];
            if (wr_strb_reg[2]) ram[wr_addr_reg[RAM_AW+1:2]][23:16] <= wr_data_reg[23:16];
            if (wr_strb_reg[3]) ram[wr_addr_reg[RAM_AW+1:2]][31:24] <= wr_data_reg[31:24];
          end
          if (is_mmio(wr_addr_reg) && wr_addr_reg == 32'h1000_0000) begin
            last_code <= wr_data_reg;
            if (wr_data_reg == 32'h0000_0001) pass <= 1'b1;
            if (wr_data_reg == 32'h0000_0000) fail <= 1'b1;
          end
          if (is_clint(wr_addr_reg)) begin
            unique case (wr_addr_reg[15:0])
              16'h0000: if (wr_strb_reg[0]) msip_reg <= |wr_data_reg[0];
              16'h4000: mtimecmp[31:0]  <= apply_wstrb(mtimecmp[31:0], wr_data_reg, wr_strb_reg);
              16'h4004: mtimecmp[63:32] <= apply_wstrb(mtimecmp[63:32], wr_data_reg, wr_strb_reg);
              default: ;
            endcase
          end
          if (is_gpio(wr_addr_reg)) begin
            case (wr_addr_reg[4:0])
              5'h00: gpio_out <= apply_wstrb(gpio_out, wr_data_reg, wr_strb_reg);
              5'h04: gpio_oe  <= apply_wstrb(gpio_oe,  wr_data_reg, wr_strb_reg);
              5'h0C: gpio_out <= gpio_out | wr_data_reg;
              5'h10: gpio_out <= gpio_out & ~wr_data_reg;
              default: ;
            endcase
          end
          if (is_uart(wr_addr_reg)) begin
            case (wr_addr_reg[4:0])
              5'h00: begin
                if (wr_strb_reg[0] && uart_ctrl[0]) begin
                  uart_last_tx  <= wr_data_reg[7:0];
                  uart_tx_data  <= wr_data_reg[7:0];
                  uart_tx_valid <= 1'b1;
                  if (uart_ctrl[1]) begin
                    uart_rx_data  <= wr_data_reg[7:0];
                    uart_rx_valid <= 1'b1;
                  end
                end
              end
              5'h0C: uart_ctrl    <= apply_wstrb(uart_ctrl,    wr_data_reg, wr_strb_reg);
              5'h10: uart_bauddiv <= apply_wstrb(uart_bauddiv, wr_data_reg, wr_strb_reg);
              default: ;
            endcase
          end
          if (is_plic(wr_addr_reg)) begin
            unique case (wr_addr_reg - 32'h0C00_0000)
              PLIC_OFF_ENABLE: begin
                for (int i = 1; i <= 8; i++)
                  plic_enabled[i] <= wr_data_reg[i];
              end
              PLIC_OFF_THRESHOLD: begin
                if (wr_strb_reg[0])
                  plic_threshold <= wr_data_reg[7:0];
              end
              PLIC_OFF_CLAIM: begin
                if (plic_claim_active && (wr_data_reg[3:0] == plic_claim_id))
                  plic_claim_active <= 1'b0;
              end
              default: begin
                logic [31:0] rel;
                int idx;
                rel = wr_addr_reg - 32'h0C00_0000;
                if (rel[1:0] == 2'b00 && rel >= PLIC_OFF_PRIORITY && rel < PLIC_OFF_PENDING) begin
                  idx = plic_source_idx(rel);
                  if (idx >= 1 && idx <= 8 && wr_strb_reg[0])
                    plic_prio[idx] <= wr_data_reg[7:0];
                end
              end
            endcase
          end
          wr_resp_reg <= (is_rom(wr_addr_reg) || is_ram(wr_addr_reg) || is_clint(wr_addr_reg) || is_plic(wr_addr_reg) || is_gpio(wr_addr_reg) || is_uart(wr_addr_reg) || is_mmio(wr_addr_reg)) ? 2'b00 : 2'b11;
          if (should_stall(lfsr_b)) begin
            wr_state     <= WR_WAIT;
            wr_stall_cnt <= lfsr_b[3:0] & 4'h7;
          end else begin
            wr_state <= WR_RESP;
          end
        end

        WR_WAIT: begin
          if (wr_stall_cnt == 0)
            wr_state <= WR_RESP;
          else
            wr_stall_cnt <= wr_stall_cnt - 1;
        end

        WR_RESP: begin
          if (bvalid && bready) begin
            wr_state <= WR_IDLE;
          end
        end

        default: wr_state <= WR_IDLE;
      endcase
    end
  end

  assign awready = (wr_state == WR_IDLE || wr_state == WR_GOT_W) && !should_stall(lfsr_aw);
  assign wready  = (wr_state == WR_IDLE || wr_state == WR_GOT_AW) && !should_stall(lfsr_w);
  assign bvalid  = (wr_state == WR_RESP);
  assign bresp   = wr_resp_reg;
  assign mtip = (mtime >= mtimecmp);
  assign msip = msip_reg;
  assign meip = plic_meip;

endmodule
