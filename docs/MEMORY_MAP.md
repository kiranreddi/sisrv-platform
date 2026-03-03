# Memory map (default)

## Regions
| Region | Base | Size (MVP suggestion) | Notes |
|---|---:|---:|---|
| ROM | 0x0000_0000 | 64 KiB | reset vector, small boot program |
| RAM | 0x8000_0000 | 256 KiB–1 MiB | program/data/stack |
| MMIO | 0x1000_0000 | 64 KiB | peripherals + tohost |

## MMIO devices (MVP)
| Device | Base | Offset regs | Notes |
|---|---:|---|---|
| tohost | 0x1000_0000 | +0x0 DATA | write PASS/FAIL signature |
| UART (opt) | 0x1000_1000 | TXDATA/RXDATA/STATUS | minimal |
| Timer (opt) | 0x1000_2000 | MTIME/MTIMECMP | machine timer interrupt |

## PASS/FAIL protocol
- Write 32-bit value to `tohost.DATA`:
  - `0x0000_0001` = PASS
  - `0x0000_0000` = FAIL
  - Any other value can encode test id / error code (recommended).

## Reset
- CPU reset vector: `0x0000_0000`
- ROM contains initial code that jumps to RAM if desired.
