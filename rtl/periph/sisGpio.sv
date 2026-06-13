// sisGpio.sv - Simple 32-bit GPIO peripheral
//
// MMIO registers, relative to BASE_ADDR:
//   +0x00 DATA  RW: output data register
//   +0x04 DIR   RW: output enable/direction register (1=output)
//   +0x08 IN    RO: sampled input pins
//   +0x0C SET   WO: write 1s to set DATA bits
//   +0x10 CLR   WO: write 1s to clear DATA bits

module sisGpio #(
    parameter logic [31:0] BASE_ADDR = 32'h1000_3000
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

    input  logic [31:0] gpio_in,
    output logic [31:0] gpio_out,
    output logic [31:0] gpio_oe
);

  localparam logic [4:0] OFF_DATA = 5'h00;
  localparam logic [4:0] OFF_DIR  = 5'h04;
  localparam logic [4:0] OFF_IN   = 5'h08;
  localparam logic [4:0] OFF_SET  = 5'h0C;
  localparam logic [4:0] OFF_CLR  = 5'h10;

  logic        pending;
  logic [31:0] rdata_reg;

  wire        addr_match = (req_addr[31:8] == BASE_ADDR[31:8]);
  wire [4:0]  reg_offset = req_addr[4:0];

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
      pending   <= 1'b0;
      rdata_reg <= 32'h0;
      gpio_out  <= 32'h0;
      gpio_oe   <= 32'h0;
    end else begin
      if (req_valid && req_ready) begin
        pending <= 1'b1;

        if (addr_match && req_we) begin
          unique case (reg_offset)
            OFF_DATA: gpio_out <= apply_wstrb(gpio_out, req_wdata, req_wstrb);
            OFF_DIR:  gpio_oe  <= apply_wstrb(gpio_oe,  req_wdata, req_wstrb);
            OFF_SET:  gpio_out <= gpio_out | req_wdata;
            OFF_CLR:  gpio_out <= gpio_out & ~req_wdata;
            default: ;
          endcase
        end

        if (addr_match && !req_we) begin
          unique case (reg_offset)
            OFF_DATA: rdata_reg <= gpio_out;
            OFF_DIR:  rdata_reg <= gpio_oe;
            OFF_IN:   rdata_reg <= gpio_in;
            OFF_SET:  rdata_reg <= 32'h0;
            OFF_CLR:  rdata_reg <= 32'h0;
            default:  rdata_reg <= 32'h0;
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
