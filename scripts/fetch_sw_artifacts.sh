#!/usr/bin/env bash
# Download CI-built RISC-V software artifacts (no local toolchain required).
#
# Prerequisites: GitHub CLI (`gh`) authenticated to the repo.
#
# Examples:
#   ./scripts/fetch_sw_artifacts.sh
#   ./scripts/fetch_sw_artifacts.sh --run-id 30611181758
#   ./scripts/fetch_sw_artifacts.sh --branch cursor/uvm-sim-requirements-578d
#   make sw-from-artifacts SW_ARTIFACTS_TGZ=build/sw-artifacts/sisrv-sw-artifacts.tar.gz
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${SW_ARTIFACTS_OUT:-${ROOT}/build/sw-artifacts}"
BRANCH=""
RUN_ID=""
REPO="${GITHUB_REPOSITORY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh (GitHub CLI) is required to download Actions artifacts" >&2
  exit 2
fi

mkdir -p "${OUT_DIR}"
DL_DIR="${OUT_DIR}/download"
rm -rf "${DL_DIR}"
mkdir -p "${DL_DIR}"

REPO_ARGS=()
if [[ -n "${REPO}" ]]; then
  REPO_ARGS=(-R "${REPO}")
fi

if [[ -z "${RUN_ID}" ]]; then
  if [[ -n "${BRANCH}" ]]; then
    RUN_ID="$(gh run list "${REPO_ARGS[@]}" --branch "${BRANCH}" --workflow CI --limit 20 \
      --json databaseId,conclusion,displayTitle \
      --jq '[.[] | select(.conclusion=="success")][0].databaseId')"
  else
    # Prefer latest successful run on the default branch that produced the artifact.
    RUN_ID="$(gh run list "${REPO_ARGS[@]}" --workflow CI --limit 30 \
      --json databaseId,conclusion,headBranch \
      --jq '[.[] | select(.conclusion=="success")][0].databaseId')"
  fi
fi

if [[ -z "${RUN_ID}" || "${RUN_ID}" == "null" ]]; then
  echo "ERROR: could not find a successful CI run to download from" >&2
  echo "Pass --run-id <id> explicitly (see Actions → CI → run number)." >&2
  exit 2
fi

echo "Downloading sisrv-sw-artifacts from run ${RUN_ID} ..."
gh run download "${RUN_ID}" "${REPO_ARGS[@]}" -n sisrv-sw-artifacts -D "${DL_DIR}"

TGZ="$(find "${DL_DIR}" -name 'sisrv-sw-artifacts.tar.gz' | head -1)"
if [[ -z "${TGZ}" ]]; then
  echo "ERROR: sisrv-sw-artifacts.tar.gz not found in download" >&2
  find "${DL_DIR}" -type f | head -40 >&2 || true
  exit 2
fi

cp -f "${TGZ}" "${OUT_DIR}/sisrv-sw-artifacts.tar.gz"
echo "Saved: ${OUT_DIR}/sisrv-sw-artifacts.tar.gz"
echo "Install with:"
echo "  make sw-from-artifacts SW_ARTIFACTS_TGZ=${OUT_DIR}/sisrv-sw-artifacts.tar.gz"
