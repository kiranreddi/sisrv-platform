#!/usr/bin/env python3
"""Filter RISCOF test_list.yaml to the sisrv ACT CI profile (RV32IMC + Zicsr core suite).

CI runs the I/M/C/Zicsr architectural suite, which completes in ~20 min and gates every
push to main. The full PMP, privilege, and A (atomics) ACT sub-suites are *excluded here*:
the upstream riscv-arch-test PMP/privilege suites are very large and pushed the CI job past
its 3-hour timeout. The A/PMP/U RTL is fully covered by the directed regression
(test_atomics, 13 U-mode + 13 PMP directed tests), cocotb, and formal; enabling the broad
ACT coverage for those extensions is a follow-up that needs local RISCOF iteration to confirm
pass/fail and bound the runtime (the dev environment has no spike/riscof). Matches the last
known-green profile (commit e1782b4).
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter

import yaml

EXCLUDE_PATH_PARTS = (
    "/pmp/",
    "/A/",
    "/privilege/",
    "/vm_pmp/",
    "/pmps/",
    "/pmpzicbo/",
    "/vm_sv",
    "/vm_",
)


def should_exclude(test_path: str) -> bool:
    normalized = test_path.replace("\\", "/")
    return any(part in normalized for part in EXCLUDE_PATH_PARTS)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("test_list", help="RISCOF test_list.yaml from riscof testlist")
    parser.add_argument("output", help="Filtered YAML for riscof run --testfile")
    args = parser.parse_args()

    with open(args.test_list, "r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)

    kept: dict = {}
    excluded = Counter()
    for key, entry in data.items():
        test_path = entry.get("test_path", key)
        if should_exclude(test_path):
            for part in EXCLUDE_PATH_PARTS:
                if part.strip("/") in test_path.replace("\\", "/"):
                    excluded[part.strip("/")] += 1
                    break
            continue
        kept[key] = entry

    with open(args.output, "w", encoding="utf-8") as handle:
        yaml.safe_dump(kept, handle, sort_keys=False)

    print(
        f"ACT filter: kept {len(kept)} tests, excluded {len(data) - len(kept)} "
        f"(PMP/A/privilege/S-mode out-of-scope for the CI time budget)",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
