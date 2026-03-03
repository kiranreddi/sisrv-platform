# sisrv-platform

ASIC-first, open-source end-to-end RISC-V (RV32) platform using **Verilator** as the primary simulator.

This repo is intentionally structured to keep the CPU core protocol-agnostic (simple internal req/resp bus),
while integrating outward via an **AXI4-Lite master bridge**. The development plan is milestone-driven so the
system is runnable at every step.

## Default platform choices (MVP)
- Address map
  - ROM:  `0x0000_0000` (reset vector)
  - RAM:  `0x8000_0000`
  - MMIO: `0x1000_0000` (UART, timer, tohost)
- External bus: **AXI4-Lite**, single outstanding read + single outstanding write (MVP)
- Privilege: **M-mode only** (minimal CSRs added after core runs)
- ISA MVP: **RV32I**, multi-cycle FSM core first; add RV32M later

## Milestones
See:
- `docs/PLAN.md` (complete milestone plan + exit criteria)
- `docs/MEMORY_MAP.md`
- `docs/INTERFACES.md` (internal bus + AXI-Lite profile)
- `docs/VERIFICATION.md`

## Quickstart (placeholder)
This repo ships as a *starter package*: stubs + docs + checklists. The Makefile targets are scaffolding.

Typical intended commands:
- `make sim`      (build + run verilator simulation)
- `make wave`     (open GTKWAVE on last run)
- `make sw`       (build bare-metal tests)
- `make regress`  (run Tier-1 suite)
- `make lint`     (verilator lint / verible)

## Directory layout
- `rtl/`    synthesizable RTL (ASIC-first)
- `tb/`     verilator harness + models
- `sw/`     BSP + asm/C tests
- `formal/` sby proofs (added as milestones progress)
- `scripts/` helper scripts
- `docs/`   architecture + plan

## License
Pick a license (Apache-2.0 / BSD-2-Clause / MIT). This package does not include third-party IP.
