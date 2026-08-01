# Prebuilt software artifacts (no local RISC-V toolchain)

Your Linux host may block installing `gcc-riscv*`. CI builds every directed asm
ROM image and uploads a tarball you can download and use for:

- commercial **UVM** / Questa / VCS / Xcelium sims (`tb/sv/sisTbTop.sv` and future UVM envs)
- **Verilator** directed runs (`make run-<test>`)
- future **cocotb** platform-level tests that preload ROM hex

Current unit-level cocotb (ALU/RegFile/Decode/CSR/AXI/PMP) does **not** need these
images. Platform-level cocotb/UVM will.

## Artifact contents

| Path | Purpose |
|------|---------|
| `tests/<name>.hex` | Little-endian word hex for `$readmemh` / `ROM_INIT_FILE` |
| `tests/<name>.elf` | ELF (Spike, gdb, riscv-dv post-process) |
| `tests/<name>.bin` | Flat binary |
| `tests/<name>.objdump` | Disassembly (when produced) |
| `ram.hex` | Empty RAM init |
| `manifest.json` | Index + toolchain/git metadata |

Artifact name in GitHub Actions: **`sisrv-sw-artifacts`**  
File inside: **`sisrv-sw-artifacts.tar.gz`**

## Download from CI

### Option A — helper script (`gh` required)

```bash
# Latest successful CI run
./scripts/fetch_sw_artifacts.sh

# Specific run id (Actions → CI → open the run → copy ID from URL)
./scripts/fetch_sw_artifacts.sh --run-id 30611181758

# Install into build/tests/
make sw-from-artifacts SW_ARTIFACTS_TGZ=build/sw-artifacts/sisrv-sw-artifacts.tar.gz
```

### Option B — GitHub UI

1. Open Actions → **CI** → pick a green run that includes job **Software Artifacts (UVM/cocotb)**.
2. Download artifact **`sisrv-sw-artifacts`**.
3. Unpack / install:

```bash
make sw-from-artifacts SW_ARTIFACTS_TGZ=/path/to/sisrv-sw-artifacts.tar.gz
```

## Use with UVM / commercial simulators

After `sw-from-artifacts`:

```bash
cp build/tests/test_pass.hex rom.hex
: > ram.hex
# Questa / VCS / Xcelium — existing helpers:
make sim-questa SIM_TEST=test_pass   # still needs site tool modules
# Or your UVM testbench:
#   +ROM_HEX=rom.hex +RAM_HEX=ram.hex +TIMEOUT_CYCLES=1000000
```

Point any future UVM sequence at `build/tests/<name>.hex` the same way the
commercial harness stages `rom.hex` today (`verification/sim/run_*.sh`).

## Use with Verilator (no toolchain)

```bash
make sw-from-artifacts SW_ARTIFACTS_TGZ=build/sw-artifacts/sisrv-sw-artifacts.tar.gz
make run-test_pass          # needs Verilator, not RISC-V gcc
make run-test_rv32m
```

## Produce the package yourself (CI or unrestricted host)

```bash
# Requires RISC-V gcc on PATH (CI uses gcc-riscv64-linux-gnu)
make sw-artifacts
# → build/sw-artifacts/sisrv-sw-artifacts.tar.gz
```

## Notes

- Images match the asm under `sw/tests/asm/` at the git SHA recorded in `manifest.json`.
- Re-download after RTL/SW changes so hex stays in sync with the DUT.
- Benchmark CoreMark/Dhrystone ELFs are **not** in this package yet (separate, larger build).
- riscv-dv-generated programs are also not included until a UVM/riscv-dv lane lands;
  when they do, CI should append them to the same artifact layout.
