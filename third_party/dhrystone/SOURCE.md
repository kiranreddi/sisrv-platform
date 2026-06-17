# Dhrystone Source Pin

- Upstream archive: <https://github.com/Keith-S-Thompson/dhrystone>
- Commit: `66bb9df1a5dea67f33437b856bf68ae52bd5c90f`
- Version: Dhrystone C 2.1 (`v2.1/dhry.h`, `v2.1/dhry_1.c`, `v2.1/dhry_2.c`)
- Original date: May 25, 1988

The files in this directory are upstream Dhrystone 2.1 sources and rationale.
sisrv-platform benchmark support lives under `sw/bench/dhrystone/` and keeps the
timed Dhrystone statement sequence unchanged.

Reported sisrv-platform Dhrystone results are internal cycle-normalized Verilator
measurements. They are intended for engineering comparison with full compiler,
ISA, simulator, and memory conditions recorded.
