#!/usr/bin/env python3
"""Retired-instruction Spike vs RTL lock-step co-simulation."""
from __future__ import annotations

import argparse
import os
from multiprocessing import Pool, cpu_count
import random
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SIM = Path(os.environ.get("COSIM_SIM", str(REPO / "obj_dir" / "sim_cosim_sisPlatformTop"))).resolve()
ELF2SISRV = REPO / "verification" / "riscof" / "scripts" / "elf2sisrv.py"
LINK_LD = REPO / "verification" / "cosim" / "link.ld"

TOOLCHAIN_PREFIXES = (
    "riscv64-unknown-elf-",
    "riscv64-elf-",
    "riscv64-linux-gnu-",
)

SPIKE_LINE = re.compile(
    r"core\s+\d+:\s+0x([0-9a-fA-F]+)\s+\(0x([0-9a-fA-F]+)\)"
)
RTL_LINE = re.compile(
    r"^([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+([0-9a-fA-F]+)\s+([0-9a-fA-F]+)$"
)


def find_toolchain() -> str | None:
    for prefix in TOOLCHAIN_PREFIXES:
        if subprocess.call(["which", f"{prefix}gcc"], stdout=subprocess.DEVNULL) == 0:
            return prefix
    return None


PROFILE_CONFIG = {
    "rv32im": {
        "march": "rv32im_zicsr",
        "spike_isa": "rv32im_zicsr",
        "spike_priv": None,
        "spike_pmpregions": None,
    },
    "rv32imac": {
        "march": "rv32imac_zicsr",
        "spike_isa": "rv32imac_zicsr",
        "spike_priv": None,
        "spike_pmpregions": None,
    },
    "rv32imac-u-pmp": {
        "march": "rv32imac_zicsr",
        "spike_isa": "rv32imac_zicsr",
        "spike_priv": "mu",
        "spike_pmpregions": "8",
    },
}


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
    words.append(0x0000006f)  # j .  (tail loop)
    return words


def gen_program_asm(seed: int, n_insn: int, profile: str) -> list[str]:
    if profile == "rv32im":
        return [f".word 0x{word:08x}" for word in gen_program_words(seed, n_insn)]

    rng = random.Random(seed)
    lines = [
        ".option push",
        ".option rvc",
        "li x4, 0x80000000",
        "li x5, 1",
        "li x6, 2",
        "sw x0, 0(x4)",
    ]

    if profile == "rv32imac-u-pmp":
        lines = [
            ".option push",
            ".option rvc",
            "li x4, -1",
            "csrw pmpaddr0, x4",
            "li x4, 0x1f",
            "csrw pmpcfg0, x4",
            "la x4, 1f",
            "csrw mepc, x4",
            "csrr x4, mstatus",
            "li x5, 0xffffe7ff",
            "and x4, x4, x5",
            "csrw mstatus, x4",
            "mret",
            "1:",
            "li x4, 0x80000000",
            "li x5, 1",
            "li x6, 2",
            "sw x0, 0(x4)",
        ]

    ops = [
        "addi x1, x1, 1",
        "addi x2, x2, -1",
        "add x3, x1, x2",
        "xor x6, x6, x5",
        "mul x7, x5, x6",
        "lw x8, 0(x4)",
        "sw x8, 4(x4)",
        "amoadd.w x0, x5, (x4)",
        "lr.w x9, (x4)",
        "sc.w x10, x5, (x4)",
        "c.nop",
        "c.addi x8, 1",
        "c.mv x9, x8",
    ]
    for _ in range(n_insn):
        lines.append(rng.choice(ops))
    lines.extend(["j .", ".option pop"])
    return lines


def write_elf(prefix: str, program_lines: list[str], march: str, out_dir: Path) -> Path:
    asm = out_dir / "prog.S"
    elf = out_dir / "prog.elf"
    lines = [".section .text.init", ".globl _start", "_start:"]
    lines.extend(program_lines)
    asm.write_text("\n".join(lines) + "\n")

    gcc = prefix + "gcc"
    cmd = [
        gcc,
        f"-march={march}",
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
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(proc.stdout, file=sys.stderr)
        print(proc.stderr, file=sys.stderr)
        proc.check_returncode()
    return elf


def elf_to_hex(elf: Path, rom_hex: Path, ram_hex: Path) -> None:
    subprocess.run(
        [sys.executable, str(ELF2SISRV), str(elf), str(rom_hex), str(ram_hex)],
        check=True,
        capture_output=True,
        text=True,
    )


def parse_spike_commits(text: str) -> list[tuple[int, int]]:
    commits: list[tuple[int, int]] = []
    for line in text.splitlines():
        match = SPIKE_LINE.search(line)
        if match:
            commits.append((int(match.group(1), 16), int(match.group(2), 16)))
    return commits


def parse_rtl_commits(path: Path) -> list[tuple[int, int]]:
    commits: list[tuple[int, int]] = []
    if not path.is_file():
        return commits
    for line in path.read_text().splitlines():
        match = RTL_LINE.match(line.strip())
        if match:
            commits.append((int(match.group(1), 16), int(match.group(2), 16)))
    return commits


def _as_str(data) -> str:
    if data is None:
        return ""
    if isinstance(data, bytes):
        return data.decode("utf-8", errors="replace")
    return str(data)


def spike_program_commits(text: str) -> list[tuple[int, int]]:
    commits = parse_spike_commits(text)
    # Drop spike's built-in boot trampoline (runs below the program at 0x2000).
    return [(pc, insn) for pc, insn in commits if pc >= 0x2000]


def run_spike(
    elf: Path,
    log_path: Path,
    spike_isa: str,
    spike_priv: str | None,
    spike_pmpregions: str | None,
) -> list[tuple[int, int]]:
    cmd = [
        "spike",
        f"--isa={spike_isa}",
        # Code runs from ROM at 0x2000 (platform instruction-fetch map; above spike's
        # reserved [0,0x1000) region). RAM is included for load/store/AMO profiles.
        "-m0x2000:0x1fe000,0x80000000:0x40000",
        "-l",
        str(elf),
    ]
    if spike_priv:
        cmd.insert(2, f"--priv={spike_priv}")
    if spike_pmpregions:
        cmd.insert(2, f"--pmpregions={spike_pmpregions}")
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=1,
        )
    except subprocess.TimeoutExpired as exc:
        log = _as_str(exc.stdout) + _as_str(exc.stderr)
        log_path.write_text(log)
        return spike_program_commits(log)

    log = _as_str(proc.stdout) + _as_str(proc.stderr)
    log_path.write_text(log)
    commits = spike_program_commits(log)
    if not commits and proc.returncode != 0:
        print(log, file=sys.stderr)
        # Embed spike's own message so it propagates through the worker pool.
        raise RuntimeError(
            f"Spike failed on {elf} (exit {proc.returncode}) cmd={' '.join(cmd)} :: "
            f"{log.strip()[:500]}"
        )
    if not commits:
        print(log, file=sys.stderr)
        raise RuntimeError(f"Spike produced no commit trace on {elf}")
    return commits


def run_verilator(rom_hex: Path, ram_hex: Path, commit_log: Path) -> list[tuple[int, int]]:
    with tempfile.TemporaryDirectory() as tmp:
        cwd = Path(tmp)
        (cwd / "rom.hex").write_text(rom_hex.read_text())
        (cwd / "ram.hex").write_text(ram_hex.read_text())
        proc = subprocess.run(
            [
                str(SIM),
                "--timeout-cycles",
                "1500",
                "--commit-log",
                str(commit_log),
            ],
            cwd=cwd,
            capture_output=True,
            text=True,
        )
        out = _as_str(proc.stdout) + _as_str(proc.stderr)
        if "FAIL" in out or "illegal" in out.lower():
            print(out, file=sys.stderr)
            raise RuntimeError("Verilator reported failure")
        if "TIMEOUT" not in out and proc.returncode != 0:
            print(out, file=sys.stderr)
            raise RuntimeError(f"Verilator exit {proc.returncode}")
        return parse_rtl_commits(commit_log)


def compare_commits(
    seed: int,
    spike_commits: list[tuple[int, int]],
    rtl_commits: list[tuple[int, int]],
    min_required: int,
) -> None:
    if not spike_commits:
        raise RuntimeError(f"seed {seed}: Spike produced no retired instructions")
    if not rtl_commits:
        raise RuntimeError(f"seed {seed}: RTL produced no retired instructions")

    limit = min(len(spike_commits), len(rtl_commits))
    if limit < min_required:
        raise RuntimeError(
            f"seed {seed}: insufficient retired instructions "
            f"(spike={len(spike_commits)} rtl={len(rtl_commits)} need>={min_required})"
        )

    for idx in range(limit):
        spc, sin = spike_commits[idx]
        rpc, rin = rtl_commits[idx]
        if spc != rpc or sin != rin:
            raise RuntimeError(
                f"seed {seed} mismatch at retire {idx}: "
                f"spike pc=0x{spc:08x} insn=0x{sin:08x} "
                f"rtl pc=0x{rpc:08x} insn=0x{rin:08x}"
            )


def run_one_seed(cfg: tuple[int, str, int, str, str]) -> str | None:
    seed, prefix, insns, sim_path, profile = cfg
    profile_cfg = PROFILE_CONFIG[profile]
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        program_lines = gen_program_asm(seed, insns, profile)
        elf = write_elf(prefix, program_lines, profile_cfg["march"], work)
        rom_hex = work / "rom.hex"
        ram_hex = work / "ram.hex"
        spike_log = work / "spike.log"
        rtl_log = work / "rtl.log"
        elf_to_hex(elf, rom_hex, ram_hex)

        spike_commits = run_spike(
            elf,
            spike_log,
            profile_cfg["spike_isa"],
            profile_cfg["spike_priv"],
            profile_cfg["spike_pmpregions"],
        )
        global SIM
        SIM = Path(sim_path)
        rtl_commits = run_verilator(rom_hex, ram_hex, rtl_log)
        try:
            compare_commits(seed, spike_commits, rtl_commits, insns)
        except RuntimeError as err:
            return str(err)
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seeds", type=int, default=10000)
    parser.add_argument("--insns", type=int, default=12)
    parser.add_argument("--jobs", type=int, default=min(8, cpu_count() or 4))
    parser.add_argument("--profile", choices=sorted(PROFILE_CONFIG), default="rv32im")
    parser.add_argument("--require-spike", action=argparse.BooleanOptionalAction, default=True)
    args = parser.parse_args()

    if not SIM.is_file():
        print(f"Build simulator first: {SIM}", file=sys.stderr)
        return 1

    prefix = find_toolchain()
    if prefix is None:
        print("No RISC-V toolchain found for co-sim ELF build", file=sys.stderr)
        return 1

    if args.require_spike and subprocess.call(["which", "spike"], stdout=subprocess.DEVNULL) != 0:
        print("Spike required for lock-step co-sim but not installed", file=sys.stderr)
        return 1

    sim_path = str(SIM)
    tasks = [(seed, prefix, args.insns, sim_path, args.profile) for seed in range(args.seeds)]
    completed = 0
    with Pool(processes=args.jobs) as pool:
        for err in pool.imap_unordered(run_one_seed, tasks, chunksize=16):
            completed += 1
            if err is not None:
                print(err, file=sys.stderr)
                pool.terminate()
                return 1
            if completed % 500 == 0:
                print(f"Lock-step progress: {completed}/{args.seeds} seeds")

    print(
        f"Lock-step co-sim: {args.seeds} seeds PASS profile={args.profile} "
        f"(retired-instruction Spike vs RTL)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
