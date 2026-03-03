# Implementation Status

**Last updated**: 2026-03-03

## Summary

The sisrv-platform project implements a fully functional RV32I RISC-V processor core
with M-mode CSRs and trap handling. The core is verified through 23 directed assembly
tests, 28 cocotb randomized unit tests, and 3 formal proofs — all running on Verilator 5.038.

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

**Test coverage** (23 directed tests, all passing):

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

**Exit criteria**: 23 directed tests covering all instruction groups ✅,
x0 always 0 ✅, PC word-aligned ✅, correct sign/zero extension ✅

---

### ✅ Milestone 2 — Minimal CSRs + traps
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `sisCsr.sv` | ✅ Done | mstatus, mtvec, mepc, mcause, mtval, mscratch, mie, mip |
| CSR instructions | ✅ Done | CSRRW, CSRRS, CSRRC + immediate forms |
| ECALL/EBREAK | ✅ Done | Trap entry with correct mcause |
| MRET | ✅ Done | Returns to mepc |
| Trap tests | ✅ Done | test_ecall, test_ebreak, test_illegal, test_csr, test_csr_edge |

**Exit criteria**: Trap tests pass ✅, mcause/mepc match expected ✅, no regressions ✅

---

### ✅ Milestone 2.5 — Verification infrastructure
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| cocotb ALU tests | ✅ Done | 1000 directed + 1000 random + shift sweep (Verilator 5.038) |
| cocotb RegFile tests | ✅ Done | x0 zero, write/read all, isolation, 500 random cycles |
| cocotb Decode tests | ✅ Done | Type flags, illegal opcodes, immediates (I/S/U/B/J), register extraction, 1000 random |
| cocotb CSR tests | ✅ Done | Reset values, RW/RS/RC ops, trap entry, MRET, MEPC alignment, outputs |
| Formal ALU proof | ✅ Done | All 10 ops proven correct (yosys SAT, < 1s) |
| Formal RegFile proof | ✅ Done | x0-always-zero (k-induction, SymbiYosys + z3) |
| Formal Decode proof | ✅ Done | Field extraction, immediate invariants, legality consistency (yosys SAT) |
| CI pipeline | ✅ Done | GitHub Actions: lint, regress, cocotb, formal |

---

### ✅ Milestone 3 — AXI4-Lite master bridge
**Status: RTL COMPLETE** (not integrated in default platform path)

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `sisAxiLiteM.sv` | ✅ Done | Corebus → AXI4-Lite bridge, strict FSM |
| AXI4-Lite compliance | ✅ Done | Proper AR/R and AW+W/B handshake |
| Single outstanding | ✅ Done | One read OR one write at a time |
| Lint clean | ✅ Done | Verilator Wall clean |

The AXI4-Lite bridge is implemented and lint-clean but not yet integrated
into the default platform interconnect (platform uses direct corebus routing).

---

### 🔲 Milestone 4 — Timer interrupt
**Status: NOT STARTED**

Planned:
- `rtl/periph/sisTimer.sv` — MTIME/MTIMECMP registers
- MTIP interrupt path through mie/mip/mstatus
- Interrupt handler test

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

### 🔲 Milestone 7 — Yosys synthesis
**Status: NOT STARTED**

Planned:
- Yosys synthesis script
- Area/timing report

---

### 🔲 Milestone 8 — OpenROAD hardening
**Status: NOT STARTED**

Planned:
- Sky130 PDK flow
- GDS generation

---

## Build & Verification Summary

| Metric | Value |
|--------|-------|
| Verilator version | 5.038 |
| Lint status | ✅ Clean (Wall, no warnings) |
| Compiler | riscv64-linux-gnu-gcc 13.3 |
| Assembly test suite | 23 tests |
| Assembly regression | 23/23 passing |
| cocotb unit tests | 28 tests (3 ALU + 4 RegFile + 10 Decode + 11 CSR) |
| cocotb status | 28/28 passing |
| Formal proofs | ALU (all 10 ops), RegFile (x0=0), Decode (fields + legality) |
| Formal status | All proofs PASS |
| Simulation time | < 2s per test |
| Waveform format | FST |
| CI pipeline | GitHub Actions (lint, regress, cocotb, formal) |

## Files Implemented

### RTL (synthesizable)
- `rtl/sisPlatformTop.sv` — Top-level platform integration
- `rtl/core/sisRvCore.sv` — RV32I multi-cycle FSM CPU core
- `rtl/core/sisAlu.sv` — Arithmetic/Logic Unit
- `rtl/core/sisDecode.sv` — Instruction decoder
- `rtl/core/sisRegFile.sv` — 32-entry register file
- `rtl/core/sisCsr.sv` — M-mode CSR unit
- `rtl/bus/sisMemFabric.sv` — Address decoder/bus router
- `rtl/bus/sisAxiLiteM.sv` — AXI4-Lite master bridge
- `rtl/periph/sisRom.sv` — ROM memory
- `rtl/periph/sisRam.sv` — RAM memory with byte strobes
- `rtl/periph/sisTohost.sv` — Pass/fail MMIO device

### Testbench
- `tb/verilator/main.cpp` — Verilator C++ harness
- `tb/cocotb/test_alu.py` — ALU cocotb tests (3 tests)
- `tb/cocotb/test_regfile.py` — RegFile cocotb tests (4 tests)
- `tb/cocotb/test_decode.py` — Decoder cocotb tests (10 tests)
- `tb/cocotb/test_csr.py` — CSR unit cocotb tests (11 tests)

### Formal Verification
- `formal/alu_add.sv` — ALU proof wrapper (all 10 operations)
- `formal/alu_add.sby` — SymbiYosys config (ALU)
- `formal/alu_prove.ys` — Yosys SAT proof script (ALU)
- `formal/regfile_x0.sv` — RegFile x0 proof wrapper
- `formal/regfile_x0.sby` — SymbiYosys config (RegFile)
- `formal/decode_legal.sv` — Decoder proof wrapper (fields + legality)
- `formal/decode_prove.ys` — Yosys SAT proof script (Decoder)

### Software
- `sw/bsp/crt0.S` — C runtime startup
- `sw/bsp/link.ld` — Linker script
- `sw/tests/asm/test_*.S` — 23 assembly test programs

### Build & CI
- `Makefile` — Build, lint, sim, regression, cocotb, formal targets
- `.github/workflows/ci.yml` — CI pipeline (lint, regress, cocotb, formal)
