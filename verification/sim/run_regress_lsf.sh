#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TOOL=${1:-questa}
RESULTS=${2:-${SIM_RESULTS_DIR:-$ROOT/build/multisim}/$TOOL}
QUEUE=${LSF_QUEUE:-regress}
mkdir -p "$RESULTS"
make -C "$ROOT" sw

mapfile -t TESTS < <(find "$ROOT/build/tests" -maxdepth 1 -name '*.hex' -printf '%f\n' | sort)
(( ${#TESTS[@]} > 0 )) || { echo "No test images found" >&2; exit 2; }
printf '%s\n' "${TESTS[@]}" > "$RESULTS/tests.list"
ARRAY="sisrv_regress[1-${#TESTS[@]}]%5"
case "$TOOL" in
  questa) RUNNER="$ROOT/verification/sim/run_questa.sh" ;;
  vcs) RUNNER="$ROOT/verification/sim/run_vcs.sh" ;;
  xcelium) RUNNER="$ROOT/verification/sim/run_xcelium.sh" ;;
  *) echo "Unsupported simulator: $TOOL" >&2; exit 2 ;;
esac
JOB=$(bsub -q "$QUEUE" -J "$ARRAY" -o "$RESULTS/lsf_%I.out" -e "$RESULTS/lsf_%I.err" \
  "test=\$(sed -n \"\$LSB_JOBINDEX p\" '$RESULTS/tests.list'); \
   mkdir -p '$RESULTS/logs/'; \
   '$RUNNER' \"\$test\" '$RESULTS/logs/\$(basename \"\$test\" .hex)'") \
  | awk '{print $2}' | tr -d '<>'
if command -v bwait >/dev/null 2>&1; then
  bwait -w "ended($JOB)"
else
  echo "bwait is required to collect LSF array completion" >&2
  exit 2
fi
status=0
printf '%-32s | %s\n' TEST "$TOOL"
printf '%-32s-+-%s\n' '--------------------------------' '--------'
for test in "${TESTS[@]}"; do
  log="$RESULTS/logs/${test%.hex}/sim.log"
  if grep -q '\*\*\* PASS \*\*\*' "$log" 2>/dev/null; then
    result=PASS
  elif grep -q '\*\*\* TIMEOUT \*\*\*' "$log" 2>/dev/null; then
    result=TIMEOUT; status=1
  else
    result=FAIL; status=1
  fi
  printf '%-32s | %s\n' "${test%.hex}" "$result"
done
exit "$status"
