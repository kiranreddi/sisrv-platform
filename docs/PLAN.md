# Project plan (ASIC-architect view)

Date: 2026-03-02

This plan is written to prevent the two common failure modes in CPU projects:
1) building RTL without a runnable system; 2) adding configurability before correctness.

Key principles:
- **Always runnable:** every milestone ends with an end-to-end program that deterministically passes/fails.
- **Core stays protocol-agnostic:** the core speaks a simple internal bus; bridges handle AXI complexity.
- **Small config surface at MVP:** add knobs only when tests prove stability.
- **Open-source flow only:** Verilator + riscv-gnu-toolchain + Yosys + OpenROAD (+ optional SymbiYosys).

---

## Milestone 0 — Repo bootstrap & golden sim flow (1–2 days)
### Objectives
- Create a deterministic Verilator simulation harness.
- Establish pass/fail mechanisms and basic wave dumping.
- Validate build system, directory layout, and regression plumbing.

### Deliverables
- `tb/verilator/` C++ harness drives clock/reset, loads ROM image, monitors `tohost`.
- Simple ROM + RAM simulation models (non-synth OK in TB).
- `sisTohost` MMIO device at `0x1000_0000` with defined PASS/FAIL protocol.
- `make sim`, `make wave`, `make regress` scaffolding.

### Exit criteria
- `make sim` completes in < 2s with a dummy “hello” test that writes PASS to `tohost`.
- Waveform dump created (`.fst` preferred).

### Risks / mitigations
- **Timeout hangs:** mandatory cycle limit + watchdog in harness.
- **Non-determinism:** fixed seed, stable reset deassert cycle.

---

## Milestone 1 — RV32I multi-cycle (FSM) core, end-to-end on internal bus (1–2 weeks)
### Objectives
- Implement a minimal, correct RV32I core using a multi-cycle FSM.
- Run a bare-metal test from ROM that reads/writes RAM and signals PASS via tohost.

### Scope
- ISA: RV32I subset to start, then complete RV32I within milestone.
- Privilege: no CSRs/traps yet (or a minimal illegal-instruction halt).
- Memory: aligned accesses only (trap/halt on misalign for MVP, documented).
- Internal bus: request/response (single outstanding transaction).

### Microarchitecture (recommended)
- States: FETCH -> DECODE -> EXECUTE -> MEM (optional) -> WB -> FETCH
- Branch/jump resolved in EXECUTE; PC update centralized.
- Regfile: synchronous write, combinational read, x0 hardwired to 0.

### Deliverables
- `rtl/core/sisRvCore.sv` (FSM core)
- `rtl/core/sisRegFile.sv`, `rtl/core/sisDecode.sv`, `rtl/core/sisAlu.sv`
- Directed assembly tests (`sw/tests/asm/`) for:
  - arithmetic/logical, shifts
  - branches/jumps
  - loads/stores (byte/half/word)
  - LUI/AUIPC
- Minimal C test (`sw/tests/c/`) + BSP (`sw/bsp/`)

### Exit criteria
- Tier-1 regression passes:
  - >= 30 asm tests
  - >= 2 C tests (memcpy, crc32, simple loop)
- Architectural invariants:
  - x0 always 0
  - PC word-aligned
  - loads/stores correct sign/zero extension

### Risks / mitigations
- **Decode bugs:** write per-instruction directed tests before “full suite”.
- **Load/store endianness:** add golden vectors, test byte lanes thoroughly.

---

## Milestone 2 — Minimal CSRs + traps (1 week)
### Objectives
- Add enough privileged machinery to handle traps predictably (M-mode only).
- Support CSR instructions and trap entry/return.

### Scope
- CSRs: `mstatus`, `mtvec`, `mepc`, `mcause`, `mtval`, `mscratch`
- Instructions: `ECALL`, `EBREAK` (optional), `MRET`
- CSR ops: `CSRRW/CSRRS/CSRRC` + immediate forms

### Deliverables
- `rtl/core/sisCsr.sv` + integration in core FSM
- Trap vector in `sw/bsp/crt0.S`
- Tests:
  - illegal instruction -> trap
  - ecall -> trap
  - mret returns to correct PC

### Exit criteria
- All trap tests pass; `mcause`/`mepc` match expected values.
- No regressions from Milestone 1 tests.

---

## Milestone 3 — AXI4-Lite master bridge: RTL complete, system integration incomplete
### Objectives
- Keep core internal bus unchanged; add an AXI4-Lite master bridge.
- Integrate with an AXI-Lite RAM model in TB, including randomized wait states.

### Scope (AXI profile)
- AXI4-Lite only (no bursts)
- Single outstanding read and single outstanding write
- In-order responses only
- Proper channel handshake compliance

### Deliverables
- ✅ `rtl/bus/sisAxiLiteM.sv` (corebus -> AXI-Lite)
- ✅ `tb/models/sisAxiLiteSlave.sv` — AXI-Lite slave model with independent per-channel stalls
- ✅ Synthesizable assertions (ifdef ASSERT): VALID stability, no simultaneous R/W
- ✅ `sisPlatformTop` parameter switch: `USE_AXIL=0` (corebus) / `USE_AXIL=1` (AXI-Lite)
- ✅ 11 cocotb bridge unit tests with random stall stress (100 txns)
- ✅ Formal proof: VALID stability, deadlock freedom, mutual exclusion, data stability (k-induction, depth 20)
- 🔲 Full regression (25 asm tests) through AXI path in CI
- 🔲 1000-seed randomized stall nightly

### Exit criteria
- ✅ AXI-Lite bridge lint-clean and unit-tested
- ✅ Random stall stress passes (100 txns per seed)
- ✅ Formal proof of handshake safety and deadlock freedom
- 🔲 All asm tests pass with AXI-Lite path enabled
- 🔲 1000 seeded runs pass without deadlock

### Risks / mitigations
- **Handshake deadlocks:** ✅ strict FSM + synthesizable assertions + formal proof
- **TB too forgiving:** ✅ independent per-channel LFSR stall injection on all 5 channels

---

## Milestone 4 — Timer interrupt (1–2 weeks)
### Objectives
- Add machine timer interrupt (MTIP) path.
- Demonstrate periodic interrupt execution with return to mainline.

### Scope
- CSRs: `mie`, `mip` bits for MTIP; `mstatus.MIE`
- Timer peripheral at MMIO, simple compare register

### Semantic decisions (documented)
- `mstatus.MIE/MPIE`: Full swap on trap entry (MIE→MPIE, MIE=0), restore on MRET (MPIE→MIE, MPIE=1)
- `mtvec`: **Direct mode only** (MODE=0); all traps go to same vector address
- Interrupt taken between instructions (at WB→FETCH transition)
- mcause: bit 31 = interrupt flag, code 7 = machine timer
- mepc: PC + 4 (return to next instruction after interrupted one)

### Deliverables
- ✅ `rtl/periph/sisTimer.sv` — MTIME (64-bit), MTIMECMP, MTIP output
- ✅ CSR: ext_mtip → mip.MTIP, irq_pending output
- ✅ Core: interrupt check in WB state
- ✅ `test_timer.S` — deterministic periodic interrupt test
- ✅ `test_mret_boundary.S` — exact resume point verification (no skipped/repeated instructions)
- ✅ cocotb test_csr_mtip_irq_pending
- Timer peripheral at MMIO, simple compare register

### Deliverables
- `rtl/periph/sisTimer.sv`
- BSP support + interrupt handler tests

### Exit criteria
- “tick” counter increments in handler; mainline continues; PASS if both counters match expected ranges.

---

## Milestone 5 — RV32M (mul/div) (1–2 weeks)
### Objectives
- Add M extension as a configurable feature knob: `ENABLE_M`.

### Scope
- Multiply: can be single-cycle or iterative.
- Divide: iterative (restoring/non-restoring) acceptable for MVP.

### Exit criteria
- Directed tests for MUL/MULH/MULHU/MULHSU/DIV/DIVU/REM/REMU pass.
- Random test with mixed I/M ops passes.

---

## Milestone 6 — Optional: 3-stage pipeline v1 (2–4 weeks)
### Objectives
- Improve performance while preserving ISA behavior and external interfaces.

### Approach
- Replace FSM core with 3-stage (F/D/EX+WB), while keeping:
  - internal corebus interface
  - CSR/trap semantics
- Hazards:
  - ALU forwarding
  - load-use stall
  - branch resolved in EX; flush F/D

### Exit criteria
- Regression suite unchanged; all previous tests pass.
- CPI measured on a small benchmark improves vs FSM baseline.

---

## Milestone 7 — ASIC synthesis readiness (Yosys) (1 week)
### Objectives
- Ensure synthesizable RTL is clean and timing/plausibility is understood.

### Deliverables
- ✅ `scripts/yosys_synth.tcl`
- ✅ `$readmemh` guarded with `ifndef SYNTHESIS`
- ✅ `make synth` target
- ✅ Reset strategy audit: consistent async active-low across all modules
- ✅ Sim-only construct audit: no $display/$readmemh/initial in synth path
- Lint-clean RTL:
  - no inferred latches
  - no combinational loops
  - reset strategy consistent (async active-low)
- Synthesis report: area, max frequency estimate (generic libs OK)

### Exit criteria
- ✅ Yosys synthesis script exists and synthesizes core + bridge
- ✅ Sim-only constructs properly guarded
- 🔲 Synthesis reports saved as CI artifacts

---

## Milestone 8 — OpenROAD hardening (Sky130 reference) (2–4 weeks)
### Objectives
- Produce GDS for core + bridge (mem/ROM blackboxed).

### Approach
- Harden core + AXI bridge only first (no RAM macros)
- Treat RAM/ROM as blackboxes (use known SRAM macros later)

### Deliverables
- OpenROAD flow scripts + constraints
- Floorplan, PnR, DRC/LVS (as far as open flow allows)
- Post-PnR netlist and SDF (if generated)

### Exit criteria
- GDS produced; DRC/LVS is clean or deltas are documented and understood.

---

## Verification strategy (mandatory discipline)
### Regression tiers
- Tier 1 (fast): directed asm tests (seconds)
- Tier 2: C tests + randomized wait states (minutes)
- Tier 3: random instruction streams + formal proofs (nightly)

### Never skip
- watchdog timeouts
- seed logging + reproducibility
- wave dumps on failure

---

## Definition of “configurable” (MVP-safe)
Add knobs only when tested:
- `ENABLE_M` (RV32M)
- `RESET_VECTOR`
- `MTVEC_BASE`
- later: caches, pipeline depth, PMP, debug

