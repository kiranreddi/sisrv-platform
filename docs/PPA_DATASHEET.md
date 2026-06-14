# PPA Datasheet — sisRvCore (RV32IMC)

**Revision:** 1.0.0  
**Date:** 2026-06-14  
**Target:** Sky130 / generic ASIC (Yosys + OpenSTA reference flow)

## Configuration

| Parameter | Value |
|-----------|-------|
| ISA | RV32IMC + Zicsr |
| Microarchitecture | Multi-cycle FSM (7 states) |
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
| STA sign-off | Post-synth OpenSTA | `make sta` |
| Fmax | See CI synth+STA artifact | WNS/TNS from OpenSTA |

## Power

Power estimation requires switching activity (VCD/SAIF) and Liberty power tables.
Use OpenROAD + Sky130 after place-and-route for wire-accurate capacitance.

## Hardening (M8)

OpenROAD Sky130 flow: `scripts/openroad_flow.tcl`  
Exit gate: GDS DRC/LVS clean or documented deltas per milestone M8.

## CPI / Performance

| Metric | Estimate |
|--------|----------|
| CPI (FSM) | ~6–8 |
| CoreMark/MHz | ~0.4–0.6 (pre-pipeline) |

Pipeline milestone M6 targets ~1.0–1.3 CPI and E2-class CoreMark/MHz.
