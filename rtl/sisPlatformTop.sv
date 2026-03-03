module sisPlatformTop (
    input  logic clk,
    input  logic rst_n
);
  // TODO: integrate core + fabric
  // For Milestone 0: stubbed to satisfy build.
  logic [31:0] dummy;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) dummy <= 32'h0;
    else        dummy <= dummy + 1;
  end
endmodule
