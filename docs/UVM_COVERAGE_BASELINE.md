# UVM Verilator Coverage Baseline

Measured locally with Verilator 5.050 (`make uvm-coverage`).  
Informational — no PR floor yet.

## How to reproduce

```bash
make uvm-coverage
# → build/coverage/uvm/coverage_uvm.txt
# → build/coverage/uvm/annotate/
```

## Results (2026-08-01, post PLIC/JTAG fixes)

### Run status

| Lane | Result |
|------|--------|
| UVM decompress smoke | PASS (~1066 txns, ref-model scoreboard, fcov bins) |
| UVM platform asm regress | **76/76 PASS** |
| `sisDecompress.sv` (L0 only) | **98.9%** (only unreachable `unique case` default) |
| Merged DUT annotate | **86.3%** hit (2045/2370 points on `sis*.sv`) |

### Per-module (merged annotate, lowest first)

| Module | Coverage | Gap / next step |
|--------|----------|-----------------|
| `sisDm` | ~19% | Full DMI/abstract-command VIP |
| `sisJtagDtm` | ~71% (was ~36%) | TAP smoke covers SHIFT-DR; IR→DMI path incomplete in DTM RTL |
| `sisPlic` | ~67% | Fabric window + claim/threshold test fixed; more priority/source corners left |
| `sisRegFile` dbg_* | mid | Needs DM abstract access |
| `sisPlatformTop` AXI | mid | Default UVM TB uses `USE_AXIL=0` |
| `sisRvCore` dbg_* | mid | Needs DM VIP |
| `sisDecompress` | ~98–99% | L0 closed |
| `sisDecode` | 100% | Closed |

### Functional bins (decompress scoreboard `DEC_FC`)

Printed each L0 run: legal_c / illegal / uncompressed + per-quadrant + funct3 histogram.

## Test / RTL improvements from this pass

1. Expanded decompress UVM directed + random stimulus + golden ref model.
2. Fixed PLIC fabric decode `0x0C00_0000–0x0C3F_FFFF` so threshold/claim are reachable.
3. Fixed `test_plic_irq.S` to use standard claim/threshold addresses + readbacks.
4. Added minimal JTAG TAP smoke agent (bitbang IDLE↔SHIFT-DR).
5. `make uvm-coverage` / CI artifact `coverage-uvm`.
