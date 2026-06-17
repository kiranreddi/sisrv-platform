// sisCsr.sv — M-mode CSR unit for RV32IM
// Implements M-mode trap CSRs, ID CSRs, and machine counters.
// Plus CSR read/write operations and trap entry/return logic.
//
// Interrupt semantics (documented decisions):
//   - mstatus.MIE (bit 3):  Global machine interrupt enable
//   - mstatus.MPIE (bit 7): Previous MIE (saved on trap entry, restored on MRET)
//   - mie (bit 7): MTIE — Machine timer interrupt enable
//   - mip (bit 7): MTIP — Machine timer interrupt pending (read-only from external)
//   - mtvec: MODE=0 (direct) and MODE=1 (vectored) supported; bits[1:0] stored as-written
//   - Trap priority: external interrupts checked between instructions

module sisCsr #(
    parameter bit ENABLE_A = 1'b1,
    parameter bit ENABLE_C = 1'b1
)(
    input  logic        clk,
    input  logic        rst_n,

    // CSR access port
    input  logic [11:0] csr_addr,
    input  logic [31:0] csr_wdata,
    input  logic [1:0]  csr_op,       // 00=none, 01=RW, 10=RS(set), 11=RC(clear)
    input  logic        csr_wen,
    output logic [31:0] csr_rdata,

    // Trap interface
    input  logic        trap_enter,   // request trap entry
    input  logic [31:0] trap_cause,   // mcause value
    input  logic [31:0] trap_val,     // mtval value
    input  logic [31:0] trap_epc,     // PC to save in mepc

    input  logic        mret_exec,    // MRET instruction executed
    input  logic        instr_retire, // one instruction retired this cycle

    // External interrupt inputs (CLINT + PLIC)
    input  logic        ext_msip,     // Machine software interrupt pending
    input  logic        ext_mtip,     // Machine timer interrupt pending
    input  logic        ext_meip,     // Machine external interrupt pending (PLIC)

    output logic [31:0] mtvec_out,    // trap vector address
    output logic [31:0] mepc_out,     // return address for MRET
    output logic        irq_pending,  // interrupt pending and enabled
    output logic [31:0] irq_cause     // mcause value for highest-priority IRQ
);

  // CSR addresses
  localparam logic [11:0] CSR_MSTATUS  = 12'h300;
  localparam logic [11:0] CSR_MISA     = 12'h301;
  localparam logic [11:0] CSR_MIE      = 12'h304;
  localparam logic [11:0] CSR_MTVEC    = 12'h305;
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

  // CSR registers
  logic [31:0] mstatus;
  logic [31:0] mie;
  logic [31:0] mtvec;
  logic [31:0] mscratch;
  logic [31:0] mepc;
  logic [31:0] mcause;
  logic [31:0] mtval;
  logic [31:0] mip;
  logic [31:0] mcountinhibit;
  logic [63:0] mcycle;
  logic [63:0] minstret;

  localparam logic [31:0] MISA_BASE  = 32'h4000_1100;
  localparam logic [31:0] MISA_VALUE = MISA_BASE
      | (ENABLE_A ? 32'h0000_0001 : 32'h0)
      | (ENABLE_C ? 32'h0000_0004 : 32'h0);

  // mstatus bits
  // bit 3: MIE (machine interrupt enable)
  // bit 7: MPIE (previous MIE)

  // Reflect external IRQ lines into mip (MSIP=3, MTIP=7, MEIP=11)
  wire [31:0] mip_effective = {mip[31:12], ext_meip, mip[10:8], ext_mtip, mip[6:4], ext_msip, mip[2:0]};

  // CSR read
  always_comb begin
    case (csr_addr)
      CSR_MSTATUS:  csr_rdata = mstatus;
      CSR_MISA:     csr_rdata = MISA_VALUE;
      CSR_MIE:      csr_rdata = mie;
      CSR_MTVEC:    csr_rdata = mtvec;
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
      default:      csr_rdata = 32'h0;
    endcase
  end

  // Compute new CSR value based on operation
  logic [31:0] csr_new_val;
  always_comb begin
    case (csr_op)
      2'b01: csr_new_val = csr_wdata;                   // CSRRW
      2'b10: csr_new_val = csr_rdata | csr_wdata;       // CSRRS
      2'b11: csr_new_val = csr_rdata & ~csr_wdata;      // CSRRC
      default: csr_new_val = csr_rdata;
    endcase
  end

  // CSR write + trap logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mstatus  <= 32'h0000_0000;
      mie      <= 32'h0000_0000;
      mtvec    <= 32'h0000_0000;
      mscratch <= 32'h0000_0000;
      mepc     <= 32'h0000_0000;
      mcause   <= 32'h0000_0000;
      mtval    <= 32'h0000_0000;
      mip      <= 32'h0000_0000;
      mcountinhibit <= 32'h0000_0000;
      mcycle   <= 64'h0;
      minstret <= 64'h0;
    end else begin
      if (!mcountinhibit[0]) begin
        mcycle <= mcycle + 64'd1;
      end
      if (instr_retire && !mcountinhibit[2]) begin
        minstret <= minstret + 64'd1;
      end

      if (trap_enter) begin
        // Save state on trap entry
        mepc    <= trap_epc;
        mcause  <= trap_cause;
        mtval   <= trap_val;
        // Save MIE to MPIE, clear MIE
        mstatus <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
      end else if (mret_exec) begin
        // Restore MIE from MPIE, set MPIE=1
        mstatus <= {mstatus[31:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]};
      end else if (csr_wen) begin
        case (csr_addr)
          CSR_MSTATUS:  mstatus  <= csr_new_val;
          CSR_MIE:      mie      <= csr_new_val;
          CSR_MTVEC:    mtvec    <= csr_new_val;
          CSR_MCOUNTINHIBIT: mcountinhibit <= csr_new_val;
          CSR_MSCRATCH: mscratch <= csr_new_val;
          CSR_MEPC:     mepc     <= csr_new_val & (ENABLE_C ? 32'hFFFF_FFFE : 32'hFFFF_FFFC);
          CSR_MCAUSE:   mcause   <= csr_new_val;
          CSR_MTVAL:    mtval    <= csr_new_val;
          CSR_MCYCLE:   mcycle[31:0] <= csr_new_val;
          CSR_MCYCLEH:  mcycle[63:32] <= csr_new_val;
          CSR_MINSTRET: minstret[31:0] <= csr_new_val;
          CSR_MINSTRETH: minstret[63:32] <= csr_new_val;
          default: ;
        endcase
      end
    end
  end

  assign mtvec_out = mtvec;
  assign mepc_out  = mepc;

  // Interrupt pending: mstatus.MIE && any enabled+pending IRQ bit
  wire meip_on = mstatus[3] && mie[11] && ext_meip;
  wire mtip_on = mstatus[3] && mie[7]  && ext_mtip;
  wire msip_on = mstatus[3] && mie[3]  && ext_msip;

  assign irq_pending = meip_on | mtip_on | msip_on;

  // Priority: MEIP > MTIP > MSIP (standard platform convention)
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
