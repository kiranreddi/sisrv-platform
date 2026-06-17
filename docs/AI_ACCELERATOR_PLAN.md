# V1 Edge-AI Accelerator Plan: MMIO Int8 Dot-Product Engine

## Summary

Add a small AI accelerator slice to `sisrv-platform`: a memory-mapped signed int8
dot-product/MAC peripheral controlled by `sisRvCore`. This is not a full DMA NPU
yet; it is the first compute block that proves the CPU, SRAM, MMIO, UART, and
JTAG/debug shell can host AI acceleration.

Default design: 4-lane signed int8 dot product per operation, accumulated into a
signed 64-bit accumulator, polled by firmware through MMIO.

## Key Changes

- Add a synthesizable peripheral, conceptually `sisMac8`, at MMIO base
  `0x1000_5000`.
- Register map:

| Offset | Name | Access | Description |
|---:|---|---|---|
| `0x00` | `CTRL` | WO | bit0 `START`, bit1 `CLR_ACC`, bit2 `CLR_DONE` |
| `0x04` | `STATUS` | RO | bit0 `BUSY`, bit1 `DONE` |
| `0x08` | `A_PACKED` | RW | four signed int8 activations, lane0 in bits `[7:0]` |
| `0x0C` | `B_PACKED` | RW | four signed int8 weights, lane0 in bits `[7:0]` |
| `0x10` | `ACC_LO` | RO | accumulator bits `[31:0]` |
| `0x14` | `ACC_HI` | RO | accumulator bits `[63:32]` |
| `0x18` | `OP_COUNT` | RO | completed dot-product operations |
| `0x1C` | `INFO` | RO | fixed ID, version, and lane metadata |

## Operation Semantics

- On `START`, compute `sum(A[i] * B[i])` for four signed int8 lanes and add it to
  the 64-bit accumulator.
- Latency is deterministic: accept start when idle, assert `BUSY`, complete next
  cycle, set `DONE`, and increment `OP_COUNT`.
- If `START` is written while busy, ignore it and leave state unchanged; do not
  raise a bus error.
- `CLR_ACC` clears accumulator and op count.
- `CLR_DONE` clears the done bit.
- Reads and writes use the existing corebus request/response contract and
  byte-write strobe behavior.

## Integration

- Wire the accelerator into the direct corebus MMIO sub-router in
  `sisPlatformTop` as device slot `0x1000_5xxx`.
- Mirror the same register behavior in the AXI-Lite simulation slave model so
  `USE_AXIL=1`, `regress-axil`, and stalled AXI tests remain meaningful.
- Update the memory map, programmer reference, and extension roadmap to document
  `MAC8` at `0x1000_5000`.

## Tests

- Add a directed assembly test `test_mac8.S`:
  - Verify `INFO`, reset `STATUS`, accumulator zero, and `OP_COUNT=0`.
  - Run one dot product with positive values.
  - Run signed negative and mixed values.
  - Run multiple `START` operations to verify accumulation.
  - Use byte and word writes to verify packed lane behavior and write strobes.
  - Clear accumulator/done and verify state resets.
- Ensure the test passes through:
  - `make regress`
  - `make regress-axil`
  - `make regress-axil-stall`
- Add cocotb unit coverage for reset behavior, signed lane multiplication,
  accumulation, busy/done transitions, write-strobe merging, and ignored
  start-while-busy behavior.
- Run final validation:
  - `make lint`
  - `make regress`
  - `make regress-axil`
  - `make regress-axil-stall`
  - `make synth`

## Assumptions

- V1 is intentionally MMIO-fed, not DMA-fed, because the current SRAM path is
  single-port/corebus-oriented and true DMA would require RAM arbitration or a
  second memory port.
- No interrupt is added in V1; firmware polls `STATUS.DONE`.
- Arithmetic is signed int8 by signed int8 with signed 64-bit accumulation.
- This creates the first AI accelerator building block. A later V2 can add SRAM
  DMA descriptors, scratchpad buffers, a larger lane count, and an optional PLIC
  done interrupt.
