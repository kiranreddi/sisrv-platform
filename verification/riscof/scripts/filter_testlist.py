#!/usr/bin/env python3
"""Filter a RISCOF test_list.yaml down to a single named test."""

from __future__ import annotations

import argparse
import sys

import yaml


def pick_match(keys: list[str], test_name: str, prefer: str) -> str | None:
    if not keys:
        return None

    if len(keys) == 1:
        return keys[0]

    preferred = [key for key in keys if prefer in key]
    if len(preferred) == 1:
        return preferred[0]
    if preferred:
        return sorted(preferred)[0]

    non_hints = [key for key in keys if "/hints/" not in key]
    if len(non_hints) == 1:
        return non_hints[0]
    if non_hints:
        return sorted(non_hints)[0]

    return sorted(keys)[0]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("test_list", help="Path to RISCOF test_list.yaml")
    parser.add_argument(
        "test_name",
        help="Test stem (add-01) or suite-relative path (rv32i_m/I/src/add-01.S)",
    )
    parser.add_argument(
        "--prefer",
        default="rv32i_m/I/src",
        help="When multiple tests share a stem, prefer this path substring",
    )
    args = parser.parse_args()

    with open(args.test_list, "r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)

    matches: list[str] = []
    for key in data:
        basename = key.rsplit("/", 1)[-1]
        stem = basename.rsplit(".", 1)[0]
        if (
            key.endswith("/" + args.test_name)
            or args.test_name in key
            or stem == args.test_name
            or basename == args.test_name
        ):
            matches.append(key)

    match_key = pick_match(matches, args.test_name, args.prefer)

    if match_key is None:
        available = ", ".join(
            sorted({k.rsplit("/", 1)[-1].rsplit(".", 1)[0] for k in data})[:20]
        )
        print(f"Test {args.test_name} not found. First tests: {available}", file=sys.stderr)
        return 1

    filtered = {match_key: data[match_key]}
    yaml.safe_dump(filtered, sys.stdout, sort_keys=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
