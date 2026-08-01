#!/usr/bin/env bash
# Build and package RISC-V software images for offline UVM / cocotb / commercial sim.
# Run in CI (or any host with a RISC-V toolchain). Consumers without a local toolchain:
#   make sw-from-artifacts SW_ARTIFACTS_TGZ=sisrv-sw-artifacts.tar.gz
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT_DIR="${SW_ARTIFACTS_OUT:-${ROOT}/build/sw-artifacts}"
STAGING="${OUT_DIR}/staging"
TGZ="${SW_ARTIFACTS_TGZ:-${OUT_DIR}/sisrv-sw-artifacts.tar.gz}"

RV_PREFIX="${RV_PREFIX:-riscv64-linux-gnu-}"
if ! command -v "${RV_PREFIX}gcc" >/dev/null 2>&1; then
  if command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    RV_PREFIX=riscv64-unknown-elf-
  elif command -v riscv64-elf-gcc >/dev/null 2>&1; then
    RV_PREFIX=riscv64-elf-
  else
    echo "ERROR: no RISC-V gcc found (tried ${RV_PREFIX}gcc)" >&2
    exit 2
  fi
fi

echo "Using toolchain prefix: ${RV_PREFIX}"
"${RV_PREFIX}gcc" --version | head -1

echo "=== Building full asm image set (sw-all) ==="
make sw-all RV_PREFIX="${RV_PREFIX}"

if command -v "${RV_PREFIX}objdump" >/dev/null 2>&1; then
  echo "=== Generating objdumps ==="
  for elf in build/tests/*.elf; do
    [ -f "$elf" ] || continue
    base="$(basename "$elf" .elf)"
    "${RV_PREFIX}objdump" -d -M no-aliases "$elf" > "build/tests/${base}.objdump" || true
  done
fi

rm -rf "${STAGING}"
mkdir -p "${STAGING}/tests" "${STAGING}/meta"
: > "${STAGING}/ram.hex"

count=0
for hex in build/tests/*.hex; do
  [ -f "$hex" ] || continue
  base="$(basename "$hex" .hex)"
  cp -f "$hex" "${STAGING}/tests/${base}.hex"
  [ -f "build/tests/${base}.elf" ] && cp -f "build/tests/${base}.elf" "${STAGING}/tests/${base}.elf"
  [ -f "build/tests/${base}.bin" ] && cp -f "build/tests/${base}.bin" "${STAGING}/tests/${base}.bin"
  [ -f "build/tests/${base}.objdump" ] && cp -f "build/tests/${base}.objdump" "${STAGING}/tests/${base}.objdump"
  count=$((count + 1))
done

GIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
GIT_DESC="$(git describe --always --dirty 2>/dev/null || echo unknown)"
DATE_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GCC_VER="$("${RV_PREFIX}gcc" --version | head -1)"

export STAGING GIT_SHA GIT_DESC DATE_UTC GCC_VER RV_PREFIX
python3 <<'PY'
import json, os
from pathlib import Path

staging = Path(os.environ["STAGING"])
tests = sorted(p.stem for p in (staging / "tests").glob("*.hex"))
manifest = {
    "schema": 1,
    "project": "sisrv-platform",
    "purpose": "Prebuilt RISC-V ROM images for UVM / cocotb / commercial sim without a local toolchain",
    "git_sha": os.environ["GIT_SHA"],
    "git_describe": os.environ["GIT_DESC"],
    "built_at_utc": os.environ["DATE_UTC"],
    "toolchain": os.environ["GCC_VER"],
    "rv_prefix": os.environ["RV_PREFIX"],
    "isa_notes": {
        "default_march": "rv32im_zicsr (see Makefile for per-test overrides)",
        "compressed_tests": "rv32imc_zicsr",
        "atomic_umode_pmp_tests": "rv32imac_zicsr",
    },
    "layout": {
        "tests/<name>.hex": "little-endian word hex for $readmemh / ROM_INIT_FILE",
        "tests/<name>.elf": "ELF for Spike / debug",
        "tests/<name>.bin": "flat binary",
        "tests/<name>.objdump": "optional disassembly",
        "ram.hex": "empty RAM init file",
        "manifest.json": "this index",
    },
    "usage": {
        "install": "make sw-from-artifacts SW_ARTIFACTS_TGZ=sisrv-sw-artifacts.tar.gz",
        "uvm_commercial": "cp build/tests/<name>.hex rom.hex && : > ram.hex && run simv/vsim (+ROM_HEX=rom.hex)",
        "verilator_directed": "make run-<name> after install (or cp hex to rom.hex and run sim)",
        "cocotb_platform": "point platform cocotb ROM preload at build/tests/<name>.hex",
    },
    "test_count": len(tests),
    "tests": tests,
}
(staging / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
(staging / "meta" / "README.txt").write_text(
    "sisrv-platform software artifacts\n"
    f"Built: {manifest['built_at_utc']}\n"
    f"Git: {manifest['git_sha']}\n"
    f"Tests: {len(tests)}\n\n"
    "Install on a machine without a RISC-V toolchain:\n"
    "  make sw-from-artifacts SW_ARTIFACTS_TGZ=path/to/sisrv-sw-artifacts.tar.gz\n\n"
    "UVM / commercial simulator:\n"
    "  cp build/tests/test_pass.hex rom.hex && : > ram.hex\n"
    "  # then run your UVM/questa/vcs/xcelium sim with +ROM_HEX=rom.hex\n"
)
print(f"Manifest: {len(tests)} tests")
PY

mkdir -p "$(dirname "$TGZ")"
tar -C "${STAGING}" -czf "${TGZ}" .
# Browseable copy for CI artifact upload (same layout as the tarball root).
rm -rf "${OUT_DIR}/tree"
cp -a "${STAGING}" "${OUT_DIR}/tree"
echo "Packaged ${count} images -> ${TGZ}"
ls -lh "${TGZ}"
echo "Browseable tree: ${OUT_DIR}/tree"
