#!/usr/bin/env python3
"""Build, calibrate, run, and summarize sisrv-platform benchmarks."""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build" / "bench"
EMPTY_RAM = BUILD / "empty_ram.hex"
RV_ABI = "ilp32"


def run(cmd: list[str], *, cwd: Path = ROOT, stdout: Path | None = None) -> str:
    if stdout is None:
        proc = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
        if proc.returncode != 0:
            sys.stderr.write(proc.stdout)
            sys.stderr.write(proc.stderr)
            raise SystemExit(proc.returncode)
        return proc.stdout
    with stdout.open("w", encoding="utf-8") as f:
        proc = subprocess.run(cmd, cwd=cwd, text=True, stdout=f, stderr=subprocess.STDOUT)
    if proc.returncode != 0:
        sys.stderr.write(stdout.read_text(encoding="utf-8", errors="replace"))
        raise SystemExit(proc.returncode)
    return stdout.read_text(encoding="utf-8", errors="replace")


def toolchain_version(gcc: str) -> str:
    try:
        return run([gcc, "--version"]).splitlines()[0]
    except SystemExit:
        return "unknown"


def git_commit() -> str:
    try:
        return run(["git", "rev-parse", "HEAD"]).strip()
    except SystemExit:
        return "unknown"


def common_flags(isa: str) -> list[str]:
    return [
        f"-march={isa}",
        f"-mabi={RV_ABI}",
        "-O2",
        "-nostdlib",
        "-nostartfiles",
        "-ffreestanding",
        "-static",
        "-fno-pic",
        "-fno-pie",
        "-no-pie",
        "-fno-builtin",
        "-Wl,--build-id=none",
    ]


def objcopy_to_hex(objcopy: str, elf: Path, hex_path: Path) -> None:
    bin_path = hex_path.with_suffix(".bin")
    run([objcopy, "-O", "binary", str(elf), str(bin_path)])
    data = bin_path.read_bytes()
    lines = [
        f"{int.from_bytes(data[i:i + 4], 'little'):08x}"
        for i in range(0, len(data), 4)
    ]
    hex_path.write_text("\n".join(lines) + "\n", encoding="ascii")


def run_sim(sim: str, hex_path: Path, log_path: Path, timeout_cycles: int) -> str:
    EMPTY_RAM.write_text("00000000\n", encoding="ascii")
    return run(
        [
            sim,
            "--rom",
            str(hex_path),
            "--ram",
            str(EMPTY_RAM),
            "--timeout-cycles",
            str(timeout_cycles),
        ],
        stdout=log_path,
    )


def parse_int_line(text: str, key: str) -> int:
    m = re.search(rf"^{re.escape(key)}\s*:?\s*([0-9]+)", text, re.MULTILINE)
    if not m:
        raise RuntimeError(f"missing {key!r} in benchmark log")
    return int(m.group(1))


def parse_sisrv_value(text: str, key: str) -> str:
    m = re.search(rf"^SISRV_BENCH {re.escape(key)}=([^\n]+)", text, re.MULTILINE)
    if not m:
        raise RuntimeError(f"missing SISRV_BENCH {key!r} in benchmark log")
    return m.group(1).strip()


def build_coremark(
    gcc: str,
    objcopy: str,
    isa: str,
    variant: str,
    iterations: int,
    seeds: tuple[int, int, int],
    ticks_per_sec: int,
) -> Path:
    out_dir = BUILD / "coremark" / isa / variant
    out_dir.mkdir(parents=True, exist_ok=True)
    elf = out_dir / "coremark.elf"
    hex_path = out_dir / "coremark.hex"
    compiler_flags = f"{isa} -mabi={RV_ABI} -O2"
    sources = [
        ROOT / "sw/bsp/crt0.S",
        ROOT / "sw/bench/common/sisrv_bench.c",
        ROOT / "sw/bench/coremark/core_portme.c",
        ROOT / "third_party/coremark/core_list_join.c",
        ROOT / "third_party/coremark/core_main.c",
        ROOT / "third_party/coremark/core_matrix.c",
        ROOT / "third_party/coremark/core_state.c",
        ROOT / "third_party/coremark/core_util.c",
    ]
    cmd = [
        gcc,
        *common_flags(isa),
        "-I",
        str(ROOT / "sw/bench/common"),
        "-I",
        str(ROOT / "sw/bench/coremark"),
        "-I",
        str(ROOT / "third_party/coremark"),
        "-DTOTAL_DATA_SIZE=2000",
        f"-DCOREMARK_ITERATIONS={iterations}",
        f"-DCOREMARK_SEED1={seeds[0]}",
        f"-DCOREMARK_SEED2={seeds[1]}",
        f"-DCOREMARK_SEED3={seeds[2]}",
        f"-DCOREMARK_TICKS_PER_SEC={ticks_per_sec}",
        f'-DCOMPILER_FLAGS="{compiler_flags}"',
        "-T",
        str(ROOT / "sw/bsp/link.ld"),
        "-o",
        str(elf),
        *map(str, sources),
        "-lgcc",
    ]
    run(cmd)
    objcopy_to_hex(objcopy, elf, hex_path)
    return hex_path


def compile_obj(gcc: str, isa: str, source: Path, obj: Path, extra: list[str]) -> None:
    obj.parent.mkdir(parents=True, exist_ok=True)
    run([
        gcc,
        *common_flags(isa),
        "-I",
        str(ROOT / "sw/bench/common"),
        "-I",
        str(ROOT / "sw/bench/include"),
        "-I",
        str(ROOT / "third_party/dhrystone"),
        *extra,
        "-c",
        str(source),
        "-o",
        str(obj),
    ])


def build_dhrystone(gcc: str, objcopy: str, isa: str, iterations: int) -> Path:
    out_dir = BUILD / "dhrystone" / isa / f"iter-{iterations}"
    out_dir.mkdir(parents=True, exist_ok=True)
    objs = {
        "crt0": out_dir / "crt0.o",
        "common": out_dir / "sisrv_bench.o",
        "wrapper": out_dir / "dhry_sisrv.o",
        "dhry_1": out_dir / "dhry_1.o",
        "dhry_2": out_dir / "dhry_2.o",
    }
    compile_obj(gcc, isa, ROOT / "sw/bsp/crt0.S", objs["crt0"], [])
    compile_obj(gcc, isa, ROOT / "sw/bench/common/sisrv_bench.c", objs["common"], ["-std=gnu99"])
    compile_obj(
        gcc,
        isa,
        ROOT / "sw/bench/dhrystone/dhry_sisrv.c",
        objs["wrapper"],
        ["-std=gnu99", f"-DDHRY_ITERATIONS={iterations}", "-DTIME"],
    )
    old_c_flags = [
        "-std=gnu89",
        "-Wno-implicit-int",
        "-Wno-implicit-function-declaration",
        "-Wno-return-type",
        "-Wno-builtin-declaration-mismatch",
        "-Dmain=dhry_upstream_main",
        "-DTIME",
    ]
    compile_obj(gcc, isa, ROOT / "third_party/dhrystone/dhry_1.c", objs["dhry_1"], old_c_flags)
    compile_obj(gcc, isa, ROOT / "third_party/dhrystone/dhry_2.c", objs["dhry_2"], old_c_flags)
    elf = out_dir / "dhrystone.elf"
    hex_path = out_dir / "dhrystone.hex"
    run([
        gcc,
        *common_flags(isa),
        "-T",
        str(ROOT / "sw/bsp/link.ld"),
        "-o",
        str(elf),
        *map(str, objs.values()),
        "-lgcc",
    ])
    objcopy_to_hex(objcopy, elf, hex_path)
    return hex_path


def run_coremark_for_isa(args: argparse.Namespace, gcc: str, objcopy: str, isa: str) -> list[dict]:
    min_cycles = 10_000_000 if not args.smoke else 10_000
    ticks_per_sec = 1_000_000 if not args.smoke else 1_000
    timeout = args.timeout_cycles
    pilot_hex = build_coremark(gcc, objcopy, isa, "pilot", 1, (0, 0, 0x66), ticks_per_sec)
    pilot_log = BUILD / "coremark" / isa / "pilot.log"
    pilot_text = run_sim(args.sim, pilot_hex, pilot_log, timeout)
    pilot_cycles = parse_int_line(pilot_text, "Total ticks")
    target_cycles = math.ceil(min_cycles * 1.02)
    iterations = max(1, math.ceil(target_cycles / max(1, pilot_cycles)))
    if args.smoke:
        iterations = max(1, min(iterations, 2))

    variants = [
        ("performance", (0, 0, 0x66)),
        ("validation", (0x3415, 0x3415, 0x66)),
    ]
    rows: list[dict] = []
    for variant, seeds in variants:
        hex_path = build_coremark(gcc, objcopy, isa, variant, iterations, seeds, ticks_per_sec)
        log_path = BUILD / "coremark" / isa / f"{variant}.log"
        text = run_sim(args.sim, hex_path, log_path, timeout)
        cycles = parse_int_line(text, "Total ticks")
        reported_iterations = parse_int_line(text, "Iterations")
        validated = "Correct operation validated." in text
        row = {
            "benchmark": "coremark",
            "isa": isa,
            "variant": variant,
            "seeds": list(seeds),
            "iterations": reported_iterations,
            "cycles": cycles,
            "coremark_per_mhz": reported_iterations * 1_000_000 / cycles,
            "cycles_per_iteration": cycles / reported_iterations,
            "validated": validated,
            "log": str(log_path.relative_to(ROOT)),
        }
        if not args.smoke and cycles < min_cycles:
            raise RuntimeError(f"CoreMark {isa}/{variant} ran {cycles} cycles, below {min_cycles}")
        if not validated:
            raise RuntimeError(f"CoreMark {isa}/{variant} validation failed")
        rows.append(row)
    return rows


def run_dhrystone_for_isa(args: argparse.Namespace, gcc: str, objcopy: str, isa: str) -> dict:
    min_cycles = 2_000_000 if not args.smoke else 10_000
    timeout = args.timeout_cycles
    pilot_iter = 20 if not args.smoke else 2
    pilot_hex = build_dhrystone(gcc, objcopy, isa, pilot_iter)
    pilot_log = BUILD / "dhrystone" / isa / "pilot.log"
    pilot_text = run_sim(args.sim, pilot_hex, pilot_log, timeout)
    pilot_cycles = int(parse_sisrv_value(pilot_text, "cycles"))
    cycles_per_iter = max(1, pilot_cycles // pilot_iter)
    target_cycles = math.ceil(min_cycles * 1.02)
    iterations = max(1, math.ceil(target_cycles / cycles_per_iter))
    if args.smoke:
        iterations = max(2, min(iterations, 10))

    hex_path = build_dhrystone(gcc, objcopy, isa, iterations)
    log_path = BUILD / "dhrystone" / isa / "dhrystone.log"
    text = run_sim(args.sim, hex_path, log_path, timeout)
    if parse_sisrv_value(text, "benchmark") != "dhrystone":
        raise RuntimeError("missing Dhrystone benchmark marker")
    if "Validation        : PASS" not in text:
        raise RuntimeError(f"Dhrystone {isa} validation failed")
    cycles = int(parse_sisrv_value(text, "cycles"))
    if not args.smoke and cycles < min_cycles:
        raise RuntimeError(f"Dhrystone {isa} ran {cycles} cycles, below {min_cycles}")
    return {
        "benchmark": "dhrystone",
        "isa": isa,
        "iterations": int(parse_sisrv_value(text, "iterations")),
        "cycles": cycles,
        "instret": int(parse_sisrv_value(text, "instret")),
        "cycles_per_iteration": float(parse_sisrv_value(text, "cycles_per_iteration")),
        "instructions_per_iteration": float(parse_sisrv_value(text, "instructions_per_iteration")),
        "cpi": float(parse_sisrv_value(text, "cpi")),
        "dhrystones_per_sec_per_mhz": float(parse_sisrv_value(text, "dhrystones_per_sec_per_mhz")),
        "dmips_per_mhz": float(parse_sisrv_value(text, "dmips_per_mhz")),
        "validated": True,
        "log": str(log_path.relative_to(ROOT)),
    }


def write_summary(summary: dict) -> None:
    BUILD.mkdir(parents=True, exist_ok=True)
    path = BUILD / "summary.json"
    path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Wrote {path}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--benchmark", choices=["all", "coremark", "dhrystone"], required=True)
    parser.add_argument("--sim", required=True)
    parser.add_argument("--rv-prefix", default="riscv64-linux-gnu-")
    parser.add_argument("--isas", default="rv32imc_zicsr rv32im_zicsr")
    parser.add_argument("--timeout-cycles", type=int, default=60_000_000)
    parser.add_argument("--smoke", action="store_true")
    args = parser.parse_args()

    BUILD.mkdir(parents=True, exist_ok=True)
    gcc = args.rv_prefix + "gcc"
    objcopy = args.rv_prefix + "objcopy"
    isas = args.isas.split()

    summary: dict = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "git_commit": git_commit(),
        "toolchain": toolchain_version(gcc),
        "simulator": args.sim,
        "mode": "smoke" if args.smoke else "publish",
        "memory": "direct corebus ROM/RAM, ROM 64 KiB at 0x00000000, RAM 256 KiB at 0x80000000",
        "compiler_flags": "-O2 -nostdlib -nostartfiles -ffreestanding -static -fno-pic -fno-pie -no-pie -fno-builtin",
        "results": [],
    }

    for isa in isas:
        if args.benchmark in ("all", "coremark"):
            summary["results"].extend(run_coremark_for_isa(args, gcc, objcopy, isa))
        if args.benchmark in ("all", "dhrystone"):
            summary["results"].append(run_dhrystone_for_isa(args, gcc, objcopy, isa))

    write_summary(summary)
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
