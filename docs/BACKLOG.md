# sisrv-platform — Engineering Backlog (handoff)

Prioritized, self-contained items for a cold agent. Each has **what / why / where / done-when**.
State as of: RV32IMACU + 8-region PMP, M9 fetch buffer + pipelined prefetch, 2 HW debug triggers,
Zihpm-style HPM counters.
Current branch validation covers lint and the 76-test regression on 3 bus paths. CI-only lanes
cover cocotb, formal, RISCOF I/M/C, Sky130 STA ~110 MHz / WNS +10.9 ns, 10k-seed Spike lock-step,
synth, and benchmark. `rv32imc`
CoreMark 1.530/MHz (edges out `rv32im`); Dhrystone CPI ~2.36.

Toolchain note: dev env has `riscv64-elf-` at `/opt/homebrew/bin`; run make with
`RV_PREFIX=riscv64-elf-`. No spike/riscof/yosys/openroad locally — those run in CI.

---

## P0 — Verification honesty (the green overstates coverage)

### B1. Re-enable full-ISA RISCOF compliance (A / PMP / privilege)
**Branch work:** `codex/compliance-lockstep` adds opt-in/nightly CI lanes for
`riscof-act-full`; the fast per-push ACT lane remains the I/M/C subset until the slow lane
is proven green and runtime-bounded.
**Why:** to keep CI under its 3 h timeout, the ACT filter was scoped to I/M/C only
(`verification/riscof/scripts/filter_act_testlist.py` excludes `/pmp/`, `/A/`, `/privilege/`).
So the advertised **IMACU + PMP** ISA is *not* compliance-signed-off — only directed tests cover it.
**Where:** `filter_act_testlist.py`, `.github/workflows/ci.yml` (`riscof-act` job), `verification/riscof/`.
**Approach:** the runtime blew up running spike + RTL over the full PMP/privilege/A suites. Bound it:
pin + cache the Spike build (it currently `git clone --depth 1` of unpinned HEAD — also a latent
liability), parallelize the run, and/or split A/PMP/privilege into a separate **nightly** CI job so
the per-push job stays fast. Then re-include those paths and fix any genuine failures.
**Done when:** A/PMP/privilege ACT runs green in CI (nightly or bounded), exclusions documented.

### B2. Extend Spike lock-step co-sim to rv32imac / U / PMP
**Branch work:** `codex/compliance-lockstep` adds selectable cosim profiles, including
`rv32imac-u-pmp`, and changes the RTL retire log to compare raw fetched instruction encodings so
compressed instructions can lock-step against Spike.
**Why:** lock-step (`verification/cosim/spike_lockstep.py`) was reverted to **rv32im** to get green;
it diverged on random imac/privilege programs (an edge case worth finding). Compressed/atomic/U/PMP
paths have no lock-step backstop.
**Where:** `verification/cosim/spike_lockstep.py` (program gen + spike `--isa`/`--priv`/`--pmpregions`).
**Approach:** needs local spike to iterate. Re-enable `-march=rv32imac` and `--priv=mu --pmpregions=8`,
reproduce the seed-16 divergence, root-cause (likely a compressed/atomic decode or a privilege/PMP
edge case), fix, confirm 10k green.
**Done when:** lock-step passes 10k seeds on rv32imac with U/PMP enabled.

### B3. Compliance/coverage for the new HW triggers
**Why:** triggers (Sdtrig) landed with directed tests only.
**Where:** `sw/tests/asm/test_trigger_*`, `verification/riscof/`.
**Done when:** Sdtrig ACT tests (or expanded directed coverage incl. priority vs other exceptions,
chained/edge cases) pass.

---

## P1 — Performance (CPI ~2.36; ideal ~1.3 for this class)

### B4. Profile where the CPI goes (do this before B5/B6)
**Why:** fetch is now hidden by the prefetch, so the remaining ~2.36 CPI is EX/MEM-bound
(loads/stores are 2-cycle, branch flush, mul/div multi-cycle) — but guessing wastes effort.
**Where:** add event counting (see B5) or instrument `tb/verilator/main.cpp` / the retire DPI.
**Done when:** a per-class cycle/CPI breakdown exists (ALU vs load vs store vs branch vs mul/div),
captured in `docs/BENCHMARKS.md`.

### B5. mhpmcounters (Zihpm) — `mhpmcounter3..31` + `mhpmevent3..31`
**Status:** ✅ Done on `codex/benchmark-bringup` (2026-06-23). RTL implements
`mhpmcounter3..31`, `mhpmevent3..31`, U-mode `hpmcounter3..31` access via `mcounteren`, and
directed coverage in `test_hpmcounters`.
**Why:** standard performance-monitoring CSRs; enables B4 *and* is a productization feature.
**Where:** `rtl/core/sisCsr.sv` (CSR file, mirrors mcycle/minstret), event wires from the core
(retire, load, store, branch-taken, mispredict-flush, stall). Gate U-access via `mcounteren`.
**Done when:** a directed test programs an event, runs a loop, reads the counter; `misa`/docs updated.

### B6. Smarter front end / branch handling (diminishing returns)
**Why:** remaining fetch/branch cycles. Options, smallest first: a 2-word prefetch buffer (closes
the rare branch-into-mid-word straddle — see `docs/M9_FETCH_BUFFER_PLAN.md` §3.6), then a tiny BTB or
static branch hint. Re-check STA after any front-end change.
**Done when:** measurable CoreMark/Dhrystone gain with `make sta-sky130` Fmax not regressed and
76+ regression + 10k cosim green.

---

## P1/P2 — Productization features (breadth)

### B7. Debug triggers — `action=1` (enter Debug Mode) + `dcsr`/`dpc`
**Why:** the trigger MVP only does action=0 (breakpoint exception). Real debuggers want a trigger to
**enter Debug Mode** and halt. Needs `dcsr`(0x7B0)/`dpc`(0x7B1) and debug-mode privilege, which the
core lacks. See `docs/DEBUG_TRIGGERS_PLAN.md` §1/§8.
**Done when:** a trigger with action=1 halts into the DM; OpenOCD/gdb HW breakpoint flow works.

### B8. CLIC / interrupt-latency improvements
**Why:** current CLINT/PLIC are non-vectored, non-preemptive. CLIC (vectored, prioritized,
preemptive) is expected for low-latency MCU IRQ.
**Where:** new `rtl/periph/sisClic.sv` + core trap/mtvec changes. Larger feature — plan first.

### B9. AXI4 full (bursts) — promote the AXI4-Lite bridge
**Why:** `rtl/bus/sisAxiLiteM.sv` is single-beat AXI4-Lite. Full AXI4 with bursts is expected for SoC
integration / cache line fills.
**Done when:** AXI4 burst master passes a protocol-compliance check; regress-axil-equivalent green.

### B10. Small instruction cache
**Why:** tightly-coupled ROM only; a direct-mapped I-cache enables larger/slower memories without
killing fetch throughput. Pairs with B9 (line fills over AXI4 bursts).

---

## P2 — Physical signoff & hygiene

### B11. OpenROAD GDS + DRC/LVS + power (Milestone 8)
**Why:** last productization milestone (`docs/status.md` M8 "not started"). STA already clean ~110 MHz.
**Done when:** GDS generated, DRC/LVS clean-or-documented, power numbers in the PPA datasheet.

### B12. Fix stale Fmax in docs  *(quick win)*
**Status:** ✅ Done on `codex/benchmark-bringup` (2026-06-23). Stale 4.55 MHz / negative-WNS
references were replaced with the latest Sky130 HD estimate.
**Why:** several docs still cite **4.55 MHz / WNS -199.946 ns** (`docs/INDUSTRY_COMPARISON.md`,
`docs/status.md`, `docs/PPA_DATASHEET.md`). The current CI STA is **~110 MHz, WNS +10.887 ns,
TNS 0**. Badly understates the core.
**Done when:** all Fmax/WNS/TNS references match the latest STA; note it's a Sky130 HD estimate.

### B13. Pin Spike in CI  *(reliability)*
**Status:** ✅ Done on `codex/benchmark-bringup` (2026-06-23). CI now pins Spike with
`SPIKE_REF=1280c3ca1ef0ce5ec95994cb9b7144f3ea2c655c` and caches the installed build.
**Why:** `.github/workflows/ci.yml` builds Spike from **unpinned HEAD** (`git clone --depth 1`). It
already drifted once (slower build). Pin a known-good rev (+ cache) for reproducible CI.

### B14. Land the HW-trigger commit
Commit `24726c7` (hardware debug triggers) is on `codex/benchmark-bringup`, not yet on `main`.
Decide branch/PR/merge; CI on main will validate STA + 10k cosim (both expected green — triggers are
reset-inert).

---

## Suggested order
B12 + B14 (quick) → **B5 → B4** (counters then profile) → **B1/B2** (compliance honesty) →
B6 (perf) → B7/B8/B9 (features) → B11 (physical). B1/B2 need spike locally; B11 needs OpenROAD.
