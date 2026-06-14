#!/usr/bin/env bash
# Fetch Sky130 HD standard-cell Liberty for STA (named PDK reference flow).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="${ROOT}/third_party/sky130"
LIB_FILE="${LIB_DIR}/sky130_fd_sc_hd__tt_025C_1v80.lib"

mkdir -p "${LIB_DIR}"

if [[ -s "${LIB_FILE}" ]]; then
  echo "Sky130 Liberty present: ${LIB_FILE}"
  exit 0
fi

echo "Downloading Sky130 HD Liberty via OpenROAD-flow-scripts sparse checkout..."
TMP_ORFS="$(mktemp -d)"
trap 'rm -rf "${TMP_ORFS}"' EXIT

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git "${TMP_ORFS}"
cd "${TMP_ORFS}"
git sparse-checkout set flow/platforms/sky130hd/lib
cp flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib "${LIB_FILE}"

echo "Sky130 Liberty ready: ${LIB_FILE}"
