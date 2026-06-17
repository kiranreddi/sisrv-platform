// sisPmp.sv — RV32 PMP region matcher (G=0, 4-byte granularity)
//
// Natural misalignment is handled before this module is consulted; each access
// lies within a single aligned word and cannot straddle two PMP regions.

module sisPmp #(
    parameter int PMP_ENTRIES = 8
)(
    input  logic [PMP_ENTRIES-1:0][7:0]  pmpcfg,
    input  logic [PMP_ENTRIES-1:0][31:0] pmpaddr,

    input  logic [31:0] addr,
    input  logic [1:0]  priv,
    input  logic        req_r,
    input  logic        req_w,
    input  logic        req_x,

    output logic        allow
);

  localparam logic [1:0] PRIV_M = 2'b11;
  localparam logic [1:0] PRIV_U = 2'b00;

  function automatic logic [31:0] napot_mask(input logic [31:0] pa);
    logic [31:0] t;
    begin
      if (pa == 32'hFFFF_FFFF)
        napot_mask = 32'hFFFF_FFFF;
      else
        napot_mask = ~(pa ^ (pa + 32'd1));
    end
  endfunction

  function automatic logic entry_matches(
      input int          idx,
      input logic [31:0] byte_addr,
      input logic [7:0]  cfg,
      input logic [31:0] this_addr,
      input logic [31:0] prev_addr
  );
    logic [29:0] aw;
    logic [1:0]  a;
    logic [31:0] mask;
    begin
      aw = byte_addr[31:2];
      a  = cfg[4:3];
      entry_matches = 1'b0;
      unique case (a)
        2'b00: entry_matches = 1'b0;
        2'b01: entry_matches = (aw >= prev_addr[29:0]) && (aw < this_addr[29:0]);
        2'b10: entry_matches = (aw == this_addr[29:0]);
        2'b11: begin
          mask = napot_mask(this_addr);
          entry_matches = ((byte_addr[31:2] ^ this_addr[29:0]) & mask[29:0]) == 30'h0;
        end
        default: entry_matches = 1'b0;
      endcase
    end
  endfunction

  logic [PMP_ENTRIES-1:0] match;
  logic                   any_match;
  integer                 i, j;
  logic [7:0]             win_cfg;
  logic                   perm_ok;
  logic                   locked;
  logic                   use_perm;

  always_comb begin
    for (i = 0; i < PMP_ENTRIES; i = i + 1) begin
      logic [31:0] prev;
      prev = (i == 0) ? 32'h0 : pmpaddr[i-1];
      match[i] = entry_matches(i, addr, pmpcfg[i], pmpaddr[i], prev);
    end

    any_match = 1'b0;
    win_cfg   = 8'h0;

    for (j = 0; j < PMP_ENTRIES; j = j + 1) begin
      if (match[j] && !any_match) begin
        any_match = 1'b1;
        win_cfg   = pmpcfg[j];
      end
    end

    perm_ok  = (!req_r || win_cfg[0]) && (!req_w || win_cfg[1]) && (!req_x || win_cfg[2]);
    locked   = win_cfg[7];
    use_perm = locked || (priv == PRIV_U);

    if (PMP_ENTRIES == 0) begin
      allow = 1'b1;
    end else if (!any_match) begin
      allow = (priv == PRIV_M);
    end else begin
      allow = use_perm ? perm_ok : 1'b1;
    end
  end

endmodule
