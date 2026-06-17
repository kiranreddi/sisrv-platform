# EEMBC CoreMark Source Pin

- Upstream: <https://github.com/eembc/coremark>
- Version: `v1.01`
- Commit: `cfa9ab377835911f23d9b0831c7be302ed1f58de`
- Vendored files: benchmark sources, `coremark.h`, upstream `README.md`, and `LICENSE.md`.

The files in this directory are upstream benchmark files. sisrv-platform benchmark
support lives under `sw/bench/coremark/` and must not modify these sources.

Public CoreMark score publication has extra EEMBC run and reporting rules. The
sisrv-platform report is an internal cycle-normalized Verilator measurement, not
an official or certified EEMBC submission.
