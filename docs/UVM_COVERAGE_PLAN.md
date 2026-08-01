# UVM / Coverage Verification Plan (locked)

Canonical identity: **Kiran Tathekalva** `<kiranreddi.t@gmail.com>`.  
No `Co-authored-by` trailers. See `AGENTS.md`.

## Decisions (locked)

| Topic | Decision |
|-------|----------|
| Primary UVM sim | **Verilator 5.050+** with chipsalliance `uvm-verilator` (`third_party/uvm`) |
| CI | UVM smoke (`make uvm-decompress`, `make uvm-platform`) **gates PRs** once green; cocotb/formal/asm remain |
| Commercial sims | Same UVM filelists on Questa/VCS/Xcelium (LSF); not required for PR gate |
| Functional coverage on Verilator | Python bins and/or SVA `cover` (no SV `covergroup`) |
| Code coverage | Verilator `--coverage` via `UVM_COVERAGE=1` / `make coverage-unit` |
| Bottom-up stitch | L0 agents first (Decompress shipped) → tohost/platform → bus/IRQ/JTAG |
| SV non-UVM TB | `tb/sv/sisTbTop.sv` remains directed smoke; UVM platform TB wraps same DUT |
| Bugs | GitHub Issues (`.github/ISSUE_TEMPLATE/bug_rtl.yml`) |
| `sisTimer` | Deleted (CLINT owns timer) |

## Tree

```text
verification/uvm/
  vip/decompress/   agent + scoreboard + sequences
  vip/tohost/       platform pass/fail monitor
  env/              decompress_env, platform_env
  tests/            sis_decompress_smoke_test, sis_platform_tohost_test
  tb/               sis_uvm_decompress_tb, sis_uvm_platform_tb
third_party/uvm/    Accellera UVM (uvm-2017-1.0-vlt)
```

## Commands

```bash
make uvm-decompress                          # L0 UVM smoke
make sw && make uvm-platform                 # platform UVM + test_pass.hex
make uvm-platform-regress                    # all asm images via UVM platform TB
UVM_COVERAGE=1 make uvm-decompress           # code coverage (single smoke)
make uvm-coverage                            # L0 + full platform regress, merge/annotate
# Reports: build/coverage/uvm/coverage_uvm.txt (+ annotate/)
```

## Coverage notes

- Verilator `--coverage` (line/toggle/branch/expr). No SV `covergroup` on Verilator.
- UVM decompress scoreboard also prints Python-style functional bins (`DEC_FC`).
- Constrained `randomize()` needs z3 on Verilator; sequences use `$urandom` instead.
- Annotate noise includes UVM library; DUT summary filters `sis*.sv`.

## Phase order

1. **Ship UVM env on Verilator** (done): Decompress agent + platform tohost env + CI.
2. **Enable coverage + close L0 gaps** (this work): `make uvm-coverage`, expand decompress seq/scoreboard.
3. **B2**: keep 64-seed imac+U/PMP lock-step smoke; fix divergences via Issues.
4. Grow VIP: corebus/AXI agents, IRQ, then JTAG/DM.
5. Coverage floors only after measured baselines.

## Non-goals

- Rebuilding UVM agents for ALU/RegFile/Decode already closed by formal+cocotb (unless coverage demands)
- Full-`sisRvCore` GDS TB
- EEMBC-certified numbers
