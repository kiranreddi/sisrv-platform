# Extension roadmap

This platform is ready for incremental feature work because the current top level
already has a configurable corebus or AXI4-Lite path, directed assembly tests,
cocotb unit tests, formal checks, and CI coverage.

## Recommended sequence

| Order | Extension | Why here | Primary use case | Acceptance checks |
|---:|---|---|---|---|
| 1 | GPIO | Smallest end-to-end peripheral slice | Board bring-up, LED/switch control, firmware-visible MMIO smoke tests | Done: corebus + AXI regression pass `test_gpio` |
| 2 | UART | Reuses MMIO pattern, adds byte-stream I/O | Firmware console, boot logs, printf-style debugging | Done: TX/RX/status registers, loopback test, Verilator console capture |
| 3 | RV32M | Isolated ISA extension before microarchitecture churn | Embedded math, DSP kernels, compiler support for `rv32im` | MUL/DIV/REM assembly tests, illegal when disabled |
| 4 | PMP | Adds protection checks on existing memory requests | Firmware sandboxing, MMIO/ROM/RAM access policy validation | CSR tests plus access-fault assembly tests |
| 5 | Debug | Needs stable bus, CSRs, and halt behavior | External halt/resume, register inspection, bring-up workflows | Halt/resume smoke test and debug CSR/register access model |
| 6 | 3-stage pipeline | Largest behavior change, best after ISA/peripheral baseline | Better IPC while preserving the same software contract | Existing 29-test suite unchanged, plus hazard/flush tests |

## Implemented slice 1: GPIO

GPIO is the first implemented extension.

Address map:

| Register | Address | Access | Description |
|---|---:|---|---|
| DATA | `0x1000_3000` | RW | Output data register |
| DIR | `0x1000_3004` | RW | Output enable, 1 means output |
| IN | `0x1000_3008` | RO | Sampled input pins |
| SET | `0x1000_300C` | WO | Write 1s to set DATA bits |
| CLR | `0x1000_3010` | WO | Write 1s to clear DATA bits |

Implemented surfaces:

- `rtl/periph/sisGpio.sv` corebus peripheral.
- `sisPlatformTop` GPIO ports and MMIO decode at `0x1000_3000`.
- `tb/models/sisAxiLiteSlave.sv` matching AXI simulation model.
- `sw/tests/asm/test_gpio.S` directed assembly regression.
- Memory map and verification documentation.

## Implemented slice 2: UART

UART is the second implemented extension.

Address map:

| Register | Address | Access | Description |
|---|---:|---|---|
| TXDATA | `0x1000_4000` | WO/R | Write low byte to transmit, read last TX byte |
| RXDATA | `0x1000_4004` | RO | Read low byte from receive register, clears RX valid |
| STATUS | `0x1000_4008` | RO | bit0 TX_READY, bit1 RX_VALID |
| CTRL | `0x1000_400C` | RW | bit0 TX_ENABLE, bit1 LOOPBACK |
| BAUDDIV | `0x1000_4010` | RW | Baud divider placeholder |

Implemented surfaces:

- `rtl/periph/sisUart.sv` corebus peripheral.
- `sisPlatformTop` UART TX ports and MMIO decode at `0x1000_4000`.
- `tb/models/sisAxiLiteSlave.sv` matching AXI simulation model.
- Verilator harness console output for `uart_tx_valid` bytes.
- `sw/tests/asm/test_uart.S` directed assembly regression.

## RV32M slice

Recommended implementation:

- Add `ENABLE_M` parameter, default off until tests are complete.
- Decode opcode `0110011` with funct7 `0000001`.
- Start with single-cycle MUL/MULH/MULHU/MULHSU if timing is acceptable for this educational target.
- Implement DIV/DIVU/REM/REMU with RISC-V edge cases: divide by zero, signed overflow, remainder sign.
- Update `RV_ARCH` to `rv32im_zicsr` when enabled, or keep handwritten encodings for disabled-mode tests.

## PMP slice

Recommended minimum:

- Implement M-mode PMP CSRs: `pmpcfg0`, `pmpaddr0` through at least `pmpaddr3`.
- Support OFF and NAPOT first; add TOR after the base tests pass.
- Check instruction fetch, load, and store requests before memory fabric routing.
- Raise instruction, load, or store access fault with correct `mcause` and `mtval`.

## Debug slice

Start with a simulation-friendly debug module before external JTAG:

- Halt request input, halted output, resume request input.
- Register/CSR readback through a lightweight debug interface or MMIO debug window.
- Optional abstract command model after halt/resume semantics are stable.
- Keep debug out of the synthesis-critical path unless explicitly enabled.

## Pipeline slice

Do this only after peripheral and ISA coverage is stable:

- Split the existing FSM into fetch, decode, and execute/memory/writeback stages.
- Preserve the current corebus contract initially: one outstanding memory request.
- Add forwarding for ALU results, load-use stall, branch/jump flush, trap/interrupt flush.
- Keep the existing assembly suite as the non-negotiable compatibility gate.
