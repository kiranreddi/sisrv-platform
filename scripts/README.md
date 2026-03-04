# scripts/

Helper scripts for the sisrv-platform build flow.

## Available scripts

- `yosys_synth.tcl` — Yosys synthesis script for core + AXI bridge
  - Synthesizes `sisRvCore` and `sisAxiLiteM` to generic gates
  - Reports area and cell counts
  - Writes netlist to `build/*_synth.v`
  - Uses `-define SYNTHESIS` to guard sim-only constructs

## Planned scripts
- `openroad_flow.tcl` — OpenROAD PnR flow (Milestone 8)

## Current build flow

The Makefile handles the complete build flow:

```
.S → .elf → .bin → .hex → Verilator simulation
```

1. Assembly source compiled with `riscv64-linux-gnu-gcc`
2. ELF converted to flat binary with `objcopy`
3. Binary converted to hex with `od`
4. Hex loaded into ROM via `$readmemh` during simulation (guarded with `ifndef SYNTHESIS`)

## Running synthesis

```bash
make synth
```

This runs Yosys with `scripts/yosys_synth.tcl` and produces:
- Gate-level netlist: `build/sisRvCore_synth.v`, `build/sisAxiLiteM_synth.v`
- Area/cell reports printed to stdout
