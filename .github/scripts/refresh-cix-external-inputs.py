#!/usr/bin/env python3
"""Refresh retained CIX workflow inputs without discarding known-good data."""

from __future__ import annotations

import argparse
import datetime
import json
import os
import shutil
import subprocess
import urllib.request
from pathlib import Path

from cix_external_inputs import (
    UBUNTU_SEEDS,
    load_json,
    validate_acpica_metadata,
    validate_directory,
    validate_gentoo_metadata,
    validate_ubuntu_seed,
    write_checksums,
)


GENTOO_URL = (
    "https://api.github.com/repos/gentoo/gentoo/contents/"
    "sys-kernel/gentoo-sources?ref=master"
)
ACPICA_URL = "https://api.github.com/repos/acpica/acpica/releases/latest"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fallback-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--offline", action="store_true")
    return parser.parse_args()


def fetch_json(url: str, destination: Path) -> None:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "cix-external-input-refresh",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token := os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        data = response.read()
    json.loads(data)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data + (b"" if data.endswith(b"\n") else b"\n"))


def replace_directory(source: Path, destination: Path) -> None:
    shutil.rmtree(destination, ignore_errors=True)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(source, destination)


def refresh_json(
    root: Path,
    relative_path: Path,
    url: str,
    validator,
    work_dir: Path,
) -> bool:
    candidate_root = work_dir / relative_path.parts[0]
    candidate = candidate_root.joinpath(*relative_path.parts[1:])
    shutil.rmtree(candidate_root, ignore_errors=True)
    try:
        fetch_json(url, candidate)
        validator(work_dir)
    except (OSError, ValueError) as error:
        print(f"warning: retaining {relative_path}: {error}")
        return False
    destination = root / relative_path
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(candidate, destination)
    return True


def main() -> None:
    args = parse_args()
    if args.output_dir == Path("/") or args.work_dir == Path("/"):
        raise SystemExit("refusing to use the filesystem root")
    if args.output_dir.exists():
        raise SystemExit(f"output directory already exists: {args.output_dir}")

    validate_directory(args.fallback_dir)
    shutil.copytree(args.fallback_dir, args.output_dir)
    args.work_dir.mkdir(parents=True, exist_ok=True)
    retention = load_json(args.output_dir / "retention.json")
    if not isinstance(retention, dict):
        raise SystemExit("fallback retention metadata is invalid")
    components = retention["components"]
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    refreshed = {name: False for name in components}

    if not args.offline:
        refreshed["gentoo-sources"] = refresh_json(
            args.output_dir,
            Path("gentoo-sources/contents.json"),
            GENTOO_URL,
            validate_gentoo_metadata,
            args.work_dir,
        )
        refreshed["acpica"] = refresh_json(
            args.output_dir,
            Path("acpica/latest-release.json"),
            ACPICA_URL,
            validate_acpica_metadata,
            args.work_dir,
        )

        fetch_script = Path(__file__).with_name("fetch-ubuntu-configs.sh")
        for seed in UBUNTU_SEEDS:
            candidate = args.work_dir / "ubuntu-configs" / seed
            shutil.rmtree(candidate, ignore_errors=True)
            result = subprocess.run(
                [
                    fetch_script,
                    "--seed",
                    seed,
                    "--output-dir",
                    candidate,
                    "--work-dir",
                    args.work_dir / f"ubuntu-{seed}",
                ],
                check=False,
            )
            if result.returncode:
                print(f"warning: retaining Ubuntu {seed} configuration seed")
                continue
            try:
                validate_ubuntu_seed(args.work_dir, seed)
            except (OSError, ValueError) as error:
                print(f"warning: retaining Ubuntu {seed} configuration seed: {error}")
                continue
            replace_directory(
                candidate,
                args.output_dir / "ubuntu-configs" / seed,
            )
            refreshed[f"ubuntu-config-{seed}"] = True

    for name, record in components.items():
        record["last_checked_at"] = now
        record["state"] = "refreshed" if refreshed[name] else "retained"
        if refreshed[name]:
            record["last_refreshed_at"] = now
    retention["generated_at"] = now
    (args.output_dir / "retention.json").write_text(
        json.dumps(retention, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    write_checksums(args.output_dir)
    validate_directory(args.output_dir)

    for name in sorted(components):
        print(f"{name}: {components[name]['state']}")


if __name__ == "__main__":
    main()
