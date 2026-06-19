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
| CoreMark performance | `rv32imc_zicsr -O2` | 15 | 10,258,078 | n/a | **1.462 CoreMark/MHz** | 683,871.867 | n/a | n/a | PASS |
| CoreMark validation | `rv32imc_zicsr -O2` | 15 | 10,264,469 | n/a | 1.461 CoreMark/MHz | 684,297.933 | n/a | n/a | PASS |
| Dhrystone 2.1 | `rv32imc_zicsr -O2` | 1,648 | 2,086,448 | 835,551 | **0.449 DMIPS/MHz** | 1,266.048 | 507.009 | 2.497 | PASS |
| CoreMark performance | `rv32im_zicsr -O2` | 16 | 10,655,909 | n/a | **1.502 CoreMark/MHz** | 665,994.313 | n/a | n/a | PASS |
| CoreMark validation | `rv32im_zicsr -O2` | 16 | 10,675,445 | n/a | 1.499 CoreMark/MHz | 667,215.313 | n/a | n/a | PASS |
| Dhrystone 2.1 | `rv32im_zicsr -O2` | 1,675 | 2,035,202 | 849,240 | **0.468 DMIPS/MHz** | 1,215.045 | 507.008 | 2.396 | PASS |

CoreMark/MHz is computed as `iterations * 1,000,000 / cycles`.
Dhrystone DMIPS/MHz is computed as `iterations * 1,000,000 / cycles / 1757`.

## Analysis: M9 fetch buffer — most of the C-extension cost recovered

A **1-word instruction fetch buffer** (`rtl/core/sisRvCore.sv`, `fbuf_*`) was added to the IF
stage. It retains the last fetched word so the second compressed halfword of a word — and the
resident low half of a sequential straddling 32-bit instruction — are served with no bus
round-trip. The effect on `rv32imc`:

| Metric | `rv32imc` before | `rv32imc` after | `rv32im` (target) | Gap closed |
|---|---:|---:|---:|---:|
| CoreMark/MHz | 1.264 | **1.462** | 1.502 | **~84%** |
| Dhrystone DMIPS/MHz | 0.400 | **0.449** | 0.468 | **~72%** |
| Dhrystone CPI | 2.804 | **2.497** | 2.396 | **~75%** |
| Dhrystone cycles/iter | 1,422 | **1,266** | 1,215 | — |

**`rv32im` is byte-identical before and after** (1.5015 CoreMark/MHz, 0.468 DMIPS/MHz, 1,215
cycles/iter, same cycle counts) — the buffer is filled but never hit for all-aligned 32-bit
code, so it is a pure front-end win with zero collateral change.

### What the buffer removes

The IF FSM (`IF_REQ → IF_WAIT → IF_SECOND_REQ → IF_SECOND_WAIT`) previously issued one
**word-aligned** bus fetch per instruction with no state retained. Compressed code paid two
costs `rv32im` never pays:

1. **Word re-fetch for the second halfword** — two 16-bit instructions in a word used to cost
   two bus fetches (the second re-requesting a word already fetched). The buffer now serves
   the upper halfword from `fbuf_data` with no bus access. *This is the dominant win.*
2. **Straddle double-fetch** — a 32-bit instruction crossing a word boundary fetched two
   words; when the low word is already resident (the common sequential case) the buffer
   supplies the low half and only the next word is fetched.

The buffer is invalidated on every redirect (branch/jump/trap/MRET), so a hit is always
same-privilege and same-instruction-memory as the access that hits it. Correctness verified by
the full 70-test directed regression (incl. compressed, atomics, U-mode, PMP, trap-flush
paths); the design also exposed and fixed a latent back-to-back-issue ordering hazard
(`if_produces` guard on the `if_id_valid` clear).

### Remaining gap / follow-on

The residual ~16–28% gap is the rare branch-into-mid-word straddle (low word not yet resident)
and back-to-back miss latency. A **2-word buffer with prefetch-ahead** would close most of it;
see [`M9_FETCH_BUFFER_PLAN.md`](M9_FETCH_BUFFER_PLAN.md) §3.6. With the 1-word buffer landed,
`rv32imc` is now within ~3% of `rv32im` on CoreMark while keeping the code-density advantage.

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
Total ticks      : 10258078
Total time (secs): 10
Iterations       : 15
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
