# Programmer's Reference — sisRvCore

## ISA

**Advertised:** `RV32IMAC_Zicsr` (M-mode + U-mode)

| Extension | Support |
|-----------|---------|
| RV32I | Full |
| M | MUL/DIV/REM |
| C | Compressed 16-bit instructions |
| Zicsr | CSRs, ECALL, EBREAK, MRET, WFI (TW-gated in U) |
| Zifencei | FENCE.I treated as NOP |
| U | User mode with PMP (8 regions, G=0) |

## Privilege

Machine mode (M) and user mode (U). No S-mode or MMU. Traps and interrupts always
deliver to M-mode. `mret` transitions M↔U using `mstatus.MPP`.

## CSRs

| CSR | Address | Access | Notes |
|-----|---------|--------|-------|
| mstatus | 0x300 | RW | MIE(3), MPIE(7), MPP(12:11), MPRV(17), TW(21) |
| misa | 0x301 | RO | I+M+A+C+U bits |
| mie | 0x304 | RW | MSIE(3), MTIE(7), MEIE(11) |
| mtvec | 0x305 | RW | Direct or vectored (MODE=1) |
| mcounteren | 0x306 | RW | CY/TM/IR gates for U-mode `cycle`/`instret` |
| mscratch | 0x340 | RW | |
| mepc | 0x341 | RW | Word-aligned on write |
| mcause | 0x342 | RW | ECALL: 8 (U), 11 (M) |
| mtval | 0x343 | RW | |
| mip | 0x344 | RO | MSIP/MTIP/MEIP from CLINT/PLIC |
| pmpcfg0–7 | 0x3A0–0x3A7 | RW | Per-entry cfg byte (TOR/NA4/NAPOT, R/W/X, L) |
| pmpaddr0–7 | 0x3B0–0x3B7 | RW | Physical address [33:2] |
| cycle/instret | 0xC00/0xC02 | RO shadows | Gated by `mcounteren` in U |
| mcycle/minstret | 0xB00/0xB02 | RW | Zicntr |
| ID CSRs | 0xF11–0xF15 | RO | Zero (configurable later) |

## PMP

Eight physical memory regions. Lowest matching entry wins. M-mode bypasses
permission checks on unlocked entries; locked entries apply to M and U. Fetch
checks X; load/LR checks R; store/SC/AMO checks W (AMO requires R+W).

## Traps

Standard mcause codes for illegal instruction, ecall, ebreak, misaligned
load/store/control-flow, and instruction/load/store access faults on `rsp_err`.

## Interrupts

Taken between instructions when `mstatus.MIE` and the corresponding `mie` bit are set.

| IRQ | mcause | Source |
|-----|--------|--------|
| MSIP | 0x80000003 | CLINT MSIP |
| MTIP | 0x80000007 | CLINT timer |
| MEIP | 0x8000000B | PLIC |

## Debug

RISC-V Debug Module 0.13 subset: halt, resume, single-step, abstract GPR access via DMI/JTAG.
The current DMCONTROL subset uses bit 31 for `haltreq`, bit 30 for `resumereq`,
bit 2 for step mode, and bit 0 for `dmactive`.

## Performance

The core is an in-order IF/ID/EX-MEM pipeline with an independent WB/retire slot
and direct-corebus Harvard instruction/data path.
Internal direct-corebus Verilator measurements on `rv32imc_zicsr -O2`: **1.264
CoreMark/MHz**, **0.400 Dhrystone DMIPS/MHz**, Dhrystone **CPI 2.804**. See
[BENCHMARKS.md](BENCHMARKS.md) for conditions, raw excerpts, and caveats.
