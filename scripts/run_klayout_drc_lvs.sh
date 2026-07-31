#!/usr/bin/env bash
# Optional KLayout DRC/LVS for M8 artifacts (when klayout is installed).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PDK_DIR="${PDK_DIR:-${ROOT}/third_party/sky130hd}"
OUT_DIR="${OUT_DIR:-${ROOT}/build/openroad}"
DESIGN_NAME="${DESIGN_NAME:-sisHardenTop}"

GDS="${OUT_DIR}/${DESIGN_NAME}.gds"
DEF="${OUT_DIR}/${DESIGN_NAME}.def"
NETLIST="${OUT_DIR}/${DESIGN_NAME}_pnr.v"
DRC_XML="${PDK_DIR}/drc/sky130hd.lydrc"
LVS_XML="${PDK_DIR}/lvs/sky130hd.lylvs"
CDL="${PDK_DIR}/cdl/sky130hd.cdl"

if ! command -v klayout >/dev/null 2>&1; then
  echo "klayout not installed; skipping KLayout DRC/LVS"
  echo "Magic DRC report (if present): ${OUT_DIR}/${DESIGN_NAME}_magic_drc.rpt"
  exit 0
fi

if [[ ! -s "${GDS}" ]]; then
  echo "Missing GDS: ${GDS}" >&2
  exit 1
fi

echo "=== KLayout DRC ==="
klayout -b -r "${DRC_XML}" \
  -rd input="${GDS}" \
  -rd report="${OUT_DIR}/${DESIGN_NAME}_klayout_drc.lyrdb" \
  || true
echo "KLayout DRC database: ${OUT_DIR}/${DESIGN_NAME}_klayout_drc.lyrdb"

if [[ -s "${CDL}" && -s "${NETLIST}" && -f "${LVS_XML}" ]]; then
  echo "=== KLayout LVS ==="
  klayout -b -r "${LVS_XML}" \
    -rd input="${GDS}" \
    -rd schematic="${NETLIST}" \
    -rd report="${OUT_DIR}/${DESIGN_NAME}_klayout_lvs.lvsdb" \
    || true
  echo "KLayout LVS database: ${OUT_DIR}/${DESIGN_NAME}_klayout_lvs.lvsdb"
else
  echo "Skipping KLayout LVS (missing CDL/netlist/rules)"
fi
