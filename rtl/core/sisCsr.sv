// sisCsr.sv — M-mode CSR unit for RV32IMACU with PMP
// Implements trap CSRs, privilege state, PMP CSRs, and machine counters.

module sisCsr #(
    parameter bit ENABLE_A = 1'b1,
    parameter bit ENABLE_C = 1'b1,
    parameter bit ENABLE_U = 1'b1,
    parameter int PMP_ENTRIES = 8
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic [11:0] csr_addr,
    input  logic [31:0] csr_wdata,
    input  logic [1:0]  csr_op,
    input  logic        csr_wen,
    output logic [31:0] csr_rdata,

    input  logic        trap_enter,
    input  logic [31:0] trap_cause,
    input  logic [31:0] trap_val,
    input  logic [31:0] trap_epc,

    input  logic        mret_exec,
    input  logic        instr_retire,

    input  logic        ext_msip,
    input  logic        ext_mtip,
    input  logic        ext_meip,

    output logic [31:0] mtvec_out,
    output logic [31:0] mepc_out,
    output logic        irq_pending,
    output logic [31:0] irq_cause,

    output logic [1:0]  priv_o,
    output logic        mstatus_tw_o,
    output logic        mstatus_mprv_o,
    output logic [1:0]  mstatus_mpp_o,
    output logic [2:0]  mcounteren_o,
    output logic [PMP_ENTRIES-1:0][7:0]  pmpcfg_o,
    output logic [PMP_ENTRIES-1:0][31:0] pmpaddr_o
);

  localparam logic [1:0] PRIV_M = 2'b11;
  localparam logic [1:0] PRIV_U = 2'b00;

  localparam logic [11:0] CSR_MSTATUS  = 12'h300;
  localparam logic [11:0] CSR_MISA     = 12'h301;
  localparam logic [11:0] CSR_MIE      = 12'h304;
  localparam logic [11:0] CSR_MTVEC    = 12'h305;
  localparam logic [11:0] CSR_MCOUNTEREN = 12'h306;
  localparam logic [11:0] CSR_MCOUNTINHIBIT = 12'h320;
  localparam logic [11:0] CSR_MSCRATCH = 12'h340;
  localparam logic [11:0] CSR_MEPC     = 12'h341;
  localparam logic [11:0] CSR_MCAUSE   = 12'h342;
  localparam logic [11:0] CSR_MTVAL    = 12'h343;
  localparam logic [11:0] CSR_MIP      = 12'h344;
  localparam logic [11:0] CSR_MVENDORID = 12'hF11;
  localparam logic [11:0] CSR_MARCHID   = 12'hF12;
  localparam logic [11:0] CSR_MIMPID    = 12'hF13;
  localparam logic [11:0] CSR_MHARTID   = 12'hF14;
  localparam logic [11:0] CSR_MCONFIGPTR = 12'hF15;
  localparam logic [11:0] CSR_MCYCLE    = 12'hB00;
  localparam logic [11:0] CSR_MINSTRET  = 12'hB02;
  localparam logic [11:0] CSR_MCYCLEH   = 12'hB80;
  localparam logic [11:0] CSR_MINSTRETH = 12'hB82;
  localparam logic [11:0] CSR_CYCLE     = 12'hC00;
  localparam logic [11:0] CSR_CYCLEH    = 12'hC80;
  localparam logic [11:0] CSR_INSTRET   = 12'hC02;
  localparam logic [11:0] CSR_INSTRETH  = 12'hC82;

  localparam logic [31:0] MSTATUS_WMASK = 32'h0022_1888; // MIE, MPIE, MPP, MPRV, TW

  logic [31:0] mstatus;
  logic [31:0] mie;
  logic [31:0] mtvec;
  logic [31:0] mcounteren;
  logic [31:0] mscratch;
  logic [31:0] mepc;
  logic [31:0] mcause;
  logic [31:0] mtval;
  logic [31:0] mip;
  logic [31:0] mcountinhibit;
  logic [63:0] mcycle;
  logic [63:0] minstret;
  logic [1:0]  priv;

  logic [PMP_ENTRIES-1:0][7:0]  pmpcfg;
  logic [PMP_ENTRIES-1:0][31:0] pmpaddr;

  localparam logic [31:0] MISA_BASE  = 32'h4000_1100;
  localparam logic [31:0] MISA_VALUE = MISA_BASE
      | (ENABLE_A ? 32'h0000_0001 : 32'h0)
      | (ENABLE_C ? 32'h0000_0004 : 32'h0)
      | (ENABLE_U ? 32'h0010_0000 : 32'h0);

  wire [31:0] mip_effective = {mip[31:12], ext_meip, mip[10:8], ext_mtip, mip[6:4], ext_msip, mip[2:0]};

  function automatic logic [7:0] warl_pmpcfg_byte(input logic [7:0] val);
    logic [1:0] a;
    begin
      a = val[4:3];
      warl_pmpcfg_byte = {val[7], 2'b00, a, val[2:0]};
    end
  endfunction

  function automatic logic [31:0] apply_mstatus_warl(input logic [31:0] old_val, input logic [31:0] new_val);
    logic [31:0] merged;
    logic [1:0]  mpp_in;
    logic [1:0]  mpp_out;
    begin
      merged = (old_val & ~MSTATUS_WMASK) | (new_val & MSTATUS_WMASK);
      if (!ENABLE_U) begin
        merged[12:11] = 2'b00;
        merged[17]    = 1'b0;
        merged[21]    = 1'b0;
      end else begin
        mpp_in = merged[12:11];
        if (mpp_in == 2'b01 || mpp_in == 2'b10)
          mpp_out = PRIV_U;
        else
          mpp_out = mpp_in;
        merged[12:11] = mpp_out;
      end
      apply_mstatus_warl = merged;
    end
  endfunction

  function automatic logic pmpcfg_locked(input int idx);
    begin
      pmpcfg_locked = (idx < PMP_ENTRIES) && pmpcfg[idx][7];
    end
  endfunction

  function automatic logic pmpaddr_write_blocked(input int idx);
    begin
      pmpaddr_write_blocked = 1'b0;
      if (idx >= PMP_ENTRIES) begin
        pmpaddr_write_blocked = 1'b1;
      end else if (pmpcfg_locked(idx)) begin
        pmpaddr_write_blocked = 1'b1;
      end else if ((idx + 1) < PMP_ENTRIES) begin
        if (pmpcfg[idx + 1][4:3] == 2'b01 && pmpcfg[idx + 1][7])
          pmpaddr_write_blocked = 1'b1;
      end
    end
  endfunction

  function automatic logic csr_is_pmpcfg(input logic [11:0] addr, output int idx);
    begin
      csr_is_pmpcfg = 1'b0;
      idx = 0;
      if (addr >= 12'h3A0 && (addr < 12'(12'h3A0 + PMP_ENTRIES))) begin
        idx = int'(addr - 12'h3A0);
        csr_is_pmpcfg = idx < PMP_ENTRIES;
      end
    end
  endfunction

  function automatic logic csr_is_pmpaddr(input logic [11:0] addr, output int idx);
    begin
      csr_is_pmpaddr = 1'b0;
      idx = 0;
      if (addr >= 12'h3B0 && addr <= 12'h3EF && ((int'(addr - 12'h3B0) % 4) == 0)) begin
        idx = int'(addr - 12'h3B0) / 4;
        csr_is_pmpaddr = idx < PMP_ENTRIES;
      end
    end
  endfunction

  logic [31:0] csr_new_val;
  always_comb begin
    case (csr_op)
      2'b01: csr_new_val = csr_wdata;
      2'b10: csr_new_val = csr_rdata | csr_wdata;
      2'b11: csr_new_val = csr_rdata & ~csr_wdata;
      default: csr_new_val = csr_rdata;
    endcase
  end

  logic        is_pmpcfg;
  logic        is_pmpaddr;
  int          pmp_cfg_idx;
  int          pmp_idx;

  always_comb begin
    is_pmpcfg = csr_is_pmpcfg(csr_addr, pmp_cfg_idx);
    is_pmpaddr = csr_is_pmpaddr(csr_addr, pmp_idx);

    case (csr_addr)
      CSR_MSTATUS:  csr_rdata = mstatus;
      CSR_MISA:     csr_rdata = MISA_VALUE;
      CSR_MIE:      csr_rdata = mie;
      CSR_MTVEC:    csr_rdata = mtvec;
      CSR_MCOUNTEREN: csr_rdata = mcounteren;
      CSR_MCOUNTINHIBIT: csr_rdata = mcountinhibit;
      CSR_MSCRATCH: csr_rdata = mscratch;
      CSR_MEPC:     csr_rdata = mepc;
      CSR_MCAUSE:   csr_rdata = mcause;
      CSR_MTVAL:    csr_rdata = mtval;
      CSR_MIP:      csr_rdata = mip_effective;
      CSR_MVENDORID: csr_rdata = 32'h0;
      CSR_MARCHID:   csr_rdata = 32'h0;
      CSR_MIMPID:    csr_rdata = 32'h0;
      CSR_MHARTID:   csr_rdata = 32'h0;
      CSR_MCONFIGPTR: csr_rdata = 32'h0;
      CSR_MCYCLE:    csr_rdata = mcycle[31:0];
      CSR_MCYCLEH:   csr_rdata = mcycle[63:32];
      CSR_MINSTRET:  csr_rdata = minstret[31:0];
      CSR_MINSTRETH: csr_rdata = minstret[63:32];
      CSR_CYCLE:     csr_rdata = mcycle[31:0];
      CSR_CYCLEH:    csr_rdata = mcycle[63:32];
      CSR_INSTRET:   csr_rdata = minstret[31:0];
      CSR_INSTRETH:  csr_rdata = minstret[63:32];
      default: begin
        if (is_pmpcfg)
          csr_rdata = {24'h0, pmpcfg[pmp_cfg_idx]};
        else if (is_pmpaddr)
          csr_rdata = pmpaddr[pmp_idx];
        else
          csr_rdata = 32'h0;
      end
    endcase
  end

  logic [1:0] mret_next_priv;
  assign mret_next_priv = mstatus[12:11];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mstatus  <= 32'h0;
      mie      <= 32'h0;
      mtvec    <= 32'h0;
      mcounteren <= 32'h0;
      mscratch <= 32'h0;
      mepc     <= 32'h0;
      mcause   <= 32'h0;
      mtval    <= 32'h0;
      mip      <= 32'h0;
      mcountinhibit <= 32'h0;
      mcycle   <= 64'h0;
      minstret <= 64'h0;
      priv     <= PRIV_M;
      for (int ri = 0; ri < PMP_ENTRIES; ri = ri + 1) begin
        pmpcfg[ri]  <= 8'h0;
        pmpaddr[ri] <= 32'h0;
      end
    end else begin
      if (!mcountinhibit[0])
        mcycle <= mcycle + 64'd1;
      if (instr_retire && !mcountinhibit[2])
        minstret <= minstret + 64'd1;

      if (trap_enter) begin
        mepc    <= trap_epc;
        mcause  <= trap_cause;
        mtval   <= trap_val;
        mstatus <= {mstatus[31:13], priv[1:0], mstatus[10:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
        priv    <= PRIV_M;
      end else if (mret_exec) begin
        priv <= mret_next_priv;
        mstatus <= {mstatus[31:18],
                    (mret_next_priv == PRIV_M) ? mstatus[17] : 1'b0,
                    mstatus[16:13],
                    ENABLE_U ? PRIV_U : PRIV_M,
                    mstatus[10:8],
                    1'b1,
                    mstatus[6:4],
                    mstatus[7],
                    mstatus[2:0]};
      end else if (csr_wen) begin
        case (csr_addr)
          CSR_MSTATUS:  mstatus <= apply_mstatus_warl(mstatus, csr_new_val);
          CSR_MIE:      mie <= csr_new_val;
          CSR_MTVEC:    mtvec <= csr_new_val;
          CSR_MCOUNTEREN: mcounteren <= csr_new_val & 32'h0000_0007;
          CSR_MCOUNTINHIBIT: mcountinhibit <= csr_new_val;
          CSR_MSCRATCH: mscratch <= csr_new_val;
          CSR_MEPC:     mepc <= csr_new_val & (ENABLE_C ? 32'hFFFF_FFFE : 32'hFFFF_FFFC);
          CSR_MCAUSE:   mcause <= csr_new_val;
          CSR_MTVAL:    mtval <= csr_new_val;
          CSR_MCYCLE:   mcycle[31:0] <= csr_new_val;
          CSR_MCYCLEH:  mcycle[63:32] <= csr_new_val;
          CSR_MINSTRET: minstret[31:0] <= csr_new_val;
          CSR_MINSTRETH: minstret[63:32] <= csr_new_val;
          default: begin
            if (is_pmpcfg) begin
              if (!pmpcfg_locked(pmp_cfg_idx))
                pmpcfg[pmp_cfg_idx] <= warl_pmpcfg_byte(csr_new_val[7:0]);
            end else if (is_pmpaddr && !pmpaddr_write_blocked(pmp_idx)) begin
              pmpaddr[pmp_idx] <= csr_new_val;
            end
          end
        endcase
      end
    end
  end

  assign mtvec_out = mtvec;
  assign mepc_out  = mepc;
  assign priv_o = priv;
  assign mstatus_tw_o = mstatus[21];
  assign mstatus_mprv_o = mstatus[17];
  assign mstatus_mpp_o = mstatus[12:11];
  assign mcounteren_o = mcounteren[2:0];
  assign pmpcfg_o = pmpcfg;
  assign pmpaddr_o = pmpaddr;

  wire meip_on = mstatus[3] && mie[11] && ext_meip;
  wire mtip_on = mstatus[3] && mie[7]  && ext_mtip;
  wire msip_on = mstatus[3] && mie[3]  && ext_msip;

  assign irq_pending = meip_on | mtip_on | msip_on;

  always_comb begin
    irq_cause = 32'h0;
    if (meip_on)
      irq_cause = {1'b1, 31'd11};
    else if (mtip_on)
      irq_cause = {1'b1, 31'd7};
    else if (msip_on)
      irq_cause = {1'b1, 31'd3};
  end

endmodule
