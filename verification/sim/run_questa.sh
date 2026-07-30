#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TEST=${1:?test name or hex path required}
RESULTS=${2:?results directory required}
TIMEOUT=${TIMEOUT_CYCLES:-1000000}
SCRATCH=${SIM_SCRATCH_DIR:-${TMPDIR:-/tmp}/sisrv_sim}
mkdir -p "$RESULTS" "$SCRATCH"
if ! command -v module >/dev/null 2>&1; then
  echo "module command is required" >&2
  exit 2
fi
module load boxsteru4

HEX=$TEST
[[ "$HEX" == *.hex ]] || HEX="$ROOT/build/tests/$TEST.hex"
[[ -f "$HEX" ]] || { echo "Missing test image: $HEX" >&2; exit 2; }
RUN="$SCRATCH/questa_$(basename "$HEX" .hex)_$$"
mkdir -p "$RUN"
cp "$HEX" "$RUN/rom.hex"
: > "$RUN/ram.hex"
cd "$RUN"
sed "s|^+incdir+|+incdir+$ROOT/|; /^[^+]/s|^|$ROOT/|" \
  "$ROOT/verification/sim/filelist.f" > "$RUN/filelist.f"
vlog -sv -work work -f "$RUN/filelist.f" +define+QUESTA +define+COMMERCIAL_SIM \
  >"$RESULTS/compile.log" 2>&1
vopt sisTbTop -o sisTbTop_opt +acc \
  >"$RESULTS/elab.log" 2>&1
vsim -c sisTbTop_opt \
  -do "run -all; quit -code 0" \
  +ROM_HEX="$RUN/rom.hex" +RAM_HEX="$RUN/ram.hex" \
  +TIMEOUT_CYCLES="$TIMEOUT" \
  >"$RESULTS/sim.log" 2>&1
grep -q '\*\*\* PASS \*\*\*' "$RESULTS/sim.log"
