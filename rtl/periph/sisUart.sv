// sisUart.sv - Simple MMIO UART peripheral
//
// MMIO registers, relative to BASE_ADDR:
//   +0x00 TXDATA   WO/R: write low byte to transmit, read last TX byte
//   +0x04 RXDATA   RO:   read low byte from receive register, clears RX valid
//   +0x08 STATUS   RO:   bit0 TX_READY, bit1 RX_VALID
//   +0x0C CTRL     RW:   bit0 TX_ENABLE, bit1 LOOPBACK
//   +0x10 BAUDDIV  RW:   programmable divider placeholder

module sisUart #(
    parameter logic [31:0] BASE_ADDR = 32'h1000_4000
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

    output logic        uart_tx_valid,
    output logic [7:0]  uart_tx_data
);

  localparam logic [4:0] OFF_TXDATA  = 5'h00;
  localparam logic [4:0] OFF_RXDATA  = 5'h04;
  localparam logic [4:0] OFF_STATUS  = 5'h08;
  localparam logic [4:0] OFF_CTRL    = 5'h0C;
  localparam logic [4:0] OFF_BAUDDIV = 5'h10;

  logic        pending;
  logic [31:0] rdata_reg;
  logic [31:0] ctrl_reg;
  logic [31:0] bauddiv_reg;
  logic [7:0]  last_tx_data;
  logic [7:0]  rx_data;
  logic        rx_valid;

  wire        addr_match = (req_addr[31:8] == BASE_ADDR[31:8]);
  wire [4:0]  reg_offset = req_addr[4:0];
  wire        tx_enable = ctrl_reg[0];
  wire        loopback = ctrl_reg[1];

  assign req_ready = !pending || rsp_ready;

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

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending       <= 1'b0;
      rdata_reg     <= 32'h0;
      ctrl_reg      <= 32'h1;
      bauddiv_reg   <= 32'h0;
      last_tx_data  <= 8'h00;
      rx_data       <= 8'h00;
      rx_valid      <= 1'b0;
      uart_tx_valid <= 1'b0;
      uart_tx_data  <= 8'h00;
    end else begin
      uart_tx_valid <= 1'b0;

      if (req_valid && req_ready) begin
        pending <= 1'b1;

        if (addr_match && req_we) begin
          unique case (reg_offset)
            OFF_TXDATA: begin
              if (req_wstrb[0] && tx_enable) begin
                last_tx_data  <= req_wdata[7:0];
                uart_tx_data  <= req_wdata[7:0];
                uart_tx_valid <= 1'b1;
                if (loopback) begin
                  rx_data  <= req_wdata[7:0];
                  rx_valid <= 1'b1;
                end
              end
            end
            OFF_CTRL:    ctrl_reg    <= apply_wstrb(ctrl_reg,    req_wdata, req_wstrb);
            OFF_BAUDDIV: bauddiv_reg <= apply_wstrb(bauddiv_reg, req_wdata, req_wstrb);
            default: ;
          endcase
        end

        if (addr_match && !req_we) begin
          unique case (reg_offset)
            OFF_TXDATA:  rdata_reg <= {24'h0, last_tx_data};
            OFF_RXDATA:  begin
              rdata_reg <= {24'h0, rx_data};
              rx_valid  <= 1'b0;
            end
            OFF_STATUS:  rdata_reg <= {30'h0, rx_valid, 1'b1};
            OFF_CTRL:    rdata_reg <= ctrl_reg;
            OFF_BAUDDIV: rdata_reg <= bauddiv_reg;
            default:     rdata_reg <= 32'h0;
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

endmodule
