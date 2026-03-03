# sisrv-platform

[![CI](https://github.com/kiranreddi/sisrv-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/kiranreddi/sisrv-platform/actions/workflows/ci.yml)

ASIC-first, open-source end-to-end RISC-V (RV32I) platform using **Verilator** as the primary simulator.

This repo implements a complete RV32I multi-cycle FSM core with M-mode CSRs and traps,
connected to ROM, RAM, and MMIO peripherals via a simple internal bus.

## Current status

| Milestone | Status |
|-----------|--------|
| M0 — Sim harness & golden flow | ✅ Complete |
| M1 — RV32I multi-cycle core | ✅ Complete (23/23 tests pass) |
| M2 — CSRs + traps (M-mode) | ✅ Complete |
| M2.5 — Formal verification | ✅ Complete (ALU + RegFile proofs) |
| M3 — AXI4-Lite master bridge | ✅ RTL complete (not integrated in default platform) |
| M4 — Timer interrupt | 🔲 Planned |
| M5 — RV32M (mul/div) | 🔲 Planned |
| M6 — 3-stage pipeline | 🔲 Planned |
| M7 — Yosys synthesis | 🔲 Planned |
| M8 — OpenROAD hardening | 🔲 Planned |

See `docs/status.md` for detailed status.

## Quickstart

### Prerequisites

- **Verilator 5.038+** (required for cocotb support)
- **RISC-V cross-compiler**: `riscv64-linux-gnu-gcc` (from `gcc-riscv64-linux-gnu` package)
- **GNU Make**
- **Python 3 + cocotb** (for cocotb tests)
- **Yosys + SymbiYosys + z3** (for formal verification)

On Ubuntu/Debian:
```bash
# Core tools
sudo apt-get install gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu make

# Verilator 5.038 (build from source)
sudo apt-get install git autoconf g++ flex bison libfl2 libfl-dev help2man ccache zlib1g-dev
cd /tmp && git clone --depth 1 --branch v5.038 https://github.com/verilator/verilator.git
cd verilator && autoconf && ./configure --prefix=/usr/local && make -j$(nproc) && sudo make install

# cocotb
pip install cocotb

# Formal verification
sudo apt-get install yosys symbiyosys z3
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

# Run full regression suite (23 tests)
make regress

# Run cocotb tests (ALU + RegFile, 7 tests)
make cocotb

# Run formal verification proofs
make formal

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
  PASS: test_alu_edge
  PASS: test_back_to_back
  PASS: test_branch
  PASS: test_branch_edge
  PASS: test_csr
  PASS: test_csr_edge
  PASS: test_ebreak
  PASS: test_ecall
  PASS: test_fence
  PASS: test_illegal
  PASS: test_jal_jalr
  PASS: test_jalr_align
  PASS: test_load_store
  PASS: test_logic
  PASS: test_lui_auipc
  PASS: test_mem_edge
  PASS: test_pass
  PASS: test_ram_walk
  PASS: test_shift
  PASS: test_slt
  PASS: test_x0
=== Results: 23/23 passed, 0 failed ===
```

## Verification

### Assembly Tests (23 tests)
Directed self-checking tests covering all RV32I instructions:

| Category | Tests | Coverage |
|----------|-------|----------|
| ALU | test_add_sub, test_addi, test_alu_edge | ADD/SUB/ADDI with overflow, INT_MIN/MAX, zero edge cases |
| Logic | test_logic, test_shift, test_slt | AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU |
| Memory | test_load_store, test_mem_edge, test_ram_walk | LB/LBU/LH/LHU/LW/SB/SH/SW, all byte lanes, walking ones/zeros |
| Branch | test_branch, test_branch_edge | BEQ/BNE/BLT/BGE/BLTU/BGEU, INT_MIN/MAX boundaries |
| Jump | test_jal_jalr, test_jalr_align | JAL/JALR, bit[0] masking, rd=x0 |
| CSR | test_csr, test_csr_edge | CSRRW/CSRRS/CSRRC/CSRRWI/CSRRSI/CSRRCI, rs1=x0 read-only |
| Trap | test_ecall, test_ebreak, test_illegal | ECALL/EBREAK/illegal instr trap, mcause, MRET |
| System | test_fence, test_lui_auipc, test_x0 | FENCE, LUI/AUIPC, x0 hardwired zero |
| Stress | test_back_to_back | Fibonacci, register file stress, data dependencies, loops |

### cocotb Tests (28 tests)
Randomized and directed unit tests using Verilator 5.038:

- **ALU** (3 tests): 1000 directed edge-case checks, 1000 random stimulus, full shift amount sweep
- **RegFile** (4 tests): x0-always-zero, write/read all registers, write isolation, 500 random read/write cycles
- **Decoder** (10 tests): Type flag decode for all 11 opcodes, illegal opcode detection, register extraction, I/S/U/B/J immediate sign-extension, funct3/funct7 extraction, 1000 random instructions
- **CSR** (11 tests): Reset values, CSRRW/CSRRS/CSRRC operations, unknown CSR reads zero, trap entry (mepc/mcause/mtval/mstatus), MRET restore, MEPC word alignment, mtvec/mepc output ports

### Formal Verification
Proofs via Yosys/SymbiYosys:

- **ALU**: All 10 operations (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND) formally proven correct for all 2^64 input combinations. Zero flag proven correct.
- **RegFile**: x0-always-zero property proven by k-induction for any sequence of writes.
- **Decoder**: Field extraction, U/B/J immediate alignment invariants, is_legal consistency — all proven for all 2^32 possible instructions.

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

## CI Pipeline

The CI pipeline runs on every push/PR to `main`:

| Job | Description | Tool |
|-----|-------------|------|
| **Lint** | Verilator lint check (all RTL) | Verilator 5.038 |
| **Regression** | 23 assembly self-checking tests | Verilator 5.038 + riscv64-gcc |
| **cocotb** | 28 randomized/directed unit tests | Verilator 5.038 + cocotb |
| **Formal** | ALU + RegFile + Decoder formal proofs | Yosys + SymbiYosys + z3 |

## Directory layout

```
rtl/           Synthesizable RTL (ASIC-first)
  core/        CPU core: sisRvCore, sisAlu, sisDecode, sisRegFile, sisCsr
  bus/         Bus infrastructure: sisMemFabric, sisAxiLiteM
  periph/      Peripherals: sisRom, sisRam, sisTohost
tb/            Testbench
  verilator/   Verilator C++ harness
  cocotb/      cocotb Python tests (ALU, RegFile, Decode, CSR)
  models/      Behavioral models
sw/            Bare-metal BSP + assembly tests
  bsp/         crt0.S, link.ld
  tests/asm/   Assembly test programs (23 tests)
formal/        Formal verification
  alu_add.sv       ALU formal proof wrapper (all 10 ops)
  alu_prove.ys     Yosys SAT proof script (ALU)
  regfile_x0.sv    RegFile x0 proof wrapper
  regfile_x0.sby   SymbiYosys configuration (RegFile)
  decode_legal.sv  Decoder proof wrapper (fields + legality)
  decode_prove.ys  Yosys SAT proof script (Decoder)
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
