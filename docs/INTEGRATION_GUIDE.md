# Integration Guide — sisrv-platform

## Overview

sisrv-platform delivers a verified RV32IMC soft core with standard CLINT/PLIC,
RISC-V Debug (DM + JTAG DTM), and an optional AXI4-Lite master path.

## Quick start

```bash
make lint regress cocotb formal synth
```

## Top-level module

`sisPlatformTop` parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ROM_INIT_FILE` | `rom.hex` | Verilog $readmemh ROM image |
| `RAM_INIT_FILE` | `""` | Optional RAM init |
| `USE_AXIL` | 0 | 0=corebus fabric, 1=AXI4-Lite bridge |
| `AXIL_STALL_RATE` | 0 | AXI slave stall injection (TB) |

## Memory map

| Region | Address | Device |
|--------|---------|--------|
| ROM | `0x0000_0000` | Instruction / rodata |
| CLINT | `0x0200_0000` | MSIP, MTIMECMP, MTIME |
| MMIO | `0x1000_0000` | Tohost pass/fail |
| GPIO | `0x1000_3000` | 32-bit GPIO |
| UART | `0x1000_4000` | Console UART |
| PLIC | `0x0C00_0000` | Platform IRQ controller |
| RAM | `0x8000_0000` | Data / bss / stack |

## Interrupt wiring

- **MTIP/MSIP:** CLINT at `0x0200_0000` → `mie.MTIE` / `mie.MSIE`
- **MEIP:** PLIC external sources `plic_irq[7:0]` OR GPIO `gpio_out[7:0]`
- Priority: MEIP > MTIP > MSIP

## Debug

JTAG pins: `jtag_tck`, `jtag_tms`, `jtag_tdi`, `jtag_tdo`  
Connect to OpenOCD RISC-V target after DM bring-up (halt/resume/step, abstract GPR access).

## Toolchain

Build firmware with `riscv64-unknown-elf-gcc` (or `riscv64-linux-gnu-gcc`):

```
-march=rv32imc_zicsr -mabi=ilp32
```

## Compliance

RISCOF + Spike co-simulation under `verification/riscof/`.  
Lock-step random ISS: `make cosim-lockstep`.

## License

Apache-2.0 — see [LICENSE](../LICENSE).
