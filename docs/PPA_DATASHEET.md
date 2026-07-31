# PPA Datasheet — sisRvCore (RV32IMC)

**Revision:** 1.0.0  
**Date:** 2026-06-14  
**Target:** Sky130 / generic ASIC (Yosys + OpenSTA reference flow)

## Configuration

| Parameter | Value |
|-----------|-------|
| ISA | RV32IMAC + Zicsr + U-mode + PMP + Zihpm-style HPM counters |
| Microarchitecture | In-order IF/ID/EX-MEM pipeline with independent WB/retire slot and direct-corebus Harvard I/D path |
| Bus | Corebus or AXI4-Lite |
| Clock target | 50 MHz (20 ns) |

## Area (Yosys generic synthesis)

Run `make synth` for current gate-level area report. Typical post-synth cell count
includes core FSM, decode, CSR, CLINT/PLIC, debug DM/DTM, and AXI bridge.

| Block | Notes |
|-------|-------|
| sisRvCore | ALU, decode, regfile, CSR, decompress |
| sisClint + sisPlic | Standard interrupt controllers |
| sisDm + sisJtagDtm | RISC-V Debug 0.13 subset |
| sisAxiLiteM | Single-outstanding AXI4-Lite master |

## Timing (OpenSTA + scripts/constraints.sdc)

| Metric | Value | Method |
|--------|-------|--------|
| Target period | 20 ns | SDC `create_clock` |
| STA sign-off | Post-synth OpenSTA | `make sta-sky130` |
| Sky130 HD latest CI | WNS +10.887 ns, TNS 0 ns, estimated Fmax ~109.7 MHz | Sky130 HD OpenSTA estimate |

## Power

| Metric | Value | Method |
|--------|-------|--------|
| Vectorless post-PnR | `build/openroad/sisHardenTop_power.rpt` after `make harden` | OpenROAD `report_power` / area on Sky130 HD |
| Activity-based (SAIF/VCD) | not yet | Needs switching dump from Verilator |
| Post-PnR WNS (global route) | +5.807 ns | `make harden` / `sisHardenTop_pnr_report.txt` |
| Post-PnR est. Fmax | ~70.5 MHz | Derived from 20 ns clock − WNS |

Wire-accurate capacitance needs RCX SPEF; older OpenROAD builds used in CI may emit a SPEF stub — see `docs/HARDENING.md`.

## Hardening (M8)

| Item | Status |
|------|--------|
| Flow | `make harden` → `scripts/openroad_flow.tcl` + Magic GDS/DRC |
| Top | `sisHardenTop` (ALU/decode/regfile/decompress + AXI-Lite) |
| Synth area | ~63.4k µm² (Yosys Sky130 HD) |
| GDS | `build/openroad/sisHardenTop.gds` (~4 MB) |
| Magic DRC | 0 errors on streamed DEF (educational tech) |
| Full-core GDS | Deferred (Yosys SV frontend limits on CSR/PMP) |

## CPI / Performance

| Metric | Current status |
|--------|----------------|
| Microarchitecture | In-order IF/ID/EX-MEM pipeline with independent WB/retire slot and direct-corebus Harvard I/D path |
| Directed pipeline smoke | forwarding 60 cycles; load-use 66; branch/jump flush 59; trap flush 55; interrupt flush 76; throughput guard 94; debug single-step 36 |
| CoreMark/MHz | **1.530** (`rv32imc_zicsr -O2`, direct corebus, internal Verilator, not certified EEMBC) |
| Dhrystone DMIPS/MHz | **0.475** (`rv32imc_zicsr -O2`, direct corebus, internal Verilator) |
| Dhrystone CPI | **2.360** over 1,741 iterations |

See `docs/BENCHMARKS.md` for raw logs, validation status, compiler flags, and the
`rv32im_zicsr -O2` comparison row.
