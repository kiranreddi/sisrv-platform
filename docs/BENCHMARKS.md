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
| CoreMark performance | `rv32imc_zicsr -O2` | 13 | 10,287,471 | n/a | **1.264 CoreMark/MHz** | 791,343.923 | n/a | n/a | PASS |
| CoreMark validation | `rv32imc_zicsr -O2` | 13 | 10,286,981 | n/a | 1.264 CoreMark/MHz | 791,306.231 | n/a | n/a | PASS |
| Dhrystone 2.1 | `rv32imc_zicsr -O2` | 1,491 | 2,120,289 | 755,952 | **0.400 DMIPS/MHz** | 1,422.058 | 507.010 | 2.804 | PASS |
| CoreMark performance | `rv32im_zicsr -O2` | 16 | 10,655,909 | n/a | **1.502 CoreMark/MHz** | 665,994.313 | n/a | n/a | PASS |
| CoreMark validation | `rv32im_zicsr -O2` | 16 | 10,675,445 | n/a | 1.499 CoreMark/MHz | 667,215.313 | n/a | n/a | PASS |
| Dhrystone 2.1 | `rv32im_zicsr -O2` | 1,675 | 2,035,202 | 849,240 | **0.468 DMIPS/MHz** | 1,215.045 | 507.008 | 2.396 | PASS |

CoreMark/MHz is computed as `iterations * 1,000,000 / cycles`.
Dhrystone DMIPS/MHz is computed as `iterations * 1,000,000 / cycles / 1757`.

## Analysis: the C extension currently *costs* throughput

The `rv32im` configuration is faster than `rv32imc` on both benchmarks:

| Metric | `rv32imc` | `rv32im` | Δ (im vs imc) |
|---|---:|---:|---:|
| CoreMark/MHz | 1.264 | 1.502 | **+18.8%** |
| Dhrystone DMIPS/MHz | 0.400 | 0.468 | **+17.0%** |
| Dhrystone CPI | 2.804 | 2.396 | **+0.41 with C** |
| Dhrystone cycles/iter | 1,422 | 1,215 | **+17% with C** |
| Dhrystone retired instr/iter | 507.01 | 507.01 | **identical** |

The C extension does its job on **code density** (16-bit encodings → smaller `.text`),
but on this microarchitecture it buys *zero* dynamic-instruction reduction for Dhrystone
(identical 507 retired instructions/iteration) while adding ~17% cycles. The entire delta
is **CPI**, i.e. front-end fetch overhead.

### Root cause: a stateless, single-word fetch front end

The IF stage (`rtl/core/sisRvCore.sv`, FSM `IF_REQ → IF_WAIT → IF_SECOND_REQ →
IF_SECOND_WAIT`) issues one **word-aligned** bus fetch at a time and keeps no fetch buffer
across instructions. With compressed code that creates two extra costs that `rv32im`
(all-aligned, all 32-bit) never pays:

1. **Word re-fetch for the second halfword.** When a 32-bit word holds two 16-bit
   instructions, the lower one retires with `fetch_pc += 2` and the **next instruction
   re-requests the same word** to read its upper half — a redundant bus round-trip for a
   word the core already had (`IF_WAIT` lower/upper-half handling). Two compressed
   instructions in one word therefore cost two fetches, erasing the density benefit at the
   bus.
2. **Straddle double-fetch for unaligned 32-bit instructions.** Because C breaks 4-byte
   alignment, a 32-bit instruction can cross a word boundary. The front end then saves the
   low half (`fetch_upper_hold`) and takes a **second sequential word fetch**
   (`IF_SECOND_REQ`/`IF_SECOND_WAIT`) before it can issue — a 2× fetch latency for that one
   instruction. `rv32im` never straddles, so it never pays this.

### Fix direction (M9 front-end rework)

Both costs disappear with a small **fetch buffer** (1–2 words) that retains the last fetched
word and its address: the second compressed instruction in a word is served with no bus
access, and the low half of a straddling 32-bit instruction is already resident. That lets
the core keep the code-density win *and* recover the ~17–19% throughput, and is the natural
scope for an M9 fetch/decode-buffer milestone. Until then, **`rv32im` is the faster
configuration** and the more favorable number to lead with when comparing against
E2 / Cortex-M0+–M3-class cores; `rv32imc` remains the right pick when code size dominates.

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
Total ticks      : 10287471
Total time (secs): 10
Iterations       : 13
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
