#!/usr/bin/env python3
"""Summarize Verilator --annotate output for DUT RTL (sis*.sv / rtl/)."""
from __future__ import annotations

import argparse
import re
from pathlib import Path


def parse_annotate(path: Path):
    hit = miss = 0
    uncovered = []
    for i, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
        if line.startswith("%00"):
            miss += 1
            uncovered.append((i, line[7:140].rstrip()))
            continue
        m = re.match(r"^ {0,5}(\d+)\s", line)
        if not m:
            continue
        cnt = int(m.group(1))
        if cnt > 0:
            hit += 1
        else:
            miss += 1
            uncovered.append((i, line[6:140].rstrip()))
    return hit, miss, uncovered


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("annotate_dir")
    ap.add_argument("--report", required=True)
    args = ap.parse_args()
    ann = Path(args.annotate_dir)
    report = Path(args.report)

    files = sorted({*ann.glob("sis*.sv"), *ann.glob("sis*.svh")})
    # Prefer DUT RTL names; fall back to any non-uvm annotate
    if not files:
        files = [p for p in sorted(ann.rglob("*.sv")) if "uvm_" not in p.name]

    rows = []
    th = tm = 0
    for f in files:
        h, m, unc = parse_annotate(f)
        if h + m == 0:
            continue
        th += h
        tm += m
        pct = 100.0 * h / (h + m)
        rows.append((pct, h, m, f.name, unc[:15]))
    rows.sort(key=lambda r: (r[0], r[3]))

    with report.open("a") as fh:
        fh.write("\n=== DUT annotate summary ===\n")
        if th + tm:
            fh.write(f"TOTAL hit={th} miss={tm} pct={100.0*th/(th+tm):.2f}\n")
        else:
            fh.write("TOTAL hit=0 miss=0\n")
        fh.write("\nPer-file (lowest first):\n")
        for pct, h, m, name, unc in rows:
            fh.write(f"  {pct:6.2f}%  {h:5d}/{(h+m):<5d}  {name}\n")
        fh.write("\nUncovered samples:\n")
        for pct, h, m, name, unc in rows:
            if pct >= 99.9 or not unc:
                continue
            fh.write(f"\n-- {name} ({pct:.1f}%) --\n")
            for ln, src in unc:
                fh.write(f"  L{ln}: {src}\n")
    print(report.read_text())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
