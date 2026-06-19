# Benchmarks — CoreMark and Dhrystone

**Date:** 2026-06-17
**Git commit:** `e76492047fd8b9d59ab7519fa35ff9bc15a72277`
**Simulator:** Verilator `build/sim_sisPlatformTop`, direct corebus ROM/RAM path
**Toolchain:** `riscv64-elf-gcc (GCC) 16.1.0`
**Compiler flags:** `-O2 -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -fno-builtin`
**Memory map:** ROM 64 KiB at `0x0000_0000`, RAM 256 KiB at `0x8000_0000`

These are internal, cycle-normalized Verilator measurements for the M6 pipeline
after the direct-corebus Harvard instruction/data split.
They are not certified EEMBC CoreMark submissions and should not be represented as
official benchmark submissions.

## Headline Results

| Benchmark | ISA / flags | Iterations | Cycles | Instret | Score | Cycles/iter | Inst/iter | CPI | Validation |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| CoreMark performance | `rv32imc_zicsr -O2` | 16 | 10,457,567 | n/a | **1.530 CoreMark/MHz** | 653,597.938 | n/a | n/a | PASS |
| CoreMark validation | `rv32imc_zicsr -O2` | 16 | 10,457,938 | n/a | 1.530 CoreMark/MHz | 653,621.125 | n/a | n/a | PASS |
| Dhrystone 2.1 | `rv32imc_zicsr -O2` | 1,741 | 2,084,055 | 882,702 | **0.475 DMIPS/MHz** | 1,197.044 | 507.009 | 2.360 | PASS |
| CoreMark performance | `rv32im_zicsr -O2` | 16 | 10,514,019 | n/a | **1.522 CoreMark/MHz** | 657,126.188 | n/a | n/a | PASS |
| CoreMark validation | `rv32im_zicsr -O2` | 16 | 10,531,431 | n/a | 1.519 CoreMark/MHz | 658,214.438 | n/a | n/a | PASS |
| Dhrystone 2.1 | `rv32im_zicsr -O2` | 1,712 | 2,035,645 | 867,999 | **0.478 DMIPS/MHz** | 1,189.044 | 507.008 | 2.345 | PASS |

CoreMark/MHz is computed as `iterations * 1,000,000 / cycles`.
Dhrystone DMIPS/MHz is computed as `iterations * 1,000,000 / cycles / 1757`.

## Analysis: M9 front end — 1-word buffer + pipelined prefetch

The IF stage gained two cooperating mechanisms (`rtl/core/sisRvCore.sv`):
1. a **1-word fetch buffer** (`fbuf_*`) — serves the second compressed halfword of a word with
   no bus round-trip;
2. a **sequential prefetch slot** (`pf_*`) — fetches the next word ahead on otherwise-idle
   I-bus cycles (the corebus slaves accept a new request the same cycle the previous response
   is consumed), so back-to-back word fetches no longer each pay the `IF_REQ → IF_WAIT` round
   trip. On a sequential advance the prefetched word is promoted into `fbuf` with no demand fetch.

Combined effect (vs. the pre-M9 baseline):

| Metric | baseline | +1-word buf | +prefetch (now) | `rv32im` now |
|---|---:|---:|---:|---:|
| `rv32imc` CoreMark/MHz | 1.264 | 1.462 | **1.530** | 1.522 |
| `rv32imc` Dhrystone DMIPS/MHz | 0.400 | 0.449 | **0.475** | 0.478 |
| `rv32imc` Dhrystone CPI | 2.804 | 2.497 | **2.360** | 2.345 |

**The prefetch lowers base CPI for *both* ISAs** (it hides fetch latency behind execute), so
unlike the 1-word buffer it is not `rv32im`-neutral — `rv32im` CoreMark improved 1.502 → 1.522,
CPI 2.396 → 2.345. Net result: **`rv32imc` (1.530) now slightly *exceeds* `rv32im` (1.522) on
CoreMark** — the C extension went from a ~19% throughput *cost* (pre-M9) to a net win, because
the density advantage is no longer paid for at the fetch bus. On the dense-compressed
microbench (`test_fetch_buffer_throughput`) a 32-instruction block dropped **49 → 33 cycles**
(~1.03 cycles/instruction; close to the 1-word/cycle fetch floor).

### Correctness

The prefetch is speculative and shares one single-outstanding I-bus with demand fetches
(demand has priority). Validated by the full **71-test directed regression on three bus paths**
(corebus, AXI4-Lite, AXI4-Lite with stalls), `pipeline-debug`, and the throughput guard.
Review surfaced and fixed a **PMP/prefetch hazard**: a prefetched word must be fetch-PMP-checked
against its *own* address, not the demand address — otherwise a sequential fall-through into a
no-execute region could run a denied instruction in U-mode. Fixed (`fetch_pmp_addr` selects the
prefetched address when a prefetch response lands) and guarded by `test_pmp_prefetch_x`, which
fails without the fix. The buffer and prefetch slot are both dropped on every redirect (and any
in-flight prefetch is discarded), so a hit is always same-privilege/same-memory.

### Remaining / not yet validated

**Fmax must be confirmed in CI STA** (`make sta-sky130`) — the prefetch adds a 2:1 mux on the
I-bus address and the prefetch address is a registered `fetch_pc + 1`, so the impact should be
small, but Sky130 timing is marginal (~4.55 MHz) and this has not been checked locally (no STA
tools in the dev environment). The 10k-seed lock-step co-sim (CI) is the functional backstop for
the speculative-fetch behavior.

## Reproducibility

```bash
PATH=/opt/homebrew/bin:/opt/homebrew/Cellar/riscv64-elf-gcc/16.1.0/bin:$PATH \
  make benchmark RV_PREFIX=riscv64-elf-
```

The runner writes raw logs and machine-readable results under `build/bench/`:

- `build/bench/summary.json`
- `build/bench/coremark/rv32imc_zicsr/performance.log`
- `build/bench/coremark/rv32imc_zicsr/validation.log`
- `build/bench/dhrystone/rv32imc_zicsr/dhrystone.log`
- Matching `rv32im_zicsr` logs for the comparison row

Two consecutive local publish runs produced identical cycle and iteration counts.

## Raw Output Excerpts

CoreMark `rv32imc_zicsr` performance run:

```text
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 10457567
Total time (secs): 10
Iterations       : 16
Compiler version : GCC 16.1.0
Compiler flags   : rv32imc_zicsr -mabi=ilp32 -O2
Memory location  : sisrv static RAM
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x0415
Correct operation validated. See readme.txt for run and reporting rules.
```

Dhrystone `rv32imc_zicsr` run:

```text
Dhrystone Benchmark, Version 2.1 (Language: C)
Execution starts, 1491 runs through Dhrystone
Execution ends
Validation        : PASS
SISRV_BENCH cycles=2120289
SISRV_BENCH instret=755952
SISRV_BENCH cycles_per_iteration=1422.058
SISRV_BENCH instructions_per_iteration=507.010
SISRV_BENCH cpi=2.804
SISRV_BENCH dhrystones_per_sec_per_mhz=703.206
SISRV_BENCH dmips_per_mhz=0.400
```

## Notes

- CoreMark sources are vendored from EEMBC CoreMark `v1.01`; project-specific port
  files live under `sw/bench/coremark/`.
- Dhrystone sources are vendored from Dhrystone C 2.1; project-specific wrapper code
  lives under `sw/bench/dhrystone/`.
- The headline path is direct corebus. AXI4-Lite bridge benchmark numbers are not
  published here.
- A bounded dual-slot/MEM-hold experiment passed directed regression but was not kept
  because it measured slower than the Harvard split on the current one-cycle RAM path.
  A future M9 pipeline should pair deeper overlap with a memory/WB structure that
  improves measured CPI, not just structural occupancy.
- During bring-up, the benchmark exposed and fixed an RV32C `C.SW`/`C.SWSP`
  decompression immediate bug. The directed regression is `test_compressed_mem`.
