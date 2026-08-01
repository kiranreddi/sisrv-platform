#!/usr/bin/env bash
# Fetch / refresh chipsalliance UVM tree for Verilator.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="${UVM_HOME:-${ROOT}/third_party/uvm}"
BRANCH="${UVM_BRANCH:-uvm-2017-1.0-vlt}"
URL="${UVM_URL:-https://github.com/chipsalliance/uvm-verilator.git}"

if [[ -f "${DEST}/src/uvm.sv" && "${UVM_FORCE:-0}" != "1" ]]; then
  echo "UVM already present at ${DEST} (set UVM_FORCE=1 to refresh)"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
git clone --depth 1 --branch "${BRANCH}" "${URL}" "${tmp}/uvm"
keep=""
[[ -f "${DEST}/SOURCE.md" ]] && keep="$(cat "${DEST}/SOURCE.md")"
rm -rf "${DEST}"
mkdir -p "${DEST}"
# Keep sources + license only (skip HTML docs / GitHub templates).
mkdir -p "${DEST}"
cp -a "${tmp}/uvm/src" "${DEST}/"
for f in LICENSE.txt NOTICE.txt README.md DEVIATIONS.md; do
  [[ -f "${tmp}/uvm/${f}" ]] && cp -a "${tmp}/uvm/${f}" "${DEST}/"
done
rm -rf "${DEST}/.git" "${DEST}/docs" "${DEST}/.github"
if [[ -n "${keep}" ]]; then
  printf '%s\n' "${keep}" > "${DEST}/SOURCE.md"
elif [[ ! -f "${DEST}/SOURCE.md" ]]; then
  cat > "${DEST}/SOURCE.md" <<EOF
# Accellera UVM (Verilator-compatible tree)

- Upstream: ${URL}
- Branch / tag: \`${BRANCH}\`
- Purpose: UVM library for Verilator and commercial simulators
- Refresh: \`bash scripts/ci/fetch_uvm.sh\`
EOF
fi
echo "Installed UVM ${BRANCH} -> ${DEST}"
ls "${DEST}/src/uvm.sv"
