#!/usr/bin/env python3
"""Filter RISCOF test_list.yaml to the sisrv Phase-A ACT profile.

Excludes architectural tests outside the advertised RV32IMCZicsr M-mode scope:
  - PMP (not implemented; documented P1)
  - A extension / atomics (not implemented; documented P1)
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter

import yaml

EXCLUDE_PATH_PARTS = (
    "/pmp/",
    "/A/",
    "/vm_pmp/",
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
        f"(PMP/A outside RV32IMCZicsr profile)",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
