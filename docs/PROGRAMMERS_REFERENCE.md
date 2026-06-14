# Programmer's Reference — sisRvCore

## ISA

**Advertised:** `RV32IMC_Zicsr` (M-mode only)

| Extension | Support |
|-----------|---------|
| RV32I | Full |
| M | MUL/DIV/REM |
| C | Compressed 16-bit instructions |
| Zicsr | CSRs, ECALL, EBREAK, MRET, WFI (legal NOP) |
| Zifencei | FENCE.I treated as NOP |

## Privilege

Machine mode only. `mtvec` direct mode (MODE=0).

## CSRs

| CSR | Address | Access | Notes |
|-----|---------|--------|-------|
| mstatus | 0x300 | RW | MIE bit 3, MPIE bit 7 |
| misa | 0x301 | RO | C+M+I set |
| mie | 0x304 | RW | MSIE(3), MTIE(7), MEIE(11) |
| mtvec | 0x305 | RW | Direct mode only |
| mscratch | 0x340 | RW | |
| mepc | 0x341 | RW | Word-aligned on write |
| mcause | 0x342 | RW | |
| mtval | 0x343 | RW | |
| mip | 0x344 | RO | MSIP/MTIP/MEIP from CLINT/PLIC |
| mcycle/minstret | 0xB00/0xB02 | RW | Zicntr |
| ID CSRs | 0xF11–0xF15 | RO | Zero (configurable later) |

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

## Performance

Multi-cycle FSM: ~6–8 CPI typical. See [PPA_DATASHEET.md](PPA_DATASHEET.md).
