#!/usr/bin/env bash
# Collect Verilator line/toggle coverage for the Decompress unit TB (baseline).
# Informational only — no PR floor until measured baselines exist.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

OUT="${COVERAGE_OUT:-${ROOT}/build/coverage}"
rm -rf "${OUT}"
mkdir -p "${OUT}"

echo "=== Unit coverage: sisDecompress ==="
(
  cd tb/cocotb
  rm -rf sim_build results.xml coverage.dat
  make -f Makefile.decompress SIM=verilator COVERAGE=1
  if compgen -G "sim_build/coverage.dat" > /dev/null; then
    cp -f sim_build/coverage.dat "${OUT}/decompress.dat"
  elif compgen -G "coverage.dat" > /dev/null; then
    cp -f coverage.dat "${OUT}/decompress.dat"
  else
    # Verilator 5.x may write coverage*.dat under sim_build
    found="$(find sim_build -name 'coverage*.dat' 2>/dev/null | head -1 || true)"
    if [[ -n "${found}" ]]; then
      cp -f "${found}" "${OUT}/decompress.dat"
    else
      echo "WARNING: no coverage.dat produced; continuing with empty report" >&2
    fi
  fi
)

REPORT="${OUT}/coverage_unit.txt"
{
  echo "sisrv-platform unit coverage baseline"
  echo "generated_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "dut=sisDecompress"
  echo "tool=verilator --coverage"
  echo "status=informational (no floor)"
  if [[ -f "${OUT}/decompress.dat" ]]; then
    if command -v verilator_coverage >/dev/null 2>&1; then
      verilator_coverage --write-info "${OUT}/decompress.info" "${OUT}/decompress.dat" || true
      verilator_coverage --annotate "${OUT}/annotate" "${OUT}/decompress.dat" || true
      echo "dat=${OUT}/decompress.dat"
      if [[ -d "${OUT}/annotate" ]]; then
        echo "annotate_dir=${OUT}/annotate"
        # Summarize hit lines if annotate produced files
        hits=$(find "${OUT}/annotate" -type f | wc -l | tr -d ' ')
        echo "annotate_files=${hits}"
      fi
    else
      echo "verilator_coverage=missing"
      ls -la "${OUT}/decompress.dat"
    fi
  else
    echo "dat=missing"
  fi
} | tee "${REPORT}"

echo "Wrote ${REPORT}"
