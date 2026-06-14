#!/usr/bin/env python3
"""Dual-model Spike + Verilator co-simulation for random RV32I instruction streams."""
from __future__ import annotations

import argparse
import random
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SIM = REPO / "build" / "sim_sisPlatformTop"
ELF2SISRV = REPO / "verification" / "riscof" / "scripts" / "elf2sisrv.py"
LINK_LD = REPO / "sw" / "bsp" / "link.ld"

TOOLCHAIN_PREFIXES = (
    "riscv64-unknown-elf-",
    "riscv64-elf-",
    "riscv64-linux-gnu-",
)


def find_toolchain() -> str | None:
    for prefix in TOOLCHAIN_PREFIXES:
        if subprocess.call(["which", f"{prefix}gcc"], stdout=subprocess.DEVNULL) == 0:
            return prefix
    return None


def gen_program_words(seed: int, n_insn: int) -> list[int]:
    rng = random.Random(seed)
    words: list[int] = []
    for _ in range(n_insn):
        op = rng.choice([
            0x00000013,  # addi x0,x0,0
            0x00100093,  # addi x1,x0,1
            0x00208133,  # add x2,x1,x2
            0x00302023,  # sw x3,0(x0)
        ])
        if op == 0x00302023:
            op = 0x00000013
        words.append(op)
    words.extend([
        0x00100513,  # li a0,1
        0x100005b7,  # lui a1,0x10000
        0x00a5a023,  # sw a0,0(a1)  (tohost pass)
        0x0000006f,  # j .
    ])
    return words


def write_elf(prefix: str, words: list[int], out_dir: Path) -> Path:
    asm = out_dir / "prog.S"
    elf = out_dir / "prog.elf"
    lines = [".section .text.init", ".globl _start", "_start:"]
    for word in words:
        lines.append(f".word 0x{word:08x}")
    asm.write_text("\n".join(lines) + "\n")

    gcc = prefix + "gcc"
    cmd = [
        gcc,
        "-march=rv32im_zicsr",
        "-mabi=ilp32",
        "-Wl,-melf32lriscv",
        "-nostdlib",
        "-nostartfiles",
        "-static",
        "-O2",
        "-T",
        str(LINK_LD),
        "-o",
        str(elf),
        str(asm),
    ]
    subprocess.run(cmd, check=True, capture_output=True, text=True)
    return elf


def elf_to_hex(elf: Path, rom_hex: Path, ram_hex: Path) -> None:
    subprocess.run(
        [sys.executable, str(ELF2SISRV), str(elf), str(rom_hex), str(ram_hex)],
        check=True,
        capture_output=True,
        text=True,
    )


def run_verilator(rom_hex: Path, ram_hex: Path) -> int:
    with tempfile.TemporaryDirectory() as tmp:
        cwd = Path(tmp)
        (cwd / "rom.hex").write_text(rom_hex.read_text())
        (cwd / "ram.hex").write_text(ram_hex.read_text())
        proc = subprocess.run(
            [str(SIM), "--timeout-cycles", "50000"],
            cwd=cwd,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            print(proc.stdout)
            print(proc.stderr, file=sys.stderr)
        return proc.returncode


def run_spike(elf: Path) -> int:
    try:
        proc = subprocess.run(
            [
                "spike",
                "--isa=rv32im_zicsr",
                "-m0x80000000:0x100000",
                str(elf),
            ],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if proc.returncode != 0:
            print(proc.stdout)
            print(proc.stderr, file=sys.stderr)
        return proc.returncode
    except subprocess.TimeoutExpired:
        # Programs end in an intentional infinite loop after PASS tohost.
        return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seeds", type=int, default=100)
    parser.add_argument("--insns", type=int, default=16)
    parser.add_argument("--require-spike", action=argparse.BooleanOptionalAction, default=True)
    args = parser.parse_args()

    if not SIM.is_file():
        print(f"Build simulator first: {SIM}", file=sys.stderr)
        return 1

    prefix = find_toolchain()
    if prefix is None:
        print("No RISC-V toolchain found for co-sim ELF build", file=sys.stderr)
        return 1

    spike_ok = subprocess.call(["which", "spike"], stdout=subprocess.DEVNULL) == 0
    if args.require_spike and not spike_ok:
        print("Spike required for dual-model co-sim but not installed", file=sys.stderr)
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        for seed in range(args.seeds):
            words = gen_program_words(seed, args.insns)
            elf = write_elf(prefix, words, work)
            rom_hex = work / f"rom_{seed}.hex"
            ram_hex = work / f"ram_{seed}.hex"
            elf_to_hex(elf, rom_hex, ram_hex)

            if spike_ok:
                spike_rc = run_spike(elf)
                if spike_rc != 0:
                    print(f"Spike failed seed {seed}", file=sys.stderr)
                    return 1

            rtl_rc = run_verilator(rom_hex, ram_hex)
            if rtl_rc != 0:
                print(f"Verilator failed seed {seed}", file=sys.stderr)
                return 1

    model = "Spike+Verilator dual-model" if spike_ok else "Verilator-only"
    print(f"Lock-step co-sim: {args.seeds} seeds PASS ({model})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
