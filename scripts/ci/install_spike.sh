#!/usr/bin/env bash
# Build and install Spike (riscv-isa-sim) with commitlog for lock-step / RISCOF.
# Usage:
#   SPIKE_REF=<sha> PREFIX=$HOME/.local/spike ./scripts/ci/install_spike.sh
set -euo pipefail

SPIKE_REF="${SPIKE_REF:?SPIKE_REF must be set}"
PREFIX="${PREFIX:-${HOME}/.local/spike}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

if [[ -x "${PREFIX}/bin/spike" ]]; then
  echo "Spike already present at ${PREFIX}/bin/spike"
  "${PREFIX}/bin/spike" --version || true
  exit 0
fi

echo "Installing Spike ${SPIKE_REF} -> ${PREFIX}"
sudo apt-get update
sudo apt-get install -y device-tree-compiler git build-essential

rm -rf /tmp/riscv-isa-sim
git init /tmp/riscv-isa-sim
cd /tmp/riscv-isa-sim
git remote add origin https://github.com/riscv-software-src/riscv-isa-sim.git
git fetch --depth 1 origin "${SPIKE_REF}"
git checkout FETCH_HEAD
mkdir build && cd build
../configure --prefix="${PREFIX}" --enable-commitlog
make -j"${JOBS}"
make install
"${PREFIX}/bin/spike" --version || true
