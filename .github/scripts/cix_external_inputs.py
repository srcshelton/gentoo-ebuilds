#!/usr/bin/env python3
"""Validation helpers for retained external CIX workflow inputs."""

from __future__ import annotations

import datetime
import hashlib
import json
import re
from pathlib import Path


ACPICA_ASSET = re.compile(r"acpica-unix-\d{8}\.tar\.gz")
ACPICA_DOWNLOAD = re.compile(
    r"https://github\.com/(?:acpica|open-acpica)/acpica/releases/download/"
    r"\d{8}/acpica-unix-\d{8}\.tar\.gz"
)
GENTOO_EBUILD = re.compile(
    r"^gentoo-sources-(\d+)\.(\d+)\.(\d+)(?:-r\d+)?\.ebuild$"
)
REQUIRED_GENTOO_LINES = {"6.18", "7.1", "7.2"}
UBUNTU_SEEDS = {
    "6.17": ["6.18"],
    "7.0": ["7.1", "7.2"],
}
UBUNTU_CONFIGS = {
    "arm64-generic.config",
    "arm64-generic-64k.config",
}


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"{path}: invalid JSON: {error}") from error


def validate_ubuntu_seed(root: Path, seed: str) -> None:
    seed_dir = root / "ubuntu-configs" / seed
    metadata = load_json(seed_dir / "metadata.json")
    if not isinstance(metadata, dict):
        raise ValueError(f"{seed_dir}/metadata.json: expected an object")
    if metadata.get("declared_seed") != seed:
        raise ValueError(f"{seed_dir}: declared seed is not {seed}")
    if metadata.get("source_kernel_series") != seed:
        raise ValueError(f"{seed_dir}: source kernel series is not {seed}")
    if metadata.get("consumer_lines") != UBUNTU_SEEDS[seed]:
        raise ValueError(f"{seed_dir}: unexpected consumer kernel lines")

    configs = metadata.get("configs")
    if not isinstance(configs, dict) or set(configs) != UBUNTU_CONFIGS:
        raise ValueError(f"{seed_dir}: unexpected configuration set")
    for name, record in configs.items():
        if not isinstance(record, dict):
            raise ValueError(f"{seed_dir}/{name}: invalid metadata")
        path = seed_dir / name
        data = path.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if digest != record.get("sha256"):
            raise ValueError(f"{path}: SHA-256 does not match metadata")
        if data.count(b"\n") != record.get("lines"):
            raise ValueError(f"{path}: line count does not match metadata")


def validate_gentoo_metadata(root: Path) -> None:
    path = root / "gentoo-sources" / "contents.json"
    entries = load_json(path)
    if not isinstance(entries, list):
        raise ValueError(f"{path}: expected a list")

    lines = set()
    for entry in entries:
        if not isinstance(entry, dict):
            raise ValueError(f"{path}: entry is not an object")
        match = GENTOO_EBUILD.fullmatch(str(entry.get("name", "")))
        if match:
            lines.add(f"{match.group(1)}.{match.group(2)}")
    missing = REQUIRED_GENTOO_LINES - lines
    if missing:
        raise ValueError(f"{path}: missing maintained lines {sorted(missing)}")


def validate_acpica_metadata(root: Path) -> None:
    path = root / "acpica" / "latest-release.json"
    release = load_json(path)
    if not isinstance(release, dict):
        raise ValueError(f"{path}: expected an object")
    for asset in release.get("assets", []):
        if not isinstance(asset, dict):
            continue
        name = str(asset.get("name", ""))
        url = str(asset.get("browser_download_url", ""))
        if ACPICA_ASSET.fullmatch(name) and ACPICA_DOWNLOAD.fullmatch(url):
            return
    raise ValueError(f"{path}: no ACPICA Unix source asset")


def parse_timestamp(value: object, description: str) -> datetime.datetime:
    if not isinstance(value, str):
        raise ValueError(f"{description}: expected an ISO timestamp")
    try:
        timestamp = datetime.datetime.fromisoformat(value)
    except ValueError as error:
        raise ValueError(f"{description}: invalid ISO timestamp") from error
    if timestamp.tzinfo is None:
        raise ValueError(f"{description}: timestamp lacks a timezone")
    return timestamp


def validate_retention(root: Path, max_age_days: int | None = None) -> None:
    path = root / "retention.json"
    retention = load_json(path)
    if not isinstance(retention, dict) or retention.get("schema_version") != 1:
        raise ValueError(f"{path}: unsupported schema")
    parse_timestamp(retention.get("generated_at"), f"{path}: generated_at")

    expected = {"acpica", "gentoo-sources"} | {
        f"ubuntu-config-{seed}" for seed in UBUNTU_SEEDS
    }
    components = retention.get("components")
    if not isinstance(components, dict) or set(components) != expected:
        raise ValueError(f"{path}: unexpected component set")

    now = datetime.datetime.now(datetime.timezone.utc)
    for name, record in components.items():
        if not isinstance(record, dict):
            raise ValueError(f"{path}: invalid {name} record")
        refreshed = parse_timestamp(
            record.get("last_refreshed_at"),
            f"{path}: {name}.last_refreshed_at",
        )
        parse_timestamp(
            record.get("last_checked_at"),
            f"{path}: {name}.last_checked_at",
        )
        if record.get("state") not in {"refreshed", "retained"}:
            raise ValueError(f"{path}: invalid {name} state")
        if max_age_days is not None and now - refreshed > datetime.timedelta(
            days=max_age_days
        ):
            raise ValueError(
                f"{path}: {name} was last refreshed more than "
                f"{max_age_days} days ago"
            )


def data_files(root: Path) -> list[Path]:
    return sorted(
        path
        for path in root.rglob("*")
        if path.is_file() and path.name != "SHA256SUMS"
    )


def write_checksums(root: Path) -> None:
    lines = [
        f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.relative_to(root)}"
        for path in data_files(root)
    ]
    (root / "SHA256SUMS").write_text("\n".join(lines) + "\n", encoding="utf-8")


def validate_checksums(root: Path) -> None:
    path = root / "SHA256SUMS"
    expected = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if not match or match.group(2) in expected:
            raise ValueError(f"{path}: malformed checksum record")
        expected[match.group(2)] = match.group(1)

    files = {item.relative_to(root).as_posix(): item for item in data_files(root)}
    if set(expected) != set(files):
        raise ValueError(f"{path}: checksum inventory does not match files")
    for name, item in files.items():
        if hashlib.sha256(item.read_bytes()).hexdigest() != expected[name]:
            raise ValueError(f"{item}: SHA-256 does not match SHA256SUMS")


def validate_directory(root: Path, max_age_days: int | None = None) -> None:
    if not root.is_dir():
        raise ValueError(f"{root}: retained-input directory is absent")
    for seed in UBUNTU_SEEDS:
        validate_ubuntu_seed(root, seed)
    validate_gentoo_metadata(root)
    validate_acpica_metadata(root)
    validate_retention(root, max_age_days)
    validate_checksums(root)
