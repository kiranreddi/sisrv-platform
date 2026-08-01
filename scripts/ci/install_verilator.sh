#!/usr/bin/env bash
# Build and install Verilator for CI (or local use).
# Usage:
#   VERILATOR_REF=v5.050 PREFIX=$HOME/.local/verilator ./scripts/ci/install_verilator.sh
set -euo pipefail

VERILATOR_REF="${VERILATOR_REF:-v5.050}"
PREFIX="${PREFIX:-${HOME}/.local/verilator}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

if [[ -x "${PREFIX}/bin/verilator" ]]; then
  echo "Verilator already present at ${PREFIX}/bin/verilator"
  "${PREFIX}/bin/verilator" --version
  exit 0
fi

echo "Installing Verilator ${VERILATOR_REF} -> ${PREFIX}"
sudo apt-get update
sudo apt-get install -y \
  git autoconf g++ flex bison ccache help2man make \
  libfl2 libfl-dev zlib1g zlib1g-dev liblz4-dev \
  python3 perl

rm -rf /tmp/verilator-src
git clone --depth 1 --branch "${VERILATOR_REF}" \
  https://github.com/verilator/verilator.git /tmp/verilator-src
cd /tmp/verilator-src
autoconf
./configure --prefix="${PREFIX}"
make -j"${JOBS}"
make install
"${PREFIX}/bin/verilator" --version
