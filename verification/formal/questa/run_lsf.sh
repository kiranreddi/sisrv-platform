#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
RESULTS=${1:-${FORMAL_RESULTS_DIR:-$ROOT/build/formal-questa}}
DECK=${2:-autocheck}
QUEUE=${LSF_QUEUE:-regress}
mkdir -p "$RESULTS"
module load boxsteru4
case "$DECK" in
  autocheck) DOFILE="$ROOT/verification/formal/questa/autocheck.do" ;;
  propcheck) DOFILE="$ROOT/verification/formal/questa/propcheck.do" ;;
  *) echo "Unsupported formal deck: $DECK" >&2; exit 2 ;;
esac
JOB=$(bsub -q "$QUEUE" -J sisrv_formal -o "$RESULTS/lsf.out" -e "$RESULTS/lsf.err" \
  "module load boxsteru4 && cd '$ROOT' && qverify -c -do '$DOFILE' \
   >'$RESULTS/${DECK}.log' 2>&1") | awk '{print $2}' | tr -d '<>'
bwait -w "ended($JOB)"
test -s "$RESULTS/${DECK}.log"
