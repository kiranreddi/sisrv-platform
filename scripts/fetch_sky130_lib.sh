#!/usr/bin/env bash
# Fetch Sky130 HD standard-cell Liberty for STA (named PDK reference flow).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="${ROOT}/third_party/sky130"
LIB_FILE="${LIB_DIR}/sky130_fd_sc_hd__tt_025C_1v80.lib"
LIB_URL="https://raw.githubusercontent.com/efabless/sky130-libs/refs/heads/master/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__tt_025C_1v80.lib"

mkdir -p "${LIB_DIR}"

if [[ -s "${LIB_FILE}" ]]; then
  echo "Sky130 Liberty present: ${LIB_FILE}"
  exit 0
fi

echo "Downloading Sky130 HD Liberty..."
if ! curl -fsSL "${LIB_URL}" -o "${LIB_FILE}.tmp"; then
  LIB_URL="https://raw.githubusercontent.com/ucb-art/OpenROAD-Platform-Files/master/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib"
  curl -fsSL "${LIB_URL}" -o "${LIB_FILE}.tmp" || \
  curl -fsSL "https://raw.githubusercontent.com/AlignmentResearch/flightmare/master/flightlib/3rd_party/sky130/sky130_fd_sc_hd__tt_025C_1v80.lib" -o "${LIB_FILE}.tmp"
fi

mv "${LIB_FILE}.tmp" "${LIB_FILE}"
echo "Sky130 Liberty ready: ${LIB_FILE}"
