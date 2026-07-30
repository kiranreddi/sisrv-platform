#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TEST=${1:?test name or hex path required}
RESULTS=${2:?results directory required}
TIMEOUT=${TIMEOUT_CYCLES:-1000000}
SCRATCH=${SIM_SCRATCH_DIR:-${TMPDIR:-/tmp}/sisrv_sim}
mkdir -p "$RESULTS" "$SCRATCH"
module load boxsteru4

HEX=$TEST
[[ "$HEX" == *.hex ]] || HEX="$ROOT/build/tests/$TEST.hex"
[[ -f "$HEX" ]] || { echo "Missing test image: $HEX" >&2; exit 2; }
RUN="$SCRATCH/vcs_$(basename "$HEX" .hex)_$$"
mkdir -p "$RUN"
cp "$HEX" "$RUN/rom.hex"
: > "$RUN/ram.hex"
cd "$RUN"
sed "s|^+incdir+|+incdir+$ROOT/|; /^[^+]/s|^|$ROOT/|" \
  "$ROOT/verification/sim/filelist.f" > "$RUN/filelist.f"
vcs -sverilog -full64 -ntb_opts uvm -f "$RUN/filelist.f" \
  +define+VCS +define+COMMERCIAL_SIM -top sisTbTop -o simv >"$RESULTS/compile.log" 2>&1
./simv +ROM_HEX="$RUN/rom.hex" +RAM_HEX="$RUN/ram.hex" \
  +TIMEOUT_CYCLES="$TIMEOUT" >"$RESULTS/sim.log" 2>&1
grep -q '\*\*\* PASS \*\*\*' "$RESULTS/sim.log"
