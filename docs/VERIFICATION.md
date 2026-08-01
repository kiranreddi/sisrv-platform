# Verification Plan

## Summary

The sisrv-platform uses a multi-tier verification strategy combining directed assembly
tests, randomized cocotb unit tests, and formal proofs. All tests run on Verilator 5.050.

If your host cannot install a RISC-V toolchain, download CI-built ROM images
(`sisrv-sw-artifacts`) and install with `make sw-from-artifacts` — see
[SW_ARTIFACTS.md](SW_ARTIFACTS.md). Unit-level cocotb does not need those images;
directed Verilator runs, commercial/`sisTbTop`, and future platform cocotb/UVM do.

## Verification Tiers

### Tier 1: Directed Assembly Tests (42 regression tests + throughput guard)

Self-checking assembly tests that write 1 to `0x10000000` (PASS) or 0 (FAIL).
Compiled with `rv32im_zicsr` ISA and run on the full platform simulation.

| Category | Tests | What's Verified |
|----------|-------|-----------------|
| ALU basic | test_add_sub, test_addi | ADD/SUB/ADDI correctness |
| ALU edge | test_alu_edge | Overflow, INT_MIN/MAX, shift by 0/31, self-XOR/AND/OR |
| Logic | test_logic | AND/OR/XOR/ANDI/ORI/XORI |
| Shift | test_shift | SLL/SRL/SRA/SLLI/SRLI/SRAI |
| Compare | test_slt | SLT/SLTU/SLTI/SLTIU |
| RV32M | test_rv32m | MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU, divide-by-zero, signed overflow |
| Branch | test_branch, test_branch_edge | All 6 branches + INT_MIN/MAX boundary values |
| Jump | test_jal_jalr, test_jalr_align | JAL/JALR, bit[0] masking, rd=x0 |
| Memory | test_load_store, test_mem_edge, test_ram_walk | All load/store variants, byte lanes, walking patterns |
| CSR | test_csr, test_csr_edge, test_machine_counters | All CSR instructions, ID CSRs, machine counters, mcountinhibit, rs1=x0 read-only behavior |
| Trap | test_ecall, test_ebreak, test_illegal, test_illegal_funct, test_trap_faults | ECALL/EBREAK/illegal opcode, misaligned access, access faults, mcause/mtval + MRET |
| Timer | test_timer, test_mtime_write | MTIP interrupt, ISR handler, MTIME/MTIMECMP, deterministic MTIME writes |
| Timer | test_mret_boundary | MRET exact resume point, no skipped/repeated instructions |
| GPIO | test_gpio | DATA/DIR/IN/SET/CLR MMIO registers |
| UART | test_uart | TXDATA/RXDATA/STATUS/CTRL/BAUDDIV MMIO registers and loopback |
| System | test_fence, test_lui_auipc, test_x0, test_wfi, test_pass | FENCE NOP, LUI/AUIPC, x0=0 invariant, WFI legal no-op |
| Stress | test_back_to_back | Fibonacci, register stress, tight loops |
| Pipeline | test_pipeline_forwarding, test_pipeline_load_use, test_pipeline_flush, test_pipeline_trap_flush, test_pipeline_interrupt_flush, test_pipeline_debug_step; `make pipeline-throughput` runs test_pipeline_throughput on direct corebus | M6 forwarding, load-use stall, branch/jump/trap/interrupt flush, independent ALU throughput guard, debug-step program |

### Tier 2: cocotb Randomized Tests (43 tests)

Unit-level tests using cocotb 2.x with constrained random stimulus on Verilator 5.050.

**ALU (3 tests)**:
- 1000 directed edge-case pairs (10 values × 10 values × 10 ops)
- 1000 random 32-bit operand pairs with random operations
- Full shift amount sweep (0–31) for SLL/SRL/SRA

**RegFile (4 tests)**:
- x0 write attempt (must remain 0)
- Write/read all 31 registers
- Write isolation (modifying one register doesn't corrupt others)
- 500 random read/write cycles with shadow model

**Decoder (11 tests)**:
- Type flag decode for all 11 legal opcodes (exactly one flag set)
- Illegal opcode detection (117 illegal opcodes tested)
- Illegal funct3/funct7/system/fence encoding detection
- Register field extraction (rd, rs1, rs2) with corner values
- I-type immediate sign extension (7 test vectors)
- S-type immediate sign extension (5 test vectors)
- U-type immediate (upper 20 bits, lower 12 zeroed)
- B-type immediate (13-bit signed, bit 0 always 0)
- J-type immediate (21-bit signed, bit 0 always 0)
- funct3/funct7 extraction
- 1000 random instructions with RV32I/RV32M field/legality verification

**CSR (15 tests)**:
- Reset values (implemented CSRs read expected reset values)
- CSRRW write/read all CSRs
- CSRRS set-bits operation
- CSRRC clear-bits operation
- Unknown CSR reads zero
- Trap entry (saves mepc/mcause/mtval, MIE→MPIE, MIE=0)
- MRET (restore MIE from MPIE, MPIE=1)
- MEPC word alignment (lower 2 bits cleared)
- mtvec_out/mepc_out output port verification
- MTIP/irq_pending (ext_mtip → mip.MTIP → irq_pending with MIE/MTIE)
- Machine ID CSRs (`misa`, vendor/arch/impl/hart/config pointer)
- Machine counters (`mcycle`, `minstret`) and `mcountinhibit`
- Synchronous exception trap causes (misalign/access-fault mcause/mtval)

**AXI-Lite Bridge (11 tests)**:
- Reset state verification (req_ready=1, all VALID=0)
- Basic read transaction (AR→R→corebus response)
- Basic write transaction (AW+W→B→corebus response)
- Read error response (DECERR)
- Write error response (SLVERR)
- Stalled read (AR stall + R stall)
- Stalled write (AW/W/B stalls)
- Back-to-back transactions (10 mixed R/W)
- Random stall stress (100 transactions with random stalls 0-5 cycles)
- Write strobe variations (all patterns)
- VALID stability (ARVALID stays high until ARREADY)

### Tier 3: Formal Proofs

**ALU** (`formal/alu_add.sv`):
- All 10 ALU operations formally proven correct:
  ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
- Zero flag proven correct for all operations
- Proven using Yosys SAT solver in < 1 second

**RegFile** (`formal/regfile_x0.sv`):
- Property: x0 reads 0 regardless of any write sequence
- Proven by k-induction using SymbiYosys + z3

**Decoder** (`formal/decode_legal.sv`):
- Field extraction correct for all 2^32 instructions
- U/B/J immediate alignment invariants proven
- is_legal matches RV32I/RV32M encoding rules (opcode + funct3/funct7/system/fence)
- RV32M encodings are illegal when `ENABLE_M=0`
- Proven using Yosys SAT solver

**AXI-Lite Bridge** (`formal/axil_master.sv`):
- VALID stability: ARVALID/AWVALID/WVALID stay high until READY (handshake compliance)
- No simultaneous read and write in progress (mutual exclusion)
- Corebus rsp_valid stability (stays high until rsp_ready)
- req_ready only in IDLE state (no request loss)
- AXI address/data stability while VALID high (no glitches)
- Proven using SymbiYosys + z3 (k-induction, depth 20)

## Running Tests

```bash
# Run all assembly regression tests (76 tests)
make regress

# Run direct-corebus pipeline throughput guard
make pipeline-throughput

# Run M6 debug halt/single-step retirement check
make pipeline-debug

# Run cocotb tests (43 tests)
make cocotb

# Run formal proofs
make formal

# Optional AXI-Lite bounded formal check
make formal-axil

# Run Yosys synthesis
make synth

# Run everything
make lint && make regress && make pipeline-debug && make cocotb && make formal
```

### Tier 4: RISCOF Architectural Compliance (optional smoke)

RISCOF compares memory signatures from the Verilator DUT against Spike for tests drawn
from `riscv-arch-test`. Harness lives under `verification/riscof/`.

**Claimed profile:** `RV32IM_Zicsr_Zifencei`, machine-mode only (`rv32im_zicsr` / `ilp32`).

**Explicitly excluded:** PMP, debug, CLINT/PLIC/interrupts, S/U modes, C/A/F/D/H extensions.

```bash
# One-test smoke (default: add-01)
make riscof-smoke

# Broader local runs (not required CI)
make riscof-rv32i
make riscof-rv32im
```

See `verification/riscof/README.md` for toolchain install, signature dump flow, and mismatch triage.

## CI Pipeline

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push/PR:
1. **Lint** — Verilator lint check
2. **Regression** — 42 assembly tests (corebus + AXI-Lite paths) plus `make pipeline-debug` and `make pipeline-throughput`
3. **cocotb** — 43 randomized unit tests
4. **Formal** — ALU + RegFile + Decoder proofs
5. **Synth** — Yosys synthesis (`make synth`)
6. **RISCOF ACT** — rv32imac_zicsr filtered architectural compliance
7. **Sky130 STA** — post-synth OpenSTA timing report
8. **10k lock-step co-sim** — final gated retired-instruction compare against Spike

## Debug Knobs

- Tracing on failure: always dump FST for last N cycles
- Print architectural state every K cycles behind a verbose flag
- Deterministic seed logging (cocotb seeds printed in log)

## Coverage Goals

- ✅ All RV32I opcodes covered
- ✅ All RV32M opcodes covered
- ✅ Branch taken/not-taken for all 6 conditions
- ✅ All load/store sizes and sign extension
- ✅ All CSR operations + immediate forms
- ✅ All trap types (ECALL, EBREAK, illegal, timer interrupt)
- ✅ Misaligned load/store/control-flow traps
- ✅ Instruction/load/store access fault traps from bus errors
- ✅ Machine ID and counter CSRs
- ✅ ALU edge cases (overflow, boundary values)
- ✅ Memory byte lane coverage
- ✅ Register file x0 invariant (formal proof)
- ✅ AXI-Lite handshake compliance (assertions + cocotb tests; optional bounded formal check)
- ✅ AXI-Lite VALID stability formally proven (ARVALID/AWVALID/WVALID)
- ✅ AXI-Lite read/write mutual exclusion and stalled-channel stability formally checked
- ✅ Timer interrupt end-to-end (ISR execution + return)
- ✅ MRET exact resume point (no skipped/repeated instructions)
- ✅ GPIO MMIO register behavior
- ✅ UART MMIO loopback and console TX behavior
- ✅ M6 forwarding, load-use, branch/jump flush, trap flush, interrupt flush, and debug single-step retirement
