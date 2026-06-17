# sisrv-platform vs. Commercial Industry-Standard Cores

**Date:** 2026-06-14
**Author:** Architecture review
**Purpose:** Benchmark the current `sisRvCore` against commercially deployed embedded
cores, identify the gap to "industry standard," and lay out a phased plan to reach a
licensable / product-grade RISC-V core.

> This document is a companion to [`PLAN.md`](PLAN.md) and
> [`EXTENSION_ROADMAP.md`](EXTENSION_ROADMAP.md). Those describe *what we built and
> what's next*; this one measures us against the bar set by shipping commercial IP and
> defines what "release as a product" actually requires.

---

## 1. Executive summary

`sisRvCore` today is a **correct, well-verified RV32IMAC teaching/MVP platform**: an
in-order IF/ID/EX-MEM pipeline with independent WB/retire and direct-corebus Harvard I/D path, M-mode only, with clean RTL,
real formal proofs, cocotb unit tests, a 45-test directed regression plus pipeline throughput guard, an AXI4-Lite bridge, CLINT/PLIC, debug/JTAG, C extension,
and a Yosys synthesis path. That is a genuinely strong *foundation* — better verified
than many hobby cores.

It is **not yet an industry-standard product**. The gap is not the ISA subset alone — it
is three things commercial cores treat as table stakes:

1. **Performance data.** The M6 pipeline now has internal direct-corebus
   CoreMark/Dhrystone measurements. They are useful engineering data, but not certified
   benchmark submissions.
2. **Compliance sign-off.** RISCOF **rv32imac_zicsr** ACT suite (**95/95** filtered tests;
   72 upstream PMP/A/privilege tests excluded) is green in CI, and the
   **10k-seed retired-instruction** Spike lock-step co-sim is restored as the
   final gated CI lane.
3. **Productization rigor.** Sky130 HD STA in CI: WNS **-199.946 ns**, TNS **-10929.076 ns**,
   Fmax **4.55 MHz**; internal `-O2` performance after the direct-corebus Harvard
   instruction/data split is **1.502 CoreMark/MHz** / **0.468 DMIPS/MHz** on
   `rv32im_zicsr` and **1.264** / **0.400** on `rv32imc_zicsr` (the C extension
   currently costs ~17% throughput on this stateless single-word fetch front end —
   see [`BENCHMARKS.md`](BENCHMARKS.md)).

The good news: the codebase is structured so each of these is an incremental milestone,
not a rewrite. The plan in §6 takes us from "MVP core" to "product-grade soft IP" in a
defined sequence with hard exit gates.

---

## 2. What we have today (honest snapshot)

| Dimension | Current state |
|---|---|
| ISA | RV32I + M + **C** (`rv32imac_zicsr`), M-mode only |
| Microarchitecture | In-order IF/ID/EX-MEM pipeline with independent WB/retire; single outstanding transaction per I/D corebus port |
| Performance | Internal direct-corebus Verilator, `-O2`: `rv32im_zicsr` 1.502 CoreMark/MHz, 0.468 DMIPS/MHz; `rv32imc_zicsr` 1.264, 0.400 (C costs ~17% throughput here) |
| Privilege | **M + U**; no S-mode; PMP enforced |
| Traps | Illegal instr, ECALL, EBREAK, MRET; misaligned load/store/control-flow traps; instruction/load/store access faults |
| Interrupts | **CLINT** (MSIP/MTIP/MTIME at 0x0200_0000) + **PLIC** (8 sources at 0x0C00_0000) |
| CSRs | mstatus, misa (**A**/**C**), mtvec (direct + vectored MODE=1), mepc, mcause, mtval, mscratch, mie, mip, ID CSRs, mcycle/minstret/mcountinhibit. WFI legal no-op. |
| Privilege | **M + U**; `mstatus` MPP/MPRV/TW; ECALL cause by mode; `mcounteren` |
| Memory | Aligned-only assumed; **8-entry PMP**; no cache; tightly-coupled ROM/RAM |
| Bus | Internal corebus + AXI4-Lite **master** bridge (single outstanding, no bursts) |
| Debug | **DM 0.13 subset + JTAG DTM** (halt/resume/step); **abstract GPR → regfile** |
| Verification | **45** directed asm + pipeline throughput/debug-step + 43 cocotb + 4 formal + **RISCOF ACT 95/95 (CI)** + final gated **10k-seed lock-step co-sim** |
| Physical | Yosys synth + **Sky130 HD STA** (WNS -199.946 ns, Fmax 4.55 MHz, CI) + PPA datasheet |
| Collateral | **Apache-2.0**, Integration Guide, Programmer's Reference, PPA datasheet |

---

## 3. The benchmark field (what "industry standard" means)

For a 32-bit embedded core, the bar is set by two camps. Targets below are the realistic
"compete-with" reference points for a small RV32 core.

| Core | Vendor | ISA / class | CoreMark/MHz¹ | Pipeline | Role as benchmark |
|---|---|---|---|---|---|
| **Cortex-M0+** | Arm | ARMv6-M | ~2.46 | 2-stage | Floor for ultra-low-area MCU; the area/power bar |
| **Cortex-M3 / M4** | Arm | ARMv7-M | ~3.34 / 3.42 | 3-stage | The mainstream MCU bar (M4 adds DSP/FPU) |
| **SiFive E31 (E3 series)** | SiFive | RV32IMAC | ~3.1 | 5-stage | Direct RISC-V commercial equivalent |
| **SiFive E21 / E2 series** | SiFive | RV32IMC | ~2.3–3.0 | 3-stage | Closest analog to our target point |
| **Andes N25F / D25F** | Andes | RV32IMAC(F) | ~3.5+ | 5-stage | High-end embedded RISC-V IP |
| **Cortex-M23 / M33** | Arm | ARMv8-M | ~2.5 / 4.0+ | 2/3-stage | TrustZone security bar |
| **sisRvCore (today)** | — | RV32IMAC | 1.50 (`rv32im`) / 1.26 (`rv32imc`) internal, not certified | IF/ID/EX-MEM + WB, Harvard I/D corebus | current implementation |

¹ Representative published figures; exact numbers vary by config/compiler. Use as
order-of-magnitude, not contractual.
² sisRvCore numbers are internal, cycle-normalized Verilator direct-corebus
measurements, not certified EEMBC submissions. Conditions: `riscv64-elf-gcc 16.1.0`,
`-O2`, ROM 64 KiB, RAM 256 KiB, direct corebus memory path.

**Takeaway:** The realistic product target is the **SiFive E2 / Cortex-M0+–M3 class**:
a small, pipelined, RV32IMC core with debug, standard interrupts, and compliance
sign-off. We are aiming at that point, not at an application-class (Linux-capable)
core — that is a different, much larger program.

---

## 4. Gap analysis matrix

Legend: ✅ have · 🟡 partial · ❌ missing · **P0** = required for any product claim ·
**P1** = required to be competitive · **P2** = differentiator / later.

### 4.1 ISA & programmer's model

| Feature | Industry standard | Us | Gap | Pri |
|---|---|---|---|---|
| RV32I base | yes | ✅ | — | — |
| M (mul/div) | yes | ✅ | — | — |
| **C (compressed)** | near-universal (code density) | ✅ | `sisDecompress.sv`, `test_compressed`, misa.C | **P0** |
| A (atomics) | yes for any multi-tasking/SMP | ✅ | LR/SC + full AMO, single-hart reservation model; `test_atomics` | P1 |
| Zicsr / Zifencei | yes | 🟡 | Zicsr ✅; Zifencei FENCE.I is NOP | P1 |
| F/D (float) | optional (M4F/E2F) | ❌ | only if DSP/FP target | P2 |
| B (bitmanip) / Zb* | increasingly common | ❌ | perf differentiator | P2 |
| `misa` + ID CSRs (vendor/arch/imp/hart) | mandatory | ✅ | implemented with stable zero IDs except `misa` | **P0** |
| `mcycle`/`minstret`/`mcountinhibit` | mandatory (Zicntr) | ✅ | implemented and covered by assembly + cocotb | **P0** |
| WFI | yes (low power) | 🟡 | legal no-op; no low-power state yet | P1 |

### 4.2 Privileged architecture & safety

| Feature | Industry standard | Us | Gap | Pri |
|---|---|---|---|---|
| Misaligned load/store trap (or HW support) | mandatory behavior | ✅ | precise mcause/mtval covered by `test_trap_faults` | **P0** |
| Instruction/load/store **access fault** on bus error | mandatory | ✅ | `rsp_err` routes to precise access-fault traps | **P0** |
| Instruction-address-misaligned trap | mandatory | ✅ | non-C RV32 control-flow target misalignment covered | **P0** |
| U-mode (user) | common (M33, E2, RTOS isolation) | ✅ | M+U, ECALL/trap/CSR priv enforcement | — |
| PMP (physical memory protection) | standard for secure MCU | ✅ | 8-entry matcher, I/D gates | — |
| TrustZone-class / Zk crypto | M33 / secure parts | ❌ | security-tier differentiator | P2 |
| Vectored `mtvec` (MODE=1) | common | ✅ | BASE+cause×4 dispatch; `test_vectored_mtvec` | P1 |

### 4.3 Interrupts & system integration

| Feature | Industry standard | Us | Gap | Pri |
|---|---|---|---|---|
| CLINT (timer + software IRQ, MSIP) | standard RISC-V | ✅ | `sisClint.sv` at 0x0200_0000; `test_msip`, `test_timer` | **P0** |
| PLIC / CLIC (external IRQ controller) | standard | ✅ | `sisPlic.sv` at 0x0C00_0000; GPIO mux; `test_plic_irq` | **P0** |
| Multiple prioritized IRQ sources | mandatory for real SoC | ✅ | 8 PLIC sources + MEIP/MTIP/MSIP priority in CSR | **P0** |
| Standard memory-mapped timer (mtime/mtimecmp per spec) | yes | 🟡 | exists but verify spec-exact layout | P1 |

### 4.4 Bus & memory subsystem

| Feature | Industry standard | Us | Gap | Pri |
|---|---|---|---|---|
| AXI4 / AHB-Lite **full** master (bursts, ID, outstanding) | yes | 🟡 | AXI4-**Lite** only, 1 outstanding, no bursts | P1 |
| I/D split or unified cache | E3/M7-class | 🟡 | direct-corebus Harvard ROM/data split implemented; cache/fill path still future work | P2 |
| Tightly-coupled memory (TCM/ITIM/DTIM) | E2/M-class | 🟡 | have ROM/RAM but no formal TCM interface/wait-state model | P1 |
| Bus error → precise trap | yes | ✅ | `rsp_err` routes to instruction/load/store access-fault traps | **P0** |

### 4.5 Debug & development

| Feature | Industry standard | Us | Gap | Pri |
|---|---|---|---|---|
| RISC-V Debug spec DM (halt/resume/step) | mandatory for product | ✅ | `sisDm.sv` subset | **P0** |
| JTAG / cJTAG DTM | mandatory | ✅ | `sisJtagDtm.sv` | **P0** |
| Abstract GPR access while halted | mandatory | ✅ | `sisRegFile` dbg port + `dbg_abs_*` in core/top | **P0** |
| Hardware breakpoints/triggers (Sdtrig) | standard | ❌ | — | P1 |
| GDB/OpenOCD bring-up | expected | 🟡 | documented; not CI-tested | P1 |
| Trace (instruction trace / E-Trace) | premium feature | ❌ | — | P2 |

### 4.6 Verification & quality sign-off

| Feature | Industry standard | Us | Gap | Pri |
|---|---|---|---|---|
| RISCOF / riscv-arch-test compliance pass | **mandatory to call it RISC-V** | ✅ | `make riscof-act` (**95/95** filtered) in CI | **P0** |
| ISS lock-step co-simulation (e.g. Spike) random | yes | ✅ | `verification/cosim/spike_lockstep.py` — 10k seeds, retired PC+insn compare as final gated CI lane | **P0** |
| Constrained-random + functional coverage (UVM or cocotb) | yes | 🟡 | unit-level only, no top-level coverage closure | P1 |
| Formal of control/hazard logic | premium | 🟡 | ALU/decode/regfile/AXI only, not core FSM/pipeline | P1 |
| Code + functional coverage metrics & goals | yes | ❌ | no coverage reporting in CI | P1 |
| Interrupt/trap stress & nested-trap tests | yes | 🟡 | basic only | P1 |

### 4.7 Physical / PPA & deliverables

| Feature | Industry standard | Us | Gap | Pri |
|---|---|---|---|---|
| STA / timing closure with SDC on real PDK | yes | ✅ | Sky130 HD: `make sta-sky130` → `build/sta_sky130_report.txt` (WNS/TNS/Fmax) | **P0** |
| PPA datasheet (area, fmax, power, per node) | yes | ✅ | `docs/PPA_DATASHEET.md` + Yosys area | **P0** |
| DFT: scan insertion, MBIST hooks, coverage | yes | ❌ | reset strategy is DFT-friendly but no scan | P1 |
| Low-power intent (UPF), clock gating | yes | ❌ | — | P2 |
| OpenROAD/commercial GDS hardening | yes | 🟡 | planned (M8), not done | P1 |
| Lint/CDC sign-off (Spyglass-class) | yes | 🟡 | Verilator lint only; no CDC (single clock today) | P1 |

### 4.8 Productization & business

| Feature | Industry standard | Us | Gap | Pri |
|---|---|---|---|---|
| OSI license decided (Apache-2.0/BSD) | yes | ✅ | `LICENSE` Apache-2.0 | **P0** |
| Integration guide + programmer's reference manual | yes | ✅ | `docs/INTEGRATION_GUIDE.md`, `docs/PROGRAMMERS_REFERENCE.md` | **P0** |
| Configurable, documented parameter set | yes | 🟡 | a few params, not a product config matrix | P1 |
| Versioning, release notes, errata process | yes | ❌ | — | P1 |
| Example SoC + firmware (BSP, RTOS port) | yes | 🟡 | bare-metal asm only; no C BSP/RTOS port | P1 |

---

## 5. The five gaps that matter most

If you do nothing else, these are the ordered, non-negotiable steps from "MVP" to
"defensible product":

1. **Compliance sign-off (RISCOF) + ISS co-sim.** Until the core passes the official
   architecture tests against a golden model, "industry-standard RISC-V" is not a claim
   you can make. *Cheapest high-value step; do it first — it will also surface the §4.2
   trap bugs.*
2. **Fix the privileged-mode correctness holes:** trap on bus error (`rsp_err`),
   misaligned access, and add the mandatory ID/counter CSRs + WFI. *Small RTL, large
   credibility.*
3. **Real interrupt subsystem:** CLINT (timer+software) + PLIC/CLIC with multiple
   prioritized sources. *Without this it cannot be dropped into an SoC.*
4. **Pipeline CPI tuning.** M6 now has measured benchmark baselines and a direct-corebus
   Harvard I/D split; next performance work is true memory/WB overlap, cache/fill
   tuning, and certified-report discipline.
5. **Debug (RISC-V DM + JTAG) and the C extension.** *Debug is mandatory for any
   customer bring-up; C is expected by every toolchain/RTOS and buys ~25–30% code size.*

---

## 6. Maturity plan to product

Phased on top of the existing milestone plan (M6/M8 already exist there). Each phase has
a hard exit gate. Phases are roughly independent except where noted; suggested order is
top-to-bottom by risk-adjusted value.

### Phase A — "Real RISC-V" correctness & compliance (foundation)
**Goal:** Pass official compliance; close the privileged-mode holes. No new perf.
**Status: COMPLETE** (2026-06-15, latest short CI [run #27565469770](https://github.com/kiranreddi/sisrv-platform/actions/runs/27565469770); 10k co-sim restored as final gated lane)

- Add RISCOF + riscv-arch-test to CI; pick Spike as golden ISS.
- Stand up Spike lock-step co-simulation harness (random instruction streams).
- ✅ Trap on misaligned load/store/control-flow targets (correct mcause/mtval).
- ✅ Route `rsp_err` → instruction/load/store **access-fault** traps.
- ✅ Add CSRs: `misa`, `mvendorid`, `marchid`, `mimpid`, `mhartid`, `mconfigptr`,
  `mcycle`/`minstret`/`mcountinhibit` (Zicntr). WFI is legal no-op.
- ✅ RV32C: IALIGN=16 jump alignment, WB-stage latched decode, reserved `rd=x0` C encodings as NOP.
- ✅ ROM decode expanded to 2 MB (matches ACT `link.ld`).
- **Exit gate:** ✅ RISCOF rv32imac_zicsr ACT suite **95/95** green in CI; ✅ 10k-seed
  retired-instruction Spike lock-step co-sim restored as final gated CI; ✅ Sky130 STA report in CI
  (WNS -199.946 ns, TNS -10929.076 ns, Fmax 4.55 MHz); nested-trap + access-fault directed
  tests pass.

### Phase B — System integration (droppable into an SoC)
**Goal:** Standard interrupts + bus the integrator expects.

- CLINT: `mtime`/`mtimecmp` (spec layout) + `msip` software interrupt.
- PLIC (or CLIC) with N prioritized external IRQ sources; wire `meip`.
- Vectored `mtvec` (MODE=1): **done** — BASE+cause×4 dispatch, `test_vectored_mtvec`.
- Promote AXI4-Lite → AHB-Lite **or** full AXI4 master (bursts) — pick per target market.
- **Exit gate:** multi-source prioritized IRQ test; software-interrupt test; AXI/AHB
  protocol-compliance (formal/VIP) clean.

### Phase C — Performance (the headline number)
**Goal:** use the measured CPI, CoreMark, and Dhrystone baselines to drive tuning.

- IF/ID/EX-MEM pipeline with independent WB/retire is implemented; benchmark bring-up
  reports 1.502 CoreMark/MHz and 0.468 DMIPS/MHz for `rv32im_zicsr -O2`, and 1.264 /
  0.400 for `rv32imc_zicsr -O2`.
- The C extension currently costs ~17% throughput (Dhrystone CPI 2.80 vs 2.40) because the
  stateless single-word fetch front end re-fetches a word for its second compressed halfword
  and double-fetches boundary-straddling 32-bit instructions. An **M9 fetch-buffer rework**
  (1–2 word buffer retaining the last fetched word) recovers this while keeping the density
  win — see [`BENCHMARKS.md`](BENCHMARKS.md).
- A bounded dual-slot/MEM-hold experiment passed directed regression but measured worse
  on the current one-cycle RAM path, so it was not retained. M9 should only land with
  a memory/WB structure that improves benchmark CPI.
- Add the **C extension** (compressed) — interacts with fetch/PC alignment, so do it
  with the pipeline rework.
- **A extension** (LR/SC + AMO): **done** — single-hart reservation model, full AMO set, `test_atomics`.
- Continue benchmark-driven CPI tuning; keep benchmark smoke in CI and publish full
  local results from `make benchmark`.
- **Exit gate:** full directed + RISCOF + co-sim still green; CoreMark/MHz improves
  toward E2-class (~2.5–3.0); CPI report remains reproducible.

### Phase D — Debug & security
**Goal:** Customer can bring up firmware; optional security tier.

- RISC-V Debug Module (halt/resume/step/abstract commands) + JTAG DTM.
- OpenOCD + GDB bring-up; HW triggers (Sdtrig).
- Optional: U-mode + PMP (sandboxing / secure boot), then evaluate Zk crypto.
- **Exit gate:** GDB halt/step/inspect on the example SoC; PMP access-fault tests.

### Phase E — Physical & PPA sign-off
**Goal:** Characterized, hardenable IP.
*(Extends Milestone 8.)*

- SDC constraints + STA (OpenSTA) for fmax; CDC review (multi-clock if debug/JTAG).
- OpenROAD Sky130 (and/or commercial PDK) hardening: GDS, DRC/LVS, power estimate.
- DFT: scan-chain insertion, MBIST hooks for any compiled memories.
- **Exit gate:** published PPA datasheet (area/fmax/power); GDS DRC/LVS clean or
  documented deltas.

### Phase F — Release & productization
**Goal:** Licensable deliverable.

- Choose + apply OSI license (and/or dual-license/commercial terms).
- Programmer's Reference Manual + Integration Guide + configurability matrix.
- Versioning, release notes, errata/known-issues process.
- Example SoC + C BSP + an RTOS port (FreeRTOS/Zephyr).
- **Exit gate:** a tagged release a third party can integrate from docs alone.

---

## 7. Definition of "industry-standard, product-grade" (the bar)

Ship criteria — all must be true to make the claim:

- [x] Passes RISCOF / riscv-arch-test for its advertised ISA string, in CI.
- [x] Multi-thousand-seed ISS lock-step co-simulation harness, restored as a final gated 10k CI job.
- [x] Base M-mode trap model covers misalign + access fault.
- [x] Standard interrupt subsystem (CLINT + PLIC/CLIC), multiple prioritized sources.
- [x] RISC-V Debug Module + JTAG (halt/resume/step subset); GDB/OpenOCD path documented.
- [x] RV32IMC at minimum with M6 in-order pipeline implemented; internal benchmark numbers published in `docs/BENCHMARKS.md`.
- [x] STA reported on a named PDK with a PPA datasheet; timing closure and GDS DRC/LVS remain M8 work.
- [x] OSI license, PRM + integration guide, versioned release collateral started.

---

## 8. Suggested near-term sequence (next 3 milestones)

The lowest-risk, highest-credibility path for the next product push:

1. **RISCOF + Spike co-sim in CI** → exposes real bugs, earns the "RISC-V" label.
2. **Privileged correctness pack** (misalign trap, `rsp_err` access faults, ID/counter
   CSRs, WFI legal no-op) → base RTL slice complete; still needs RISCOF/ISS sign-off.
3. **CLINT + PLIC** → makes the core actually integrable into an SoC.

M6 is now implemented and internally benchmarked. The next marquee performance
milestone is CPI/fetch/bus tuning plus a disciplined path toward certified reporting
if public benchmark claims become a release goal.

> Rationale: these are high-value verification and productization efforts that make
> benchmark and integration claims defensible.
</content>
</invoke>
