# sisrv-platform

ASIC-first, open-source end-to-end RISC-V (RV32I) platform using **Verilator** as the primary simulator.

This repo implements a complete RV32I multi-cycle FSM core with M-mode CSRs and traps,
connected to ROM, RAM, and MMIO peripherals via a simple internal bus.

## Current status

| Milestone | Status |
|-----------|--------|
| M0 — Sim harness & golden flow | ✅ Complete |
| M1 — RV32I multi-cycle core | ✅ Complete (13/13 tests pass) |
| M2 — CSRs + traps (M-mode) | ✅ Complete |
| M3 — AXI4-Lite master bridge | ✅ RTL complete (not integrated in default platform) |
| M4 — Timer interrupt | 🔲 Planned |
| M5 — RV32M (mul/div) | 🔲 Planned |
| M6 — 3-stage pipeline | 🔲 Planned |
| M7 — Yosys synthesis | 🔲 Planned |
| M8 — OpenROAD hardening | 🔲 Planned |

See `docs/status.md` for detailed status.

## Quickstart

### Prerequisites

- **Verilator** (tested with 5.020+)
- **RISC-V cross-compiler**: `riscv64-linux-gnu-gcc` (from `gcc-riscv64-linux-gnu` package)
- **GNU Make**

On Ubuntu/Debian:
```bash
sudo apt-get install verilator gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu make
```

### Build and run

```bash
# Lint all RTL (Verilator lint)
make lint

# Build simulation binary
make build/sim_sisPlatformTop

# Build all assembly test hex files
make sw

# Run a single test (the basic PASS test)
make sim

# Run full regression suite (13 tests)
make regress

# Run a specific test
make run-test_addi
make run-test_branch
make run-test_load_store

# View waveforms (after running sim)
make wave
# Then: gtkwave build/wave.fst

# Clean all build artifacts
make clean
```

### Expected output

```
$ make regress
=== Running regression tests ===
  PASS: test_add_sub
  PASS: test_addi
  PASS: test_branch
  PASS: test_csr
  PASS: test_ecall
  PASS: test_jal_jalr
  PASS: test_load_store
  PASS: test_logic
  PASS: test_lui_auipc
  PASS: test_pass
  PASS: test_shift
  PASS: test_slt
  PASS: test_x0
=== Results: 13/13 passed, 0 failed ===
```

## Architecture

### CPU Core (`rtl/core/sisRvCore.sv`)
- **ISA**: RV32I (complete base integer instruction set)
- **Microarchitecture**: Multi-cycle FSM (FETCH → DECODE → EXECUTE → MEM → WB)
- **Privilege**: M-mode only with CSRs (mstatus, mtvec, mepc, mcause, mtval, mscratch)
- **Traps**: ECALL, EBREAK, illegal instruction → handler via mtvec, return via MRET

### Memory Map
| Region | Base | Size | Notes |
|--------|------|------|-------|
| ROM | `0x0000_0000` | 64 KB | Reset vector, program code |
| MMIO | `0x1000_0000` | 64 KB | tohost (pass/fail signaling) |
| RAM | `0x8000_0000` | 256 KB | Data/stack memory |

### Internal Bus (corebus)
Simple request/response protocol, single outstanding transaction.
See `docs/INTERFACES.md` for signal details.

## Directory layout

```
rtl/           Synthesizable RTL (ASIC-first)
  core/        CPU core: sisRvCore, sisAlu, sisDecode, sisRegFile, sisCsr
  bus/         Bus infrastructure: sisMemFabric, sisAxiLiteM
  periph/      Peripherals: sisRom, sisRam, sisTohost
tb/            Verilator testbench harness + models
sw/            Bare-metal BSP + assembly tests
  bsp/         crt0.S, link.ld
  tests/asm/   Assembly test programs
formal/        SymbiYosys proofs (planned)
scripts/       Helper scripts (planned)
docs/          Architecture docs + plan
```

## Documentation

- `docs/PLAN.md` — Complete milestone plan + exit criteria
- `docs/MEMORY_MAP.md` — Address map
- `docs/INTERFACES.md` — Internal bus + AXI-Lite profile
- `docs/VERIFICATION.md` — Verification strategy
- `docs/status.md` — Detailed implementation status

## License

Pick a license (Apache-2.0 / BSD-2-Clause / MIT). This package does not include third-party IP.
