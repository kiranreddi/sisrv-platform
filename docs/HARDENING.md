# Milestone 8 — OpenROAD Sky130 hardening

**Status:** Complete (reference hardenable IP slice)  
**PDK:** Sky130 HD (`sky130_fd_sc_hd`, TT 1.8 V / 25 °C)  
**Top:** `sisHardenTop` (`rtl/asic/sisHardenTop.sv`)

## What is hardened

M8 hardens the **synthesizable core datapath + AXI4-Lite bridge**:

| Block | Role |
|-------|------|
| `sisAlu` | RV32I ALU |
| `sisDecode` | I/M/C/A decode |
| `sisRegFile` | 32×32 regfile |
| `sisDecompress` | RV32C expander |
| `sisAxiLiteM` | Corebus → AXI4-Lite master |
| `sisHardenTop` | Floorplanned ASIC wrapper |

ROM/RAM are **not** included (blackboxed for a later SRAM-macro integration), matching the M8 plan.

### Why not full `sisRvCore` yet

The open Yosys SystemVerilog frontend still rejects constructs used in CSR/PMP/PLIC:

- packed multi-dimensional ports (`logic [N-1:0][31:0]`)
- `int` / `int'()` casts inside functions
- some automatic functions with non-const args (`sisPmp`)

Those modules remain fully verified in simulation / RISCOF / co-sim. Closing the gap is a follow-on RTL cleanup (flatten PMP/HPM arrays, replace `int` with `logic` widths), not a PnR issue.

## How to run

```bash
# Tools: yosys (≥0.38 recommended), openroad, magic; klayout optional
# Install tip: micromamba create -n or -c litex-hub -c conda-forge openroad yosys magic
make fetch-sky130-pdk   # sparse-checkout ORFS sky130hd + Magic tech (~20 MB)
make synth-harden       # Yosys → Sky130 netlist
make openroad-harden    # Floorplan / place / CTS / global route → DEF/SDF
make openroad-gds       # Magic stream-out → GDS
make openroad-drc       # Magic DRC (+ KLayout DRC/LVS if installed)
make harden             # Full M8 path (CI default: HARDEN_DROUTE_ITERS=0)
make harden HARDEN_DROUTE_ITERS=3   # optional deeper TritonRoute attempt
```

Artifacts land in `build/openroad/`:

| File | Description |
|------|-------------|
| `sisHardenTop_synth.v` | Pre-PnR gate netlist |
| `sisHardenTop.def` | Placed & routed DEF |
| `sisHardenTop_pnr.v` | Post-PnR netlist |
| `sisHardenTop.gds` | GDSII |
| `sisHardenTop.sdf` / `.spef` | Timing / parasitics |
| `sisHardenTop_pnr_report.txt` | Post-route WNS/TNS/Fmax |
| `sisHardenTop_power.rpt` | OpenROAD power estimate |
| `sisHardenTop_magic_drc.rpt` | Magic DRC summary |

## Tooling notes

- CI installs OpenROAD / Yosys / Magic from the `litex-hub` conda channel (same path as local micromamba).
- GDS is written with **Magic** because some OpenROAD builds lack `write_gds`.
- PDK files are fetched on demand into `third_party/sky130hd/` (gitignored).

## DRC / LVS deltas (documented)

| Check | Expectation | Notes |
|-------|-------------|-------|
| OpenROAD detailed-route DRC | Optional | Default `HARDEN_DROUTE_ITERS=0` skips TritonRoute (multi-hour on older OpenROAD). Global-routed DEF + Magic GDS are the CI artifacts; set `HARDEN_DROUTE_ITERS=3+` locally for a deeper attempt (`*_route_drc.rpt`) |
| Magic DRC | Report always produced | Open HD kit + abstract LEF stream-out often flags fill/tap/via geometry that is flow-noise, not RTL bugs |
| KLayout DRC/LVS | Optional when `klayout` present | Rules from ORFS `sky130hd.lydrc` / `.lylvs`; schematic vs extracted mismatches from filler/tap cells are documented here as accepted for the educational reference flow |
| Full-core GDS | Deferred | Blocked on Yosys SV frontend / array flattening (above) |

Power numbers from `sisHardenTop_power.rpt` are **vectorless** (no SAIF/VCD). Activity-based power is a follow-on once a switching dump is wired through the Verilator harness.

## Exit criteria mapping

| M8 exit item | Evidence |
|--------------|----------|
| OpenROAD flow scripts + constraints | `scripts/openroad_flow.tcl`, `scripts/constraints_sisHardenTop.sdc` |
| Floorplan, PnR | `make openroad-harden` → DEF |
| Post-PnR netlist + SDF | `*_pnr.v`, `*.sdf` |
| GDS produced | `make openroad-gds` → `*.gds` |
| DRC/LVS clean or deltas documented | Magic/KLayout reports + this section |
