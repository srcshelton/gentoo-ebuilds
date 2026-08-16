#!/usr/bin/env python3
"""Compare maintained cix-sources versions with Gentoo gentoo-sources."""

from __future__ import annotations

import argparse
import json
import os
import re
import urllib.request
from pathlib import Path


EBUILD_PATTERN = re.compile(
    r"^(?:cix|gentoo)-sources-(\d+)\.(\d+)\.(\d+)(?:-r(\d+))?\.ebuild$"
)
REQUIRED_LINES = ("6.18", "7.1", "7.2")
UPSTREAM_API = (
    "https://api.github.com/repos/gentoo/gentoo/contents/"
    "sys-kernel/gentoo-sources?ref=master"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--package-dir",
        type=Path,
        default=Path("sys-kernel/cix-sources"),
        help="directory containing cix-sources ebuilds",
    )
    parser.add_argument(
        "--upstream-json",
        type=Path,
        help="read a GitHub Contents API response from this file",
    )
    return parser.parse_args()


def select_versions(names: list[str], prefix: str) -> dict[str, str]:
    selected: dict[str, tuple[tuple[int, int, int, int], str]] = {}
    for name in names:
        if not name.startswith(prefix):
            continue
        match = EBUILD_PATTERN.fullmatch(name)
        if not match:
            continue
        major, minor, patch, revision = match.groups()
        line = f"{major}.{minor}"
        if line not in REQUIRED_LINES:
            continue
        key = (int(major), int(minor), int(patch), int(revision or 0))
        version = f"{major}.{minor}.{patch}"
        if revision:
            version += f"-r{revision}"
        current = selected.get(line)
        if current is None or key > current[0]:
            selected[line] = (key, version)
    return {line: selected[line][1] for line in selected}


def fetch_upstream() -> list[dict[str, object]]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "cix-sources-version-check",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if token := os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(UPSTREAM_API, headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def main() -> None:
    args = parse_args()
    local = select_versions(
        [path.name for path in args.package_dir.glob("cix-sources-*.ebuild")],
        "cix-sources-",
    )
    if args.upstream_json:
        upstream_data = json.loads(args.upstream_json.read_text(encoding="utf-8"))
    else:
        upstream_data = fetch_upstream()
    upstream = select_versions(
        [str(entry.get("name", "")) for entry in upstream_data],
        "gentoo-sources-",
    )

    missing_local = set(REQUIRED_LINES) - local.keys()
    missing_upstream = set(REQUIRED_LINES) - upstream.keys()
    if missing_local or missing_upstream:
        raise SystemExit(
            "missing maintained lines: "
            f"local={sorted(missing_local)}, upstream={sorted(missing_upstream)}"
        )

    mismatches = [
        (line, local[line], upstream[line])
        for line in REQUIRED_LINES
        if local[line] != upstream[line]
    ]
    for line in REQUIRED_LINES:
        print(f"Linux {line}: cix-sources {local[line]}, Gentoo {upstream[line]}")
    if mismatches:
        for line, local_version, upstream_version in mismatches:
            print(
                f"out of date: Linux {line}: cix-sources {local_version}, "
                f"Gentoo {upstream_version}"
            )
        raise SystemExit(1)


if __name__ == "__main__":
    main()
