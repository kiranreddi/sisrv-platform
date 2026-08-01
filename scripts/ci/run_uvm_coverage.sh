#!/usr/bin/env bash
# Run UVM decompress + full platform asm regress with Verilator --coverage.
# Merge coverage.dat files, annotate, and summarize DUT (sis*.sv) points.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

export PATH="${HOME}/.local/verilator/bin:${PATH:-}"
OUT="${UVM_COVERAGE_OUT:-${ROOT}/build/coverage/uvm}"
JOBS="${UVM_JOBS:-$(nproc 2>/dev/null || echo 4)}"
PLATFORM_TIMEOUT="${UVM_PLATFORM_TIMEOUT:-200000}"

rm -rf "${OUT}"
mkdir -p "${OUT}/raw" "${OUT}/annotate"

REPORT="${OUT}/coverage_uvm.txt"
{
  echo "sisrv-platform UVM Verilator coverage"
  echo "generated_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "tool=verilator --coverage + uvm-verilator"
} | tee "${REPORT}"

echo "=== UVM coverage: decompress (L0) ==="
rm -rf build/uvm/decompress
make uvm-decompress UVM_COVERAGE=1 UVM_JOBS="${JOBS}" \
  UVM_TEST=sis_decompress_smoke_test \
  UVM_COV_FILE="${OUT}/raw/decompress.dat"
test -s "${OUT}/raw/decompress.dat"

echo "=== Ensure asm hex images ==="
make sw

echo "=== UVM coverage: build platform binary ==="
rm -rf build/uvm/platform
make uvm-platform UVM_COVERAGE=1 UVM_JOBS="${JOBS}" \
  UVM_ROM_HEX=build/tests/test_pass.hex \
  UVM_PLATFORM_TEST=sis_platform_tohost_test \
  UVM_COV_FILE="${OUT}/raw/platform_test_pass.dat"
test -s "${OUT}/raw/platform_test_pass.dat"

SIM="${ROOT}/build/uvm/platform/sim_uvm_platform"
test -x "${SIM}"

mapfile -t HEXES < <(ls -1 build/tests/*.hex | grep -v -E 'pipeline_throughput|fetch_buffer_throughput' || true)

echo "=== UVM coverage: platform regress (${#HEXES[@]} images) ==="
plat_pass=0
plat_fail=0
plat_total=0
for hex in "${HEXES[@]}"; do
  name="$(basename "${hex}" .hex)"
  plat_total=$((plat_total + 1))
  if [[ "${name}" == "test_pass" ]]; then
    echo "  PASS: ${name} (from build step)"
    plat_pass=$((plat_pass + 1))
    continue
  fi
  cp -f "${hex}" rom.hex
  touch ram.hex
  covfile="${OUT}/raw/platform_${name}.dat"
  set +e
  "${SIM}" \
    +UVM_TESTNAME=sis_platform_tohost_test \
    +UVM_NO_RELNOTES \
    +TIMEOUT_CYCLES="${PLATFORM_TIMEOUT}" \
    +verilator+coverage+file+"${covfile}" \
    > "${OUT}/raw/${name}.log" 2>&1
  rc=$?
  set -e
  rm -f rom.hex ram.hex
  if [[ ${rc} -eq 0 ]] && grep -qE 'status=TOHOST_PASS|TOHOST_PASS' "${OUT}/raw/${name}.log"; then
    echo "  PASS: ${name}"
    plat_pass=$((plat_pass + 1))
  else
    echo "  FAIL: ${name} (rc=${rc})"
    tail -25 "${OUT}/raw/${name}.log" || true
    plat_fail=$((plat_fail + 1))
  fi
done

echo "platform_images=${plat_total} pass=${plat_pass} fail=${plat_fail}" | tee -a "${REPORT}"

echo "=== Merge + annotate ==="
mapfile -t DATS < <(ls -1 "${OUT}"/raw/*.dat)
verilator_coverage --write "${OUT}/merged.dat" "${DATS[@]}"
verilator_coverage --write-info "${OUT}/merged.info" "${OUT}/merged.dat" || true
# Annotate with summary on stdout captured
verilator_coverage --annotate "${OUT}/annotate" --annotate-min 1 "${OUT}/merged.dat" \
  | tee -a "${REPORT}" || true

chmod +x scripts/ci/summarize_verilator_cov.py
python3 scripts/ci/summarize_verilator_cov.py "${OUT}/annotate" --report "${REPORT}"

# Also print decompress-only DUT number for the L0 focus
if [[ -f "${OUT}/raw/decompress.dat" ]]; then
  mkdir -p "${OUT}/annotate_decompress"
  verilator_coverage --annotate "${OUT}/annotate_decompress" --annotate-min 1 \
    "${OUT}/raw/decompress.dat" > "${OUT}/decompress_summary.txt" || true
  {
    echo ""
    echo "=== Decompress-only coverage (L0 UVM) ==="
    cat "${OUT}/decompress_summary.txt"
  } | tee -a "${REPORT}"
  python3 scripts/ci/summarize_verilator_cov.py "${OUT}/annotate_decompress" --report "${REPORT}"
fi

echo "Wrote ${REPORT}"
if [[ ${plat_fail} -gt 0 ]]; then
  echo "WARNING: ${plat_fail} platform UVM image(s) failed; see ${OUT}/raw/*.log" | tee -a "${REPORT}"
  exit 1
fi
echo "=== UVM coverage DONE ==="
