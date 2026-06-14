// sisRegFile.sv — 32-entry register file for RV32I
// x0 is hardwired to zero.
// 2 combinational read ports, 1 synchronous write port.

module sisRegFile (
    input  logic        clk,

    // Read port A
    input  logic [4:0]  rs1_addr,
    output logic [31:0] rs1_data,

    // Read port B
    input  logic [4:0]  rs2_addr,
    output logic [31:0] rs2_data,

    // Write port
    input  logic        wr_en,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,

    // Debug abstract access (when dbg_en, overrides normal write)
    input  logic        dbg_en,
    input  logic        dbg_we,
    input  logic [4:0]  dbg_addr,
    input  logic [31:0] dbg_wdata,
    output logic [31:0] dbg_rdata
);

  logic [31:0] regs [1:31]; // x1..x31

  // Combinational read with x0 = 0
  assign rs1_data = (rs1_addr == 5'd0) ? 32'h0 : regs[rs1_addr];
  assign rs2_data = (rs2_addr == 5'd0) ? 32'h0 : regs[rs2_addr];
  assign dbg_rdata = (dbg_addr == 5'd0) ? 32'h0 : regs[dbg_addr];

  // Synchronous write (never write x0); debug port wins over pipeline write
  always_ff @(posedge clk) begin
    if (dbg_en && dbg_we && (dbg_addr != 5'd0)) begin
      regs[dbg_addr] <= dbg_wdata;
    end else if (wr_en && (rd_addr != 5'd0)) begin
      regs[rd_addr] <= rd_data;
    end
  end

endmodule
