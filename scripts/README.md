# scripts/

Helper scripts for the sisrv-platform build flow.

## Available scripts

- `yosys_synth.tcl` — Yosys generic synthesis for ALU/decode/regfile/AXI-Lite
- `yosys_synth_sky130.tcl` — Sky130-mapped STA smoke (`sisRegFile`)
- `yosys_synth_harden.tcl` — Sky130 synthesis for `sisHardenTop` (M8)
- `sta_sky130.tcl` / `sta_opensta.tcl` — OpenSTA timing scripts
- `constraints*.sdc` — SDC constraints
- `fetch_sky130_lib.sh` — Liberty-only fetch for STA
- `fetch_sky130_pdk.sh` — Full Sky130 HD platform fetch for OpenROAD/Magic
- `openroad_flow.tcl` — OpenROAD floorplan → route (M8)
- `magic_gds.tcl` / `magic_drc.tcl` — GDS stream-out + Magic DRC
- `run_klayout_drc_lvs.sh` — Optional KLayout DRC/LVS
- `run_benchmarks.py` — CoreMark/Dhrystone driver

## Hardening (M8)

```bash
make harden
```

Produces `build/openroad/sisHardenTop.gds` plus DEF/SDF/SPEF/DRC/power reports.
See [`docs/HARDENING.md`](../docs/HARDENING.md).

## Synthesis (generic)

```bash
make synth
```

Produces gate-level netlists and `build/ppa_synth_report.txt`.
