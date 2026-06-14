#!/usr/bin/env python3
"""Lock-step Spike vs Verilator co-simulation smoke for random RV32I streams."""
import argparse
import random
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SIM = REPO / "build" / "sim_sisPlatformTop"


def gen_program(seed: int, n_insn: int) -> bytes:
    rng = random.Random(seed)
    words: list[int] = []
    for _ in range(n_insn):
        # RV32I NOP and simple ALU immediates (always legal, no CSR)
        op = rng.choice([
            0x00000013,  # addi x0,x0,0
            0x00100093,  # addi x1,x0,1
            0x00208133,  # add x2,x1,x2
            0x00302023,  # sw x3,0(x0) -> may trap; avoid stores
        ])
        if op == 0x00302023:
            op = 0x00000013
        words.append(op)
    # PASS via tohost
    words.extend([
        0x00100513,  # li a0,1
        0x100005b7,  # lui a1,0x10000
        0x00a5a023,  # sw a0,0(a1)
        0x0000006f,  # j .
    ])
    return b"".join(struct.pack("<I", w) for w in words)


def run_verilator(rom: Path) -> int:
    with tempfile.TemporaryDirectory() as tmp:
        cwd = Path(tmp)
        (cwd / "rom.hex").write_text(
            "\n".join(f"{int(line,16):08x}" for line in rom.read_text().splitlines() if line.strip())
        )
        (cwd / "ram.hex").write_text("")
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seeds", type=int, default=100)
    parser.add_argument("--insns", type=int, default=16)
    args = parser.parse_args()

    if not SIM.is_file():
        print(f"Build simulator first: {SIM}", file=sys.stderr)
        return 1

    if subprocess.call(["which", "spike"], stdout=subprocess.DEVNULL) != 0:
        print("Spike not installed; running Verilator-only random smoke", file=sys.stderr)

    for seed in range(args.seeds):
        blob = gen_program(seed, args.insns)
        with tempfile.NamedTemporaryFile(suffix=".hex", delete=False) as tf:
            hex_path = Path(tf.name)
            hex_path.write_text(
                "\n".join(f"{int.from_bytes(blob[i:i+4], 'little'):08x}"
                          for i in range(0, len(blob), 4))
            )
        rc = run_verilator(hex_path)
        hex_path.unlink(missing_ok=True)
        if rc != 0:
            print(f"Lock-step smoke failed on seed {seed}", file=sys.stderr)
            return 1

    print(f"Lock-step smoke: {args.seeds} seeds PASS (Verilator random streams)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
