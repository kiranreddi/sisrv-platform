#!/usr/bin/env bash
# Fetch Sky130 HD standard-cell Liberty for STA (named PDK reference flow).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="${ROOT}/third_party/sky130"
LIB_FILE="${LIB_DIR}/sky130_fd_sc_hd__tt_025C_1v80.lib"
LIB_URLS=(
  "https://raw.githubusercontent.com/The-OpenROAD-Project/OpenROAD-flow-scripts/master/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
  "https://raw.githubusercontent.com/efabless/sky130-pdk-libs-sky130_fd_sc_hd/main/timing/sky130_fd_sc_hd__tt_025C_1v80.lib"
)

mkdir -p "${LIB_DIR}"

if [[ -s "${LIB_FILE}" ]]; then
  echo "Sky130 Liberty present: ${LIB_FILE}"
  exit 0
fi

echo "Downloading Sky130 HD Liberty..."
rm -f "${LIB_FILE}.tmp"
for lib_url in "${LIB_URLS[@]}"; do
  if curl -fsSL "${lib_url}" -o "${LIB_FILE}.tmp"; then
    break
  fi
done

if [[ ! -s "${LIB_FILE}.tmp" ]]; then
  echo "Failed to download Sky130 HD Liberty from known sources" >&2
  exit 1
fi

mv "${LIB_FILE}.tmp" "${LIB_FILE}"
echo "Sky130 Liberty ready: ${LIB_FILE}"
