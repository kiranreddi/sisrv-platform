// sisCsr.sv — M-mode CSR unit for RV32I
// Implements minimal set: mstatus, mtvec, mepc, mcause, mtval, mscratch, mie, mip
// Plus CSR read/write operations and trap entry/return logic.
//
// Interrupt semantics (documented decisions):
//   - mstatus.MIE (bit 3):  Global machine interrupt enable
//   - mstatus.MPIE (bit 7): Previous MIE (saved on trap entry, restored on MRET)
//   - mie (bit 7): MTIE — Machine timer interrupt enable
//   - mip (bit 7): MTIP — Machine timer interrupt pending (read-only from external)
//   - mtvec: Direct mode only (MODE=0, no vectored mode)
//   - Trap priority: external interrupts checked between instructions

module sisCsr (
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

    // External interrupt input
    input  logic        ext_mtip,     // Machine timer interrupt pending (from timer)

    output logic [31:0] mtvec_out,    // trap vector address
    output logic [31:0] mepc_out,     // return address for MRET
    output logic        irq_pending   // interrupt pending and enabled
);

  // CSR addresses
  localparam logic [11:0] CSR_MSTATUS  = 12'h300;
  localparam logic [11:0] CSR_MIE      = 12'h304;
  localparam logic [11:0] CSR_MTVEC    = 12'h305;
  localparam logic [11:0] CSR_MSCRATCH = 12'h340;
  localparam logic [11:0] CSR_MEPC     = 12'h341;
  localparam logic [11:0] CSR_MCAUSE   = 12'h342;
  localparam logic [11:0] CSR_MTVAL    = 12'h343;
  localparam logic [11:0] CSR_MIP      = 12'h344;

  // CSR registers
  logic [31:0] mstatus;
  logic [31:0] mie;
  logic [31:0] mtvec;
  logic [31:0] mscratch;
  logic [31:0] mepc;
  logic [31:0] mcause;
  logic [31:0] mtval;
  logic [31:0] mip;

  // mstatus bits
  // bit 3: MIE (machine interrupt enable)
  // bit 7: MPIE (previous MIE)

  // Reflect external MTIP into mip (bit 7) — read-only from external source
  wire [31:0] mip_effective = {mip[31:8], ext_mtip, mip[6:0]};

  // CSR read
  always_comb begin
    case (csr_addr)
      CSR_MSTATUS:  csr_rdata = mstatus;
      CSR_MIE:      csr_rdata = mie;
      CSR_MTVEC:    csr_rdata = mtvec;
      CSR_MSCRATCH: csr_rdata = mscratch;
      CSR_MEPC:     csr_rdata = mepc;
      CSR_MCAUSE:   csr_rdata = mcause;
      CSR_MTVAL:    csr_rdata = mtval;
      CSR_MIP:      csr_rdata = mip_effective;
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
    end else if (trap_enter) begin
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
        CSR_MSCRATCH: mscratch <= csr_new_val;
        CSR_MEPC:     mepc     <= csr_new_val & 32'hFFFF_FFFC; // word-aligned
        CSR_MCAUSE:   mcause   <= csr_new_val;
        CSR_MTVAL:    mtval    <= csr_new_val;
        default: ;
      endcase
    end
  end

  assign mtvec_out = mtvec;
  assign mepc_out  = mepc;

  // Interrupt pending: mstatus.MIE && (mie & mip) has any enabled+pending bits
  assign irq_pending = mstatus[3] && ((mie & mip_effective) != 32'h0);

endmodule
