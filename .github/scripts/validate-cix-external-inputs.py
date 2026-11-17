#!/usr/bin/env python3
"""Validate a retained CIX external-input bundle."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from cix_external_inputs import (
    acpica_source,
    load_json,
    validate_directory,
    write_checksums,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--max-age-days", type=int)
    parser.add_argument(
        "--acpica-floor", type=Path,
        help="prefer ACPICA metadata from this fallback bundle if it is newer",
    )
    return parser.parse_args()


def apply_acpica_floor(root: Path, fallback: Path) -> None:
    retained_version, _, _ = acpica_source(root)
    try:
        fallback_version, _, _ = acpica_source(fallback)
        if fallback_version <= retained_version:
            return
        validate_directory(fallback)
    except (OSError, ValueError) as error:
        print(f"::warning::Invalid repository fallback; retaining ACPICA {retained_version}: {error}")
        return
    relative = Path("acpica/latest-release.json")
    shutil.copyfile(fallback / relative, root / relative)
    retention_path = root / "retention.json"
    retention = load_json(retention_path)
    fallback_retention = load_json(fallback / "retention.json")
    retention["components"]["acpica"] = fallback_retention["components"]["acpica"]
    retention_path.write_text(
        json.dumps(retention, indent=2, sort_keys=True) + "\n", encoding="utf-8",
    )
    write_checksums(root)
    validate_directory(root)
    print(f"Selected repository ACPICA {fallback_version} over retained {retained_version}")


def main() -> None:
    args = parse_args()
    try:
        validate_directory(args.directory, args.max_age_days)
        if args.acpica_floor:
            apply_acpica_floor(args.directory, args.acpica_floor)
    except (OSError, ValueError) as error:
        raise SystemExit(error) from error
    print(f"Validated retained external inputs in {args.directory}")


if __name__ == "__main__":
    main()
