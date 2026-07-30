# Multi-simulator verification

The commercial-simulator lane uses `tb/sv/sisTbTop.sv`, which is independent of
the Verilator C++ harness. Test images are built with `make sw`.

## Local commands

```sh
make sim-questa TEST=test_pass
make sim-vcs TEST=test_pass
make sim-xcelium TEST=test_pass
```

Each command requires the site tool environment and writes results below
`build/multisim`. The scripts stage the requested image as `rom.hex`, because
the platform's memory image is a top-level parameter; the original path is also
accepted through `+ROM_HEX` and recorded by the testbench.

## LSF regression

```sh
make regress-questa
```

The driver builds all images before submission and uses an LSF array throttle of
five concurrent jobs. It waits for array completion and prints a result table.
The VCS and Xcelium regression targets use the same per-tool driver.

## Questa Formal

```sh
make formal-questa
```

This submits the initial core AutoCheck lane through LSF. The existing property
wrappers are also wired through `verification/formal/questa/propcheck.do`.
Both decks are intentionally separate so a tool-version issue in one lane does
not hide the result of the other.

## Tool guards and waivers

No RTL tool guards were added. No findings are waived by this bring-up
scaffold; any tool or license failure is reported as a failed lane.
