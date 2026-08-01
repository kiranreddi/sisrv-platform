# Implementation Status

**Last updated**: 2026-07-31 (M8 OpenROAD Sky130 hardening)

## Summary

The sisrv-platform project implements a fully functional RV32IMAC RISC-V processor core
with M-mode CSRs, trap handling, **CLINT/PLIC interrupts**, **RISC-V Debug subset**,
GPIO, UART, HPM counters, and an AXI4-Lite master bridge.
The core is verified through **76** directed assembly regression tests, pipeline throughput/debug-step Verilator tests, **50** cocotb unit tests (ALU/RegFile/Decode/CSR/AXI/PMP),
required formal proofs (ALU/RegFile/Decode; optional AXI), **RISCOF rv32imac_zicsr ACT suite** I/M/C subset (**95/95** filtered tests in CI; A/PMP/privilege still excluded from the per-push lane), and
**10k-seed retired-instruction Spike lock-step co-sim** (rv32im profile) as a final gated CI lane.

| P0 closure snapshot (2026-06-15) | see below |
| U-mode + PMP (2026-06-16) | ✅ Complete | `ENABLE_U=1`, `PMP_ENTRIES=8`, `sisPmp.sv`, 25 new asm tests, cocotb PMP lane |
| Zihpm-style HPM counters (2026-06-23) | ✅ Complete | `mhpmcounter3..31`, `mhpmevent3..31`, U-mode `hpmcounter3..31` gating, directed asm coverage |

### P0 closure snapshot (2026-06-15)

| P0 item | Status | Evidence |
|---------|--------|----------|
| CLINT / PLIC | ✅ Complete | `sisClint.sv`, `sisPlic.sv`, `test_msip`, `test_timer`, `test_plic_irq` |
| C extension | ✅ Complete | `sisDecompress.sv`, `ENABLE_C`, `test_compressed`, **27/27 C ACT tests** |
| Debug / JTAG | ✅ Complete | `sisDm.sv`, `sisJtagDtm.sv`, halt/resume/step, abstract GPR → regfile, 2 HW triggers (exec/load/store breakpoints) |
| Product docs | ✅ Complete | `LICENSE`, Integration Guide, PRM, PPA datasheet |
| Benchmarks | ✅ Internal | CoreMark/Dhrystone direct-corebus report in `docs/BENCHMARKS.md` |
| PPA / STA | ✅ Sky130 HD | CI WNS **+10.887 ns**, TNS **0 ns**, estimated Fmax **~109.7 MHz** |
| RISCOF / co-sim | ✅ Gated | **95/95** I/M/C ACT subset green in latest short CI; **10k-seed** lock-step restored as final gated CI job with pinned Spike |

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
| `sisDecode.sv` | ✅ Done | All RV32I/RV32M instruction types decoded |
| `sisMemFabric.sv` | ✅ Done | Address decoder: ROM/RAM/MMIO routing |

**Test coverage** (76 directed regression tests plus pipeline throughput/debug tests, all passing):

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
| test_machine_counters | misa, ID CSRs, mcycle/minstret, mcountinhibit |
| test_ecall | ECALL trap + MRET return |
| test_ebreak | EBREAK trap (mcause=3) + MRET return |
| test_illegal | Illegal instruction trap (mcause=2) |
| test_fence | FENCE as NOP |
| test_trap_faults | Misaligned load/store/control-flow traps and instruction/load/store access faults |
| test_wfi | WFI legal no-op |
| test_back_to_back | Fibonacci, register file stress, data dependencies, loops |
| test_timer | Timer interrupt: MTIP, ISR counter, MRET return |
| test_mret_boundary | MRET exact resume point: no skipped/repeated instructions |
| test_gpio | GPIO MMIO: DATA, DIR, IN, SET, CLR registers |
| test_uart | UART MMIO: TXDATA, RXDATA, STATUS, CTRL, BAUDDIV, loopback |
| test_rv32m | MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU, divide-by-zero, signed overflow |

**Exit criteria**: 25 directed tests covering all instruction groups ✅,
x0 always 0 ✅, PC word-aligned ✅, correct sign/zero extension ✅

---

### ✅ Milestone 2 — Minimal CSRs + traps
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `sisCsr.sv` | ✅ Done | mstatus, misa, mtvec, mepc, mcause, mtval, mscratch, mie, mip, ID CSRs, counters |
| CSR instructions | ✅ Done | CSRRW, CSRRS, CSRRC + immediate forms |
| ECALL/EBREAK | ✅ Done | Trap entry with correct mcause |
| MRET | ✅ Done | Returns to mepc, restores MIE from MPIE |
| Trap tests | ✅ Done | test_ecall, test_ebreak, test_illegal, test_csr, test_csr_edge, test_trap_faults |

**Interrupt semantics (documented decisions)**:
- `mstatus.MIE` (bit 3): Global machine interrupt enable
- `mstatus.MPIE` (bit 7): Previous MIE saved on trap entry, restored on MRET
- `mtvec`: **Direct (MODE=0) and vectored (MODE=1)** — interrupt cause N → BASE+N×4
- Trap priority: synchronous exceptions checked first, then asynchronous interrupts between instructions

**Exit criteria**: Trap tests pass ✅, mcause/mepc match expected ✅, no regressions ✅

---

### ✅ Milestone 2.5 — Verification infrastructure
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| cocotb ALU tests | ✅ Done | 1000 directed + 1000 random + shift sweep (Verilator 5.050) |
| cocotb RegFile tests | ✅ Done | x0 zero, write/read all, isolation, 500 random cycles |
| cocotb Decode tests | ✅ Done | Type flags, illegal opcodes, immediates (I/S/U/B/J), register extraction, 1000 random |
| cocotb CSR tests | ✅ Done | Reset values, RW/RS/RC ops, trap entry, MRET, MEPC alignment, MTIP/irq_pending, ID CSRs, counters |
| cocotb AXI-Lite tests | ✅ Done | Reset, read/write, errors, stalls, random stress (100 txns), VALID stability |
| Formal ALU proof | ✅ Done | All 10 ops proven correct (yosys SAT, < 1s) |
| Formal RegFile proof | ✅ Done | x0-always-zero (k-induction, SymbiYosys + z3) |
| Formal Decode proof | ✅ Done | Field extraction, immediate invariants, legality consistency (yosys SAT) |
| Formal AXI-Lite check | Optional | Bounded VALID stability, mutual exclusion, data stability (`make formal-axil`) |
| cocotb PMP lane | ✅ Done | 7 tests in `tb/cocotb/test_pmp.py` (part of the 50-test suite) |
| CI pipeline | ✅ Done | GitHub Actions: lint, regress, cocotb (50), formal, synth, RISCOF, STA, OpenROAD harden, gated 10k co-sim (+ nightly/opt-in lanes) |

---

### ✅ Milestone 3 — AXI4-Lite master bridge
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `sisAxiLiteM.sv` | ✅ Done | Corebus → AXI4-Lite bridge, strict FSM |
| AXI4-Lite compliance | ✅ Done | Proper AR/R and AW+W/B handshake |
| Single outstanding | ✅ Done | One read OR one write at a time |
| Lint clean | ✅ Done | Verilator Wall clean |
| Synthesizable assertions | ✅ Done | VALID stability, no simultaneous R+W (ifdef ASSERT) |
| `USE_AXIL` param switch | ✅ Done | `sisPlatformTop`: 0=corebus, 1=AXI-Lite |
| AXI-Lite slave TB model | ✅ Done | `tb/models/sisAxiLiteSlave.sv` with independent per-channel stalls |
| AXI-Lite timer support | ✅ Done | `tb/models/sisAxiLiteSlave.sv` models MTIME/MTIMECMP and MTIP |
| AXI-Lite GPIO support | ✅ Done | `tb/models/sisAxiLiteSlave.sv` models DATA/DIR/IN/SET/CLR |
| AXI-Lite UART support | ✅ Done | `tb/models/sisAxiLiteSlave.sv` models TXDATA/RXDATA/STATUS/CTRL/BAUDDIV |
| AXI-Lite PLIC/CLINT support | ✅ Done | Inline PLIC + CLINT in `sisAxiLiteSlave.sv` (76/76 regress-axil) |
| AXI-Lite system regression | ✅ Done | `make regress-axil` runs all 76 regression assembly tests through the AXI path |
| cocotb bridge tests | ✅ Done | 11 tests: reset, R/W, errors, stalls, 100-txn random stress |
| 1000-seed stall nightly | ✅ Done | `make cocotb-axil-stall-nightly`; CI schedule / workflow_dispatch |
| Formal AXI-Lite bridge | Optional | Bounded VALID stability, mutual exclusion, data stability (`make formal-axil`) |

**Exit criteria**: Full regression suite passes through the AXI path ✅,
timer interrupt tests run with the AXI slave timer model ✅, CI covers `make regress-axil` ✅

---

### ✅ Milestone 4 — Timer interrupt
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| Timer path | ✅ Done via **CLINT** | `sisClint.sv` owns MTIME/MTIMECMP/MTIP; orphan `sisTimer.sv` removed |
| `sisGpio.sv` | ✅ Done | 32-bit DATA/DIR/IN/SET/CLR MMIO peripheral |
| `sisUart.sv` | ✅ Done | TXDATA/RXDATA/STATUS/CTRL/BAUDDIV MMIO peripheral |
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

### ✅ Milestone 5 — RV32M (mul/div)
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| `ENABLE_M` configuration knob | ✅ Done | `sisRvCore` and `sisDecode`, default enabled |
| RV32M decode | ✅ Done | OP-ALU-REG with funct7=1 |
| Multiply ops | ✅ Done | MUL/MULH/MULHSU/MULHU |
| Divide/remainder ops | ✅ Done | DIV/DIVU/REM/REMU with RISC-V edge cases |
| Directed regression | ✅ Done | test_rv32m covers multiply, divide, divide-by-zero, signed overflow |
| Disabled-mode legality | ✅ Done | Formal decoder wrapper proves RV32M illegal when `ENABLE_M=0` |

---

### ✅ Milestone 6 — 3-stage pipeline
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| IF/ID/EX-MEM + WB pipeline | ✅ Done | `sisRvCore` now has independent fetch, decode, execute/memory, WB/retire state, and direct-corebus Harvard I/D ports |
| Corebus owner arbitration | ✅ Done | One outstanding request per I/D port preserved; AXI compatibility path muxes them back to one outstanding request |
| Hazard controls | ✅ Done | EX/WB bypass/forwarding, load-use stall, branch/jump flush, trap/interrupt/mret flush |
| Interface preservation | ✅ Done | Corebus, AXI bridge contract, CSR/trap, interrupt, debug, compressed fetch, and DPI retire-log interfaces retained |
| Local validation | ✅ Done | `make lint`, `make regress`, `make regress-axil`, `make regress-axil-stall`, `make pipeline-debug` |
| Directed pipeline tests | ✅ Done | forwarding, load-use, branch/jump flush, trap flush, interrupt flush, throughput guard, debug halt/single-step |

---

### ✅ Post-M6 benchmark bring-up
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| CoreMark port | ✅ Done | EEMBC CoreMark `v1.01` vendored under `third_party/coremark`; project port in `sw/bench/coremark` |
| Dhrystone port | ✅ Done | Dhrystone C 2.1 vendored under `third_party/dhrystone`; project wrapper in `sw/bench/dhrystone` |
| Bare-metal BSP | ✅ Done | UART output, tohost pass/fail, 64-bit `mcycle`/`minstret`, minimal libc |
| Startup `.data` copy | ✅ Done | `crt0.S` copies initialized data from ROM LMA to RAM before `main` |
| Benchmark targets | ✅ Done | `make benchmark-coremark`, `make benchmark-dhrystone`, `make benchmark`, `make benchmark-smoke` |
| Headline result | ✅ Measured | `-O2`: `rv32imc_zicsr` 1.530 CoreMark/MHz, 0.475 DMIPS/MHz, CPI 2.360; `rv32im_zicsr` 1.522, 0.478, CPI 2.345 (M9 1-word fetch buffer + pipelined prefetch; `rv32imc` now edges out `rv32im`) |
| Determinism | ✅ Done | Two consecutive local publish runs matched cycle/iteration counts exactly |

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
| Synth report CI artifact | ✅ Done | `ppa-synth-report` uploaded from the `synth` job |

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

### ✅ Post-M6 ISA completions — Vectored mtvec + A extension
**Status: COMPLETE**

| Deliverable | Status | Notes |
|-------------|--------|-------|
| Vectored `mtvec` (MODE=1) | ✅ Done | BASE+cause×4 dispatch; exceptions always go to BASE; `test_vectored_mtvec` |
| A extension — LR.W/SC.W | ✅ Done | Single-hart reservation model; `lr_reservation_valid/addr`; cleared on any trap/interrupt |
| A extension — full AMO set | ✅ Done | AMOSWAP/ADD/XOR/AND/OR/MIN/MAX/MINU/MAXU; two-phase read-modify-write via `EX_AMO_STORE_REQ/WAIT` states |
| misa.A + misa reporting | ✅ Done | `sisCsr.sv` MISA_VALUE includes A extension; `test_machine_counters` updated |
| mepc 2-byte alignment | ✅ Fixed | `mepc` masked to `0xFFFFFFFE` (not `0xFFFFFFFC`) with C extension; required for MRET to compressed-instruction return addresses |
| Regression | ✅ 76/76 | All tests pass including atomics, U/PMP, triggers, and HPM counters |

---

### ✅ Milestone 8 — OpenROAD hardening
**Status: COMPLETE** (reference hardenable IP slice on Sky130 HD)

| Deliverable | Status | Notes |
|-------------|--------|-------|
| Harden top | ✅ Done | `rtl/asic/sisHardenTop.sv` — ALU + decode + regfile + decompress + AXI-Lite |
| Sky130 PDK fetch | ✅ Done | `scripts/fetch_sky130_pdk.sh` → `third_party/sky130hd/` |
| Yosys Sky130 synth | ✅ Done | `make synth-harden` |
| OpenROAD PnR | ✅ Done | `scripts/openroad_flow.tcl` — floorplan/place/CTS/route → DEF/SPEF/SDF |
| GDS stream-out | ✅ Done | Magic `scripts/magic_gds.tcl` (`make openroad-gds`) |
| DRC/LVS | ✅ Done | Magic DRC + optional KLayout; deltas in `docs/HARDENING.md` |
| Power report | ✅ Done | Vectorless OpenROAD `*_power.rpt` → PPA datasheet |
| Full `sisRvCore` GDS | 🔲 Deferred | Yosys SV frontend cannot parse CSR/PMP packed arrays / `int` casts yet |

**Exit criteria**: GDS produced ✅; DRC/LVS clean or deltas documented ✅ (`docs/HARDENING.md`)

---

## Build & Verification Summary

| Metric | Value |
|--------|-------|
| Verilator version | 5.050 |
| Lint status | ✅ Clean (Wall, no warnings) |
| Compiler | riscv64-linux-gnu-gcc 13.3 |
| Assembly regression suite | 76 tests |
| Assembly regression | 76/76 passing through corebus, AXI-Lite, and stalled AXI-Lite paths |
| Pipeline throughput guard | `make pipeline-throughput` passing on the direct corebus path |
| Benchmark smoke | `make benchmark-smoke` builds/runs reduced CoreMark + Dhrystone validation |
| Publish benchmark | `make benchmark` generates `build/bench/summary.json` and logs |
| cocotb unit tests | 50 tests (3 ALU + 4 RegFile + 11 Decode + 14 CSR + 11 AXI-Lite + 7 PMP) |
| cocotb status | 50/50 in CI job name / `@cocotb.test` count |
| Formal proofs/checks | Required: ALU (all 10 ops), RegFile (x0=0), Decode (fields + legality). Optional: AXI-Lite bounded safety (`make formal-axil`) |
| Formal status | All proofs PASS |
| Simulation time | < 2s per test |
| Waveform format | FST |
| CI pipeline | GitHub Actions: lint, regress (+AXI/stall/guards), cocotb (50), formal, synth (+artifact), benchmark-smoke, RISCOF ACT 95, STA (+artifact), OpenROAD harden (+artifact), gated 10k cosim; nightly/opt-in: stall-1000, ACT-full, imac+U/PMP cosim |
| Synthesis | Yosys (make synth); reports uploaded as CI artifacts |
| OpenROAD harden (M8) | `make harden` → Sky130 HD GDS/DEF/SDF for `sisHardenTop` (CI green on PR #4 / run 30611181758) |

## Files Implemented

### RTL (synthesizable)
- `rtl/sisPlatformTop.sv` — Top-level platform integration (USE_AXIL param switch)
- `rtl/core/sisRvCore.sv` — RV32IMAC in-order pipelined CPU core (M+U, PMP, interrupts, M9 fetch buffer/prefetch)
- `rtl/core/sisPmp.sv` — Physical memory protection matcher
- `rtl/asic/sisHardenTop.sv` — Sky130 hardenable datapath + AXI-Lite slice (M8)
- `rtl/core/sisAlu.sv` — Arithmetic/Logic Unit
- `rtl/core/sisDecode.sv` — Instruction decoder
- `rtl/core/sisRegFile.sv` — 32-entry register file
- `rtl/core/sisCsr.sv` — M-mode CSR unit (with MTIP/irq_pending)
- `rtl/bus/sisMemFabric.sv` — Address decoder/bus router
- `rtl/bus/sisAxiLiteM.sv` — AXI4-Lite master bridge (with assertions)
- `rtl/periph/sisRom.sv` — ROM memory (synth-safe)
- `rtl/periph/sisRam.sv` — RAM memory with byte strobes (synth-safe)
- `rtl/core/sisDecompress.sv` — RV32C decompressor
- `rtl/periph/sisClint.sv` — Core-local interruptor (MSIP/MTIP/MTIME)
- `rtl/periph/sisPlic.sv` — Platform-level interrupt controller
- `rtl/debug/sisDm.sv` — RISC-V Debug Module subset
- `rtl/debug/sisJtagDtm.sv` — JTAG DTM
- `rtl/periph/sisGpio.sv` — 32-bit GPIO MMIO peripheral
- `rtl/periph/sisUart.sv` — UART MMIO peripheral with loopback test mode
- `rtl/periph/sisTohost.sv` — Pass/fail MMIO device

### Testbench
- `tb/verilator/main.cpp` — Verilator C++ harness
- `tb/models/sisAxiLiteSlave.sv` — AXI-Lite slave TB model (random stalls)
- `tb/cocotb/test_alu.py` — ALU cocotb tests (3 tests)
- `tb/cocotb/test_regfile.py` — RegFile cocotb tests (4 tests)
- `tb/cocotb/test_decode.py` — Decoder cocotb tests (11 tests)
- `tb/cocotb/test_csr.py` — CSR unit cocotb tests (15 tests)
- `tb/cocotb/test_axil_bridge.py` — AXI-Lite bridge cocotb tests (11 tests)
- `tb/cocotb/test_pmp.py` — PMP matcher cocotb tests (7 tests)

### Formal Verification
- `formal/alu_add.sv` — ALU proof wrapper (all 10 operations)
- `formal/alu_add.sby` — SymbiYosys config (ALU)
- `formal/alu_prove.ys` — Yosys SAT proof script (ALU)
- `formal/regfile_x0.sv` — RegFile x0 proof wrapper
- `formal/regfile_x0.sby` — SymbiYosys config (RegFile)
- `formal/decode_legal.sv` — Decoder proof wrapper (fields + legality)
- `formal/decode_prove.ys` — Yosys SAT proof script (Decoder)
- `formal/axil_master.sv` — AXI-Lite bridge proof wrapper (VALID/data stability, mutual exclusion)
- `formal/axil_master.sby` — SymbiYosys config (AXI-Lite bridge)

### Software
- `sw/bsp/crt0.S` — C runtime startup
- `sw/bsp/link.ld` — Linker script
- `sw/tests/asm/test_*.S` — 76 regression assembly programs plus direct-corebus pipeline throughput guard

### Build & CI
- `Makefile` — Build, lint, sim, regression, cocotb, formal, synth targets
- `.github/workflows/ci.yml` — CI pipeline (lint, regress, cocotb 50, formal, synth, STA, OpenROAD harden, RISCOF, gated 10k cosim; nightly/opt-in lanes)
- `scripts/yosys_synth.tcl` — Yosys synthesis script
- `scripts/openroad_flow.tcl` / `scripts/magic_*.tcl` — M8 Sky130 harden path
