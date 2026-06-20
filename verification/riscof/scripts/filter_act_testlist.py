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


def should_exclude(test_path: str, exclude_parts: tuple[str, ...]) -> bool:
    normalized = test_path.replace("\\", "/")
    return any(part in normalized for part in exclude_parts)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("test_list", help="RISCOF test_list.yaml from riscof testlist")
    parser.add_argument("output", help="Filtered YAML for riscof run --testfile")
    parser.add_argument(
        "--full",
        action="store_true",
        help="Keep PMP/privilege/A suites; exclude only S-mode/vm paths (local iteration)",
    )
    args = parser.parse_args()

    exclude_parts = (
        ("/vm_pmp/", "/pmps/", "/pmpzicbo/", "/vm_sv", "/vm_")
        if args.full
        else EXCLUDE_PATH_PARTS
    )

    with open(args.test_list, "r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)

    kept: dict = {}
    excluded = Counter()
    for key, entry in data.items():
        test_path = entry.get("test_path", key)
        if should_exclude(test_path, exclude_parts):
            normalized = test_path.replace("\\", "/")
            for part in exclude_parts:
                if part in normalized:
                    excluded[part.strip("/")] += 1
                    break
            else:
                excluded["other"] += 1
            continue
        kept[key] = entry

    with open(args.output, "w", encoding="utf-8") as handle:
        yaml.safe_dump(kept, handle, sort_keys=False)

    excluded_total = len(data) - len(kept)
    breakdown = ", ".join(f"{k}={v}" for k, v in sorted(excluded.items()))
    print(
        f"ACT filter: kept {len(kept)} tests, excluded {excluded_total} "
        f"({breakdown or 'none'})",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
