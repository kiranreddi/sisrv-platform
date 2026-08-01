# sisrv-platform UVM environment (Verilator-first)

Bottom-up UVM verification environment intended to run on **Verilator 5.050+**
using the chipsalliance `uvm-verilator` tree (`third_party/uvm`, branch
`uvm-2017-1.0-vlt`). The same filelists are usable on Questa/VCS/Xcelium.

## Layout

```text
verification/uvm/
  vip/decompress/   L0 agent (driver/monitor/scoreboard/sequences)
  vip/tohost/       Platform tohost monitor agent
  env/              decompress + platform envs
  tests/            UVM tests
  tb/               TB tops (unit + platform)
  filelist_*.f      Verilator/commercial filelists
```

`tb/sv/sisTbTop.sv` remains the non-UVM commercial smoke TB. The UVM platform
TB (`sis_uvm_platform_tb`) wraps the same `sisPlatformTop` DUT.

## Quick start

```bash
# UVM library (vendored; refresh with scripts/ci/fetch_uvm.sh)
test -f third_party/uvm/src/uvm.sv

# L0: Decompress agent smoke
make uvm-decompress

# Platform: tohost-monitored directed image (needs hex)
make sw
make uvm-platform UVM_TEST=sis_platform_tohost_test \
  ROM_HEX=build/tests/test_pass.hex
```

## Plusargs

| Plusarg | Meaning |
|---------|---------|
| `+UVM_TESTNAME=` | UVM test class (default per target) |
| `+ROM_HEX=` / `+RAM_HEX=` | Firmware images (platform TB) |
| `+TIMEOUT_CYCLES=` | Platform timeout |

## Coverage

Enable Verilator code coverage with `UVM_COVERAGE=1 make uvm-decompress`.
Functional bins for Verilator remain Python/cocotb or SVA `cover` (no SV covergroups).
