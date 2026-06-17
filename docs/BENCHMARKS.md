# Benchmarks — CoreMark and Dhrystone

**Date:** 2026-06-16
**Git commit:** `e1782b49ad3d31776eefef4d078f39e6c515bdd3`
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
