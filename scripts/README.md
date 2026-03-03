# scripts/

Helper scripts for the sisrv-platform build flow.

## Available scripts

*(Scripts will be added as milestones progress)*

## Planned scripts
- `gen_hex.sh` — Convert ELF to hex for ROM initialization
- `run_regress.sh` — Regression runner with reporting
- `yosys_synth.tcl` — Yosys synthesis script (Milestone 7)
- `openroad_flow.tcl` — OpenROAD PnR flow (Milestone 8)

## Current build flow

The Makefile handles the complete build flow:

```
.S → .elf → .bin → .hex → Verilator simulation
```

1. Assembly source compiled with `riscv64-linux-gnu-gcc`
2. ELF converted to flat binary with `objcopy`
3. Binary converted to hex with `od`
4. Hex loaded into ROM via `$readmemh` during simulation
