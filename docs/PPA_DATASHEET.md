# PPA Datasheet — sisRvCore (RV32IMC)

**Revision:** 1.0.0  
**Date:** 2026-06-14  
**Target:** Sky130 / generic ASIC (Yosys + OpenSTA reference flow)

## Configuration

| Parameter | Value |
|-----------|-------|
| ISA | RV32IMC + Zicsr |
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
| Sky130 HD latest CI | WNS -199.946 ns, TNS -10929.076 ns, estimated Fmax 4.55 MHz | CI run #27565469770 |

## Power

Power estimation requires switching activity (VCD/SAIF) and Liberty power tables.
Use OpenROAD + Sky130 after place-and-route for wire-accurate capacitance.

## Hardening (M8)

OpenROAD Sky130 flow: `scripts/openroad_flow.tcl`  
Exit gate: GDS DRC/LVS clean or documented deltas per milestone M8.

## CPI / Performance

| Metric | Current status |
|--------|----------------|
| Microarchitecture | In-order IF/ID/EX-MEM pipeline with independent WB/retire slot and direct-corebus Harvard I/D path |
| Directed pipeline smoke | forwarding 60 cycles; load-use 66; branch/jump flush 59; trap flush 55; interrupt flush 76; throughput guard 94; debug single-step 36 |
| CoreMark/MHz | **1.264** (`rv32imc_zicsr -O2`, direct corebus, internal Verilator, not certified EEMBC) |
| Dhrystone DMIPS/MHz | **0.400** (`rv32imc_zicsr -O2`, direct corebus, internal Verilator) |
| Dhrystone CPI | **2.804** over 1,491 iterations |

See `docs/BENCHMARKS.md` for raw logs, validation status, compiler flags, and the
`rv32im_zicsr -O2` comparison row.
