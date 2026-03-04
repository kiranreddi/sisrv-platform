# Implementation Status

**Last updated**: 2026-03-03

## Summary

The sisrv-platform project implements a fully functional RV32I RISC-V processor core
with M-mode CSRs, trap handling, timer interrupts, and an AXI4-Lite master bridge.
The core is verified through 25 directed assembly tests, 40 cocotb randomized unit tests,
and 4 formal proofs — all running on Verilator 5.038.

## Milestone Status

### ✅ Milestone 0 — Repo bootstrap & golden sim flow
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| Verilator C++ harness | ✅ Done | `tb/verilator/main.cpp` — clock, reset, pass/fail monitor |
| ROM simulation model | ✅ Done | `rtl/periph/sisRom.sv` — $readmemh initialization |
| RAM simulation model | ✅ Done | `rtl/periph/sisRam.sv` — byte-level write strobes |
| sisTohost MMIO | ✅ Done | `rtl/periph/sisTohost.sv` — PASS/FAIL protocol |
| `make sim` | ✅ Done | Builds + runs in < 2s |
| `make wave` | ✅ Done | FST waveform dump |
| `make regress` | ✅ Done | Runs all assembly tests |
| Watchdog timeout | ✅ Done | 200K cycle limit |
| Deterministic reset | ✅ Done | Fixed 10-cycle reset deassert |

**Exit criteria**: `make sim` completes in < 2s ✅, waveform dump created ✅

---

### ✅ Milestone 1 — RV32I multi-cycle (FSM) core
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `sisRvCore.sv` | ✅ Done | 7-state FSM: FETCH_REQ→FETCH_WAIT→DECODE→EXECUTE→MEM_REQ→MEM_WAIT→WB |
| `sisAlu.sv` | ✅ Done | ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND |
| `sisRegFile.sv` | ✅ Done | 32x32 reg file, x0 hardwired, 2R/1W |
| `sisDecode.sv` | ✅ Done | All RV32I instruction types decoded |
| `sisMemFabric.sv` | ✅ Done | Address decoder: ROM/RAM/MMIO routing |

**Test coverage** (25 directed tests, all passing):

| Test | Instructions Covered |
|------|---------------------|
| test_addi | ADDI (positive, negative, zero) |
| test_add_sub | ADD, SUB |
| test_alu_edge | ALU overflow, INT_MIN/MAX, shift by 0/31, self-XOR/AND/OR |
| test_logic | AND, OR, XOR, ANDI, ORI, XORI |
| test_shift | SLL, SRL, SRA, SLLI, SRLI, SRAI |
| test_slt | SLT, SLTU, SLTI, SLTIU |
| test_branch | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| test_branch_edge | Branch with INT_MIN/MAX, unsigned edge cases |
| test_lui_auipc | LUI, AUIPC |
| test_jal_jalr | JAL, JALR |
| test_jalr_align | JALR bit[0] masking, rd=x0 discard link |
| test_load_store | LW, LH, LHU, LB, LBU, SW, SH, SB |
| test_mem_edge | All byte lanes SB/LB/LBU, halfwords, back-to-back |
| test_ram_walk | Walking ones/zeros RAM data integrity |
| test_x0 | x0 hardwired to zero invariant |
| test_pass | Minimal end-to-end (write PASS to tohost) |
| test_csr | CSR read/write operations |
| test_csr_edge | CSRRS/CSRRC with rs1=x0, CSRRWI/SI/CI edge cases |
| test_ecall | ECALL trap + MRET return |
| test_ebreak | EBREAK trap (mcause=3) + MRET return |
| test_illegal | Illegal instruction trap (mcause=2) |
| test_fence | FENCE as NOP |
| test_back_to_back | Fibonacci, register file stress, data dependencies, loops |
| test_timer | Timer interrupt: MTIP, ISR counter, MRET return |
| test_mret_boundary | MRET exact resume point: no skipped/repeated instructions |

**Exit criteria**: 25 directed tests covering all instruction groups ✅,
x0 always 0 ✅, PC word-aligned ✅, correct sign/zero extension ✅

---

### ✅ Milestone 2 — Minimal CSRs + traps
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `sisCsr.sv` | ✅ Done | mstatus, mtvec, mepc, mcause, mtval, mscratch, mie, mip |
| CSR instructions | ✅ Done | CSRRW, CSRRS, CSRRC + immediate forms |
| ECALL/EBREAK | ✅ Done | Trap entry with correct mcause |
| MRET | ✅ Done | Returns to mepc, restores MIE from MPIE |
| Trap tests | ✅ Done | test_ecall, test_ebreak, test_illegal, test_csr, test_csr_edge |

**Interrupt semantics (documented decisions)**:
- `mstatus.MIE` (bit 3): Global machine interrupt enable
- `mstatus.MPIE` (bit 7): Previous MIE saved on trap entry, restored on MRET
- `mtvec`: **Direct mode only** (MODE=0, no vectored mode)
- Trap priority: synchronous exceptions checked first, then asynchronous interrupts between instructions

**Exit criteria**: Trap tests pass ✅, mcause/mepc match expected ✅, no regressions ✅

---

### ✅ Milestone 2.5 — Verification infrastructure
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| cocotb ALU tests | ✅ Done | 1000 directed + 1000 random + shift sweep (Verilator 5.038) |
| cocotb RegFile tests | ✅ Done | x0 zero, write/read all, isolation, 500 random cycles |
| cocotb Decode tests | ✅ Done | Type flags, illegal opcodes, immediates (I/S/U/B/J), register extraction, 1000 random |
| cocotb CSR tests | ✅ Done | Reset values, RW/RS/RC ops, trap entry, MRET, MEPC alignment, MTIP/irq_pending |
| cocotb AXI-Lite tests | ✅ Done | Reset, read/write, errors, stalls, random stress (100 txns), VALID stability |
| Formal ALU proof | ✅ Done | All 10 ops proven correct (yosys SAT, < 1s) |
| Formal RegFile proof | ✅ Done | x0-always-zero (k-induction, SymbiYosys + z3) |
| Formal Decode proof | ✅ Done | Field extraction, immediate invariants, legality consistency (yosys SAT) |
| Formal AXI-Lite proof | ✅ Done | VALID stability, deadlock freedom, mutual exclusion, data stability |
| CI pipeline | ✅ Done | GitHub Actions: lint, regress, cocotb, formal |

---

### ✅ Milestone 3 — AXI4-Lite master bridge
**Status: RTL COMPLETE, system integration incomplete**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `sisAxiLiteM.sv` | ✅ Done | Corebus → AXI4-Lite bridge, strict FSM |
| AXI4-Lite compliance | ✅ Done | Proper AR/R and AW+W/B handshake |
| Single outstanding | ✅ Done | One read OR one write at a time |
| Lint clean | ✅ Done | Verilator Wall clean |
| Synthesizable assertions | ✅ Done | VALID stability, no simultaneous R+W (ifdef ASSERT) |
| `USE_AXIL` param switch | ✅ Done | `sisPlatformTop`: 0=corebus, 1=AXI-Lite |
| AXI-Lite slave TB model | ✅ Done | `tb/models/sisAxiLiteSlave.sv` with independent per-channel stalls |
| cocotb bridge tests | ✅ Done | 11 tests: reset, R/W, errors, stalls, 100-txn random stress |
| Formal AXI-Lite bridge | ✅ Done | VALID stability, deadlock freedom, mutual exclusion, data stability |

**Remaining for full milestone completion**:
- Full regression suite through AXI path (USE_AXIL=1) not yet in CI
- 1000-seed randomized stall stress not yet in nightly CI

---

### ✅ Milestone 4 — Timer interrupt
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `sisTimer.sv` | ✅ Done | MTIME (64-bit counter), MTIMECMP, MTIP output |
| CSR MTIP integration | ✅ Done | ext_mtip → mip.MTIP (bit 7), irq_pending output |
| Core interrupt handling | ✅ Done | Checked between instructions (WB→FETCH transition) |
| mstatus.MIE/MPIE | ✅ Done | Swap on trap entry, restore on MRET |
| Timer test | ✅ Done | test_timer.S: periodic interrupt, ISR counter, MRET |
| cocotb irq test | ✅ Done | test_csr_mtip_irq_pending |

**Interrupt semantics**:
- MTIP asserted when MTIME ≥ MTIMECMP (combinational)
- Interrupt taken only when mstatus.MIE=1 AND mie.MTIE=1 AND mip.MTIP=1
- mcause = 0x80000007 (bit 31 = interrupt flag, code 7 = machine timer)
- mepc = PC + 4 (return to next instruction after interrupted one)
- Acknowledged by writing large value to MTIMECMP

**Exit criteria**: Timer fires, ISR runs, main loop continues, PASS when both counters match ✅

---

### 🔲 Milestone 5 — RV32M (mul/div)
**Status: NOT STARTED**

Planned:
- MUL/MULH/MULHU/MULHSU
- DIV/DIVU/REM/REMU
- `ENABLE_M` configuration knob

---

### 🔲 Milestone 6 — 3-stage pipeline
**Status: NOT STARTED**

Planned:
- Replace FSM with 3-stage F/D/EX+WB pipeline
- ALU forwarding, load-use stall, branch flush

---

### ✅ Milestone 7 — Yosys synthesis readiness
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `scripts/yosys_synth.tcl` | ✅ Done | Synthesizes core + AXI bridge, generates area report |
| $readmemh guarded | ✅ Done | `ifndef SYNTHESIS` in sisRom.sv and sisRam.sv |
| Sim/synth separation | ✅ Done | Memory init is simulation-only; initial blocks documented |
| Reset strategy audit | ✅ Done | Consistent async active-low reset across all modules |
| No sim constructs in synth | ✅ Done | $readmemh, $display behind guards; initial blocks are ASIC-safe |
| `make synth` target | ✅ Done | Runs Yosys synthesis from Makefile |

**Synthesis constraints (documented)**:
- Target clock period: 20ns (50 MHz, conservative for educational design)
- Single clock domain, async active-low reset (consistent across all modules)
- Memories (ROM/RAM) should use SRAM macros in real ASIC flow
- Register file has no reset (intentional: ASIC-standard, contents undefined at power-on)
- No sim-only constructs in synth path: $readmemh behind `ifndef SYNTHESIS`, initial blocks ignored by synth tools

**Reset strategy (audited)**:
- All state-holding modules use `always_ff @(posedge clk or negedge rst_n)` — **async active-low**
- Exception: `sisRegFile.sv` uses `always_ff @(posedge clk)` — **no reset** (intentional: reg file contents are architecturally undefined at reset; x0 is hardwired via combinational read logic)
- This is consistent and ASIC/DFT-friendly (no mixed sync/async issues)

**Exit criteria**: Yosys builds gate-level netlist ✅, $readmemh properly guarded ✅

---

### 🔲 Milestone 8 — OpenROAD hardening
**Status: NOT STARTED**

Planned:
- Sky130 PDK flow
- Core + AXI bridge only (RAM/ROM as blackboxes)
- GDS generation
- DRC/LVS (clean or documented deltas)

---

## Build & Verification Summary

| Metric | Value |
|--------|-------|
| Verilator version | 5.038 |
| Lint status | ✅ Clean (Wall, no warnings) |
| Compiler | riscv64-linux-gnu-gcc 13.3 |
| Assembly test suite | 25 tests |
| Assembly regression | 25/25 passing |
| cocotb unit tests | 40 tests (3 ALU + 4 RegFile + 10 Decode + 12 CSR + 11 AXI-Lite) |
| cocotb status | 40/40 passing |
| Formal proofs | ALU (all 10 ops), RegFile (x0=0), Decode (fields + legality), AXI-Lite (VALID stability + deadlock freedom) |
| Formal status | All proofs PASS |
| Simulation time | < 2s per test |
| Waveform format | FST |
| CI pipeline | GitHub Actions (lint, regress, cocotb, formal) |
| Synthesis | Yosys (make synth) |

## Files Implemented

### RTL (synthesizable)
- `rtl/sisPlatformTop.sv` — Top-level platform integration (USE_AXIL param switch)
- `rtl/core/sisRvCore.sv` — RV32I multi-cycle FSM CPU core (with interrupt support)
- `rtl/core/sisAlu.sv` — Arithmetic/Logic Unit
- `rtl/core/sisDecode.sv` — Instruction decoder
- `rtl/core/sisRegFile.sv` — 32-entry register file
- `rtl/core/sisCsr.sv` — M-mode CSR unit (with MTIP/irq_pending)
- `rtl/bus/sisMemFabric.sv` — Address decoder/bus router
- `rtl/bus/sisAxiLiteM.sv` — AXI4-Lite master bridge (with assertions)
- `rtl/periph/sisRom.sv` — ROM memory (synth-safe)
- `rtl/periph/sisRam.sv` — RAM memory with byte strobes (synth-safe)
- `rtl/periph/sisTimer.sv` — Machine timer (MTIME/MTIMECMP/MTIP)
- `rtl/periph/sisTohost.sv` — Pass/fail MMIO device

### Testbench
- `tb/verilator/main.cpp` — Verilator C++ harness
- `tb/models/sisAxiLiteSlave.sv` — AXI-Lite slave TB model (random stalls)
- `tb/cocotb/test_alu.py` — ALU cocotb tests (3 tests)
- `tb/cocotb/test_regfile.py` — RegFile cocotb tests (4 tests)
- `tb/cocotb/test_decode.py` — Decoder cocotb tests (10 tests)
- `tb/cocotb/test_csr.py` — CSR unit cocotb tests (12 tests)
- `tb/cocotb/test_axil_bridge.py` — AXI-Lite bridge cocotb tests (11 tests)

### Formal Verification
- `formal/alu_add.sv` — ALU proof wrapper (all 10 operations)
- `formal/alu_add.sby` — SymbiYosys config (ALU)
- `formal/alu_prove.ys` — Yosys SAT proof script (ALU)
- `formal/regfile_x0.sv` — RegFile x0 proof wrapper
- `formal/regfile_x0.sby` — SymbiYosys config (RegFile)
- `formal/decode_legal.sv` — Decoder proof wrapper (fields + legality)
- `formal/decode_prove.ys` — Yosys SAT proof script (Decoder)
- `formal/axil_master.sv` — AXI-Lite bridge proof wrapper (VALID stability, deadlock freedom)
- `formal/axil_master.sby` — SymbiYosys config (AXI-Lite bridge)

### Software
- `sw/bsp/crt0.S` — C runtime startup
- `sw/bsp/link.ld` — Linker script
- `sw/tests/asm/test_*.S` — 25 assembly test programs

### Build & CI
- `Makefile` — Build, lint, sim, regression, cocotb, formal, synth targets
- `.github/workflows/ci.yml` — CI pipeline (lint, regress, cocotb, formal)
- `scripts/yosys_synth.tcl` — Yosys synthesis script
