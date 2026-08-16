#!/usr/bin/env python3
"""Validate a retained CIX external-input bundle."""

from __future__ import annotations

import argparse
from pathlib import Path

from cix_external_inputs import validate_directory


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--max-age-days", type=int)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    try:
        validate_directory(args.directory, args.max_age_days)
    except (OSError, ValueError) as error:
        raise SystemExit(error) from error
    print(f"Validated retained external inputs in {args.directory}")


if __name__ == "__main__":
    main()
