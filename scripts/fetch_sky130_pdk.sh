#!/usr/bin/env bash
# Fetch Sky130 HD platform files needed for OpenROAD hardening (M8).
# Sources LEF/LIB/GDS/tech collateral from OpenROAD-flow-scripts (sparse).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PDK_DIR="${ROOT}/third_party/sky130hd"
MARKER="${PDK_DIR}/.fetched"

need_refresh=0
if [[ ! -f "${MARKER}" ]]; then
  need_refresh=1
fi
for f in \
  lef/sky130_fd_sc_hd.tlef \
  lef/sky130_fd_sc_hd_merged.lef \
  lib/sky130_fd_sc_hd__tt_025C_1v80.lib \
  gds/sky130_fd_sc_hd.gds \
  pdn.tcl \
  make_tracks.tcl \
  setRC.tcl \
  cdl/sky130hd.cdl \
  drc/sky130hd.lydrc \
  lvs/sky130hd.lylvs \
  sky130hd.lyt \
  magic/sky130gds.tech
do
  if [[ ! -s "${PDK_DIR}/${f}" ]]; then
    need_refresh=1
    break
  fi
done

if [[ "${need_refresh}" -eq 0 ]]; then
  echo "Sky130 HD PDK present: ${PDK_DIR}"
  exit 0
fi

echo "Downloading Sky130 HD PDK via OpenROAD-flow-scripts sparse checkout..."
TMP_ORFS="$(mktemp -d)"
TMP_PDKS="$(mktemp -d)"
trap 'rm -rf "${TMP_ORFS}" "${TMP_PDKS}"' EXIT

git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git "${TMP_ORFS}"
(
  cd "${TMP_ORFS}"
  git sparse-checkout set flow/platforms/sky130hd
)

rm -rf "${PDK_DIR}"
mkdir -p "$(dirname "${PDK_DIR}")"
cp -a "${TMP_ORFS}/flow/platforms/sky130hd" "${PDK_DIR}"

# Broken symlink into sky130hs — drop it; RCX rules are optional for M8.
rm -f "${PDK_DIR}/rcx_patterns.rules"

echo "Downloading Magic sky130GDS tech from open_pdks..."
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/RTimothyEdwards/open_pdks.git "${TMP_PDKS}"
(
  cd "${TMP_PDKS}"
  git sparse-checkout set sky130/magic
)
mkdir -p "${PDK_DIR}/magic"
cp -f "${TMP_PDKS}/sky130/magic/sky130gds.tech" "${PDK_DIR}/magic/"
cp -f "${TMP_PDKS}/sky130/magic/sky130.tech" "${PDK_DIR}/magic/" 2>/dev/null || true

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${MARKER}"
echo "Sky130 HD PDK ready: ${PDK_DIR}"
