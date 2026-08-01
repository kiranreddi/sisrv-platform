# UVM / Coverage Verification Plan (locked)

Canonical identity: **Kiran Tathekalva** `<kiranreddi.t@gmail.com>`.  
No `Co-authored-by` trailers. See `AGENTS.md`.

## Decisions (locked)

| Topic | Decision |
|-------|----------|
| CI gate | **Verilator + cocotb only** |
| SV UVM | **Commercial / LSF only** — wraps `tb/sv/sisTbTop.sv`; never a PR gate |
| Functional coverage on Verilator | **Python-side bins** (+ later SVA `cover`); no SV `covergroup` (unsupported) |
| Code coverage | Verilator `--coverage` (line/toggle); informational until floors measured |
| L0 agent rebuild | **Skip** where formal+cocotb already close; **Decompress only** |
| Phase 1 priority | **B2 lock-step imac+U/PMP** → Decompress TB → SVA → coverage baseline |
| JTAG/DM | Phase 2 (second), not first |
| Bugs | GitHub Issues |
| `sisTimer` | **Deleted** (orphan; CLINT owns MTIME/MTIMECMP) |
| SV TB source of truth | `tb/sv/sisTbTop.sv` |

## Baseline (current `main`)

- Verilator **v5.050**, cocotb **2.0.1**
- 50 unit cocotb (ALU/RegFile/Decode/CSR/AXI/PMP) + Decompress (this work)
- 78 asm sources / 76 regress; RISCOF 95 I/M/C; lock-step per-push **rv32im**
- No coverage metrics in CI yet
- Opt-in/nightly already has `cosim-lockstep-imac-upmp` (10k)

## Phases

### Phase 0 — Foundations
- This document; delete `sisTimer`; fix stale status/PLAN; enable `-DASSERT` in Verilator sims.
- Scaffold coverage targets; declare fcov = Python bins.

### Phase 1 — Highest bug yield *(this branch)*
1. **B2 smoke in CI:** per-push `rv32imac-u-pmp` lock-step on a **bounded seed window** (triage seed-16 class failures); keep 10k on nightly.
2. **Decompress** cocotb unit TB + Python fcov counters.
3. **SVA pass:** MemFabric one-hot/decode + keep AXI asserts; enable `ASSERT` in sim builds.
4. **Coverage baseline:** informational CI artifact from unit decompress (+ existing unit suite when cheap).

### Phase 2 — Debug + platform stitch
- JTAG/DMI sequences; platform cocotb around `sisPlatformTop`.
- Commercial UVM env wrapping `sisTbTop` (LSF).

### Phase 3 — Coverage gates
- Floors from measured baselines only; then PR gates.

## Non-goals (until explicit)

- Full Accellera UVM as GitHub CI gate
- Rebuilding UVM agents for ALU/RegFile/Decode already closed by formal+cocotb
- Full-`sisRvCore` GDS TB
- EEMBC-certified numbers
