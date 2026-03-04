// sisAxiLiteSlave.sv — AXI4-Lite Slave Memory Model (Testbench only)
// Combined ROM/RAM/MMIO slave with configurable random stall injection.
// Used to verify the AXI4-Lite bridge path end-to-end.
//
// Address map (same as corebus):
//   ROM:  0x0000_0000 - 0x0000_FFFF (64 KB)
//   MMIO: 0x1000_0000 - 0x1000_FFFF (64 KB)
//   RAM:  0x8000_0000 - 0x8003_FFFF (256 KB)

module sisAxiLiteSlave #(
    parameter int ROM_DEPTH_WORDS = 16384,
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
    output logic [31:0] last_code
);

  // ---------------------------------------------------------------
  // Memory arrays
  // ---------------------------------------------------------------
  localparam ROM_AW = $clog2(ROM_DEPTH_WORDS);
  localparam RAM_AW = $clog2(RAM_DEPTH_WORDS);

  logic [31:0] rom [0:ROM_DEPTH_WORDS-1];
  logic [31:0] ram [0:RAM_DEPTH_WORDS-1];

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
    if (STALL_RATE == 0) return 1'b0;
    return (lfsr_val[6:0] < STALL_RATE[6:0]);
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
    else if (is_mmio(addr))
      return last_code;
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
              rd_resp_reg <= (is_rom(araddr) || is_ram(araddr) || is_mmio(araddr)) ? 2'b00 : 2'b11;
              rd_state    <= RD_RESP;
            end
          end
        end

        RD_WAIT: begin
          if (rd_stall_cnt == 0) begin
            rd_data_reg <= mem_read(rd_addr_reg);
            rd_resp_reg <= (is_rom(rd_addr_reg) || is_ram(rd_addr_reg) || is_mmio(rd_addr_reg)) ? 2'b00 : 2'b11;
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
  typedef enum logic [2:0] {
    WR_IDLE,
    WR_GOT_AW,   // Got AW, waiting for W
    WR_GOT_W,    // Got W, waiting for AW
    WR_EXEC,     // Both AW+W received, execute write
    WR_WAIT,     // Stall before B response
    WR_RESP      // B response
  } wr_state_t;

  wr_state_t wr_state;
  logic [31:0] wr_addr_reg;
  logic [31:0] wr_data_reg;
  logic [3:0]  wr_strb_reg;
  logic [1:0]  wr_resp_reg;
  logic [3:0]  wr_stall_cnt;

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
    end else begin
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
          wr_resp_reg <= (is_rom(wr_addr_reg) || is_ram(wr_addr_reg) || is_mmio(wr_addr_reg)) ? 2'b00 : 2'b11;
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

endmodule
