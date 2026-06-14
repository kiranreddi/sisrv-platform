# RISCOF / riscv-arch-test bring-up for sisrv-platform

This directory contains an isolated architectural-compliance harness for comparing
`sisRvCore` against a reference ISS (Spike) using [RISCOF](https://github.com/riscv/riscof).

## Claimed ISA profile

- **RV32IM** machine-mode only (`rv32im_zicsr`, ABI `ilp32`)
- **Implemented for ACT**: base integer ops, multiply/divide, Zicsr, Zifencei, WFI no-op
- **Explicitly excluded** (see `skip_tests.txt`):
  - PMP
  - Debug mode
  - CLINT / PLIC / external interrupts
  - Supervisor / user modes
  - Atomics (A), compressed (C), FP (F/D), hypervisor (H)

## Prerequisites

Install outside the repo (not committed):

```bash
cd /path/to/sisrv-platform
python3 -m venv .venv-riscof
source .venv-riscof/bin/activate
pip install -r verification/riscof/requirements.txt
```

Pinned versions (Python 3.11 recommended):

| Package | Version |
|---------|---------|
| riscof | 1.23.4 |
| riscv-config | 2.17.0 |
| riscv-isac | 0.7.0 |
| ruamel.yaml | 0.17.40 |

`riscv-arch-test` is pinned to commit `59075f8f` (legacy `riscv-test-suite/` layout
required by RISCOF 1.23.x).

Also required:

```bash
riscv64-unknown-elf-gcc --version   # or riscv64-linux-gnu-gcc fallback
spike --version                     # reference model
```

Build the Verilator platform sim once:

```bash
make build/sim_sisPlatformTop USE_AXIL=0
```

## Layout

```text
verification/riscof/
  config.ini                 # RISCOF configuration
  requirements.txt           # pinned Python deps
  skip_tests.txt             # documented exclusions
  plugins/
    sisrv/                   # DUT plugin (Verilator)
    spike/                   # reference plugin (Spike ISS)
  scripts/
    elf2sisrv.py             # ELF → rom.hex + ram.hex
    filter_testlist.py       # single-test smoke filter
```

## Smoke test (one RV32I test)

```bash
make riscof-smoke
```

This clones `riscv-arch-test`, generates a one-test list (`add-01` by default), runs Spike
and the Verilator DUT, and compares signatures.

Override the smoke test by stem name (for example `addi-01`):

```bash
make riscof-smoke RISCOF_SMOKE_TEST=addi-01
```

When multiple suite entries share a stem, the filter prefers `rv32i_m/I/src` over `hints`.

## Broader suites (local only)

```bash
make riscof-rv32i     # RV32I integer directory
make riscof-rv32im    # rv32i_m tree (still filtered by ISA yaml)
```

## Signature flow

1. Architectural tests write results between `begin_signature` / `end_signature`.
2. `model_test.h` halts via tohost code `3` (`RVMODEL_HALT`).
3. `tb/verilator/main.cpp` dumps the RAM signature region:

```bash
build/sim_sisPlatformTop \
  --rom rom.hex \
  --ram ram.hex \
  --signature-start 0x8000xxxx \
  --signature-end 0x8000yyyy \
  --signature-out DUT-sisrv.signature \
  --timeout-cycles 1000000
```

## Interpreting mismatches

| Symptom | Likely cause |
|---------|----------------|
| Compile failure | Toolchain prefix mismatch; use `riscv64-unknown-elf-` or linux-gnu fallback |
| Timeout | Trap not taken, wrong boot address, or hung WFI/interrupt wait |
| Signature size mismatch | `begin_signature`/`end_signature` not in RAM or wrong dump bounds |
| Word mismatch | RTL bug, trap priority difference, or unsupported test slipped through filters |
| Spike-only failure | Reference plugin env mismatch — compare against DUT plugin logs |

## Manual RISCOF run

```bash
cd verification/riscof
source ../../.venv-riscof/bin/activate
riscof run --config config.ini \
  --suite riscv-arch-test/riscv-test-suite/rv32i_m/I \
  --env riscv-arch-test/riscv-test-suite/env \
  --work-dir work/smoke --no-browser
```

## Notes

- Changes stay under `verification/riscof/`, `tb/verilator/main.cpp`, and minimal sim
  harness hooks unless a failing ACT exposes a real RTL bug.
- Full ACT coverage is **not** in required CI; only an optional smoke job runs when tools
  are present.
