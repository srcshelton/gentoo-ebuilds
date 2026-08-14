#!/usr/bin/env python3
"""Select the maintained CIX kernel ebuilds and expand CI matrices."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


EBUILD_PATTERN = re.compile(
    r"^cix-sources-(\d+)\.(\d+)\.(\d+)(?:-r(\d+))?\.ebuild$"
)
REQUIRED_LINES = {"6.18", "7.0", "7.1"}
NPU_ABI_BY_LINE = {
    "6.18": "separate",
    "7.0": "separate",
    "7.1": "separate",
}
UAPI_PREIMAGE_BOUNDARY_BY_LINE = {
    "6.18": "0001-mailbox-cix-add-audited-acpi-support.patch",
    "7.0": "0001-mailbox-cix-add-audited-acpi-support.patch",
    "7.1": "0001-mailbox-cix-add-audited-acpi-support.patch",
}
UBUNTU_CONFIG_SEED_BY_LINE = {
    "6.18": "6.17",
    "7.0": "7.0",
    "7.1": "7.0",
}
UBUNTU_CONFIG_ARTIFACT_BY_SEED = {
    "6.17": "cix-ubuntu-config-6.17",
    "7.0": "cix-ubuntu-config-7.0",
}

BOARD_PROFILES = (
    {
        "board_profile": "o6-acpi",
        "board_package_base": "o6-acpi",
        "board_version_base": "o6.acpi",
    },
    {
        "board_profile": "o6n-acpi",
        "board_package_base": "o6n-acpi",
        "board_version_base": "o6n.acpi",
    },
)
FIRMWARE_PROFILES = (
    {
        "firmware": "1.2",
        "firmware_package": "1.2",
        "firmware_version": "1.2",
        "acpi_table_upgrade": "dsdt",
        "acpi_initramfs_profile": "initramfs-dsdt",
    },
    {
        "firmware": "1.3",
        "firmware_package": "1.3",
        "firmware_version": "1.3",
        "acpi_table_upgrade": "ssdt",
        "acpi_initramfs_profile": "initramfs",
    },
)
CONFIG_FLAVOURS = (
    {
        "config_flavour": "generic",
        "config_package": "generic",
        "config_version": "generic",
    },
    {
        "config_flavour": "generic-64k",
        "config_package": "generic-64k",
        "config_version": "generic64k",
    },
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
        "--github-output",
        type=Path,
        help="also append compact matrix values to this GitHub output file",
    )
    return parser.parse_args()


def select_ebuilds(package_dir: Path) -> list[dict[str, object]]:
    selected: dict[str, dict[str, object]] = {}

    for ebuild in package_dir.glob("cix-sources-*.ebuild"):
        match = EBUILD_PATTERN.fullmatch(ebuild.name)
        if not match:
            if ebuild.name != "cix-sources-9999.ebuild":
                raise SystemExit(f"Unrecognised cix-sources ebuild name: {ebuild}")
            continue

        major, minor, patch, revision = match.groups()
        major_i = int(major)
        minor_i = int(minor)
        patch_i = int(patch)
        revision_i = int(revision or 0)

        if (major_i, minor_i) < (6, 18):
            continue

        line = f"{major_i}.{minor_i}"
        if line not in NPU_ABI_BY_LINE:
            raise SystemExit(
                f"Linux {line} has no declared NPU ABI; add an explicit mapping "
                "when onboarding the new kernel line"
            )
        if line not in UAPI_PREIMAGE_BOUNDARY_BY_LINE:
            raise SystemExit(
                f"Linux {line} has no declared UAPI preimage boundary; add an "
                "explicit boundary when onboarding the new kernel line"
            )
        if line not in UBUNTU_CONFIG_SEED_BY_LINE:
            raise SystemExit(
                f"Linux {line} has no declared Ubuntu configuration seed; add "
                "an explicit adjacent-series mapping when onboarding the new "
                "kernel line"
            )

        ubuntu_config_seed = UBUNTU_CONFIG_SEED_BY_LINE[line]
        try:
            ubuntu_config_artifact = UBUNTU_CONFIG_ARTIFACT_BY_SEED[
                ubuntu_config_seed
            ]
        except KeyError:
            raise SystemExit(
                f"Ubuntu configuration seed {ubuntu_config_seed} for Linux "
                f"{line} has no artifact mapping"
            ) from None

        pv = f"{major_i}.{minor_i}.{patch_i}"
        version = pv if revision_i == 0 else f"{pv}-r{revision_i}"
        key = (major_i, minor_i, patch_i, revision_i)
        candidate: dict[str, object] = {
            "key": key,
            "line": line,
            "pv": pv,
            "version": version,
            "pr": "r0" if revision_i == 0 else f"r{revision_i}",
            "ebuild": ebuild.as_posix(),
            "npu_abi": NPU_ABI_BY_LINE[line],
            "uapi_preimage_boundary": UAPI_PREIMAGE_BOUNDARY_BY_LINE[line],
            "ubuntu_config_seed": ubuntu_config_seed,
            "ubuntu_config_artifact": ubuntu_config_artifact,
        }
        current = selected.get(line)
        if current is None or key > current["key"]:
            selected[line] = candidate

    missing = REQUIRED_LINES - selected.keys()
    if missing:
        raise SystemExit(
            "Missing required maintained cix-sources line(s): "
            + ", ".join(sorted(missing))
        )

    result = []
    for line in sorted(selected, key=lambda value: tuple(map(int, value.split(".")))):
        entry = dict(selected[line])
        del entry["key"]
        result.append(entry)
    return result


def expand_build_matrix(selected: list[dict[str, object]]) -> dict[str, object]:
    include = []
    for kernel in selected:
        for board in BOARD_PROFILES:
            for firmware in FIRMWARE_PROFILES:
                for flavour in CONFIG_FLAVOURS:
                    entry = dict(kernel)
                    entry.update(
                        {
                            "board_profile": board["board_profile"],
                            "board_package": (
                                f"{board['board_package_base']}-"
                                f"{flavour['config_package']}-"
                                f"{firmware['firmware_package']}"
                            ),
                            "board_version": (
                                f"{board['board_version_base']}."
                                f"{flavour['config_version']}."
                                f"{firmware['firmware_version']}"
                            ),
                        }
                    )
                    entry.update(firmware)
                    if (
                        board["board_profile"] == "o6-acpi"
                        and firmware["firmware"] == "1.3"
                    ):
                        entry.update(
                            {
                                "acpi_table_upgrade": "dsdt",
                                "acpi_initramfs_profile": "initramfs-dsdt",
                            }
                        )
                    entry.update(flavour)
                    include.append(entry)
    return {"include": include}


def expand_ubuntu_config_matrix(
    selected: list[dict[str, object]],
) -> dict[str, object]:
    artifacts: dict[str, str] = {}
    for kernel in selected:
        seed = str(kernel["ubuntu_config_seed"])
        artifact = str(kernel["ubuntu_config_artifact"])
        existing = artifacts.setdefault(seed, artifact)
        if existing != artifact:
            raise SystemExit(
                f"Ubuntu configuration seed {seed} maps to conflicting "
                f"artifacts: {existing}, {artifact}"
            )

    include = [
        {"seed": seed, "artifact": artifacts[seed]}
        for seed in sorted(
            artifacts,
            key=lambda value: tuple(map(int, value.split("."))),
        )
    ]
    return {"include": include}


def main() -> None:
    args = parse_args()
    selected = select_ebuilds(args.package_dir)
    matrices = {
        "build": expand_build_matrix(selected),
        "validation": {"include": selected},
        "ubuntu_config": expand_ubuntu_config_matrix(selected),
    }
    print(json.dumps(matrices, indent=2))

    if args.github_output:
        with args.github_output.open("a", encoding="utf-8") as output:
            for name, matrix in matrices.items():
                value = json.dumps(matrix, separators=(",", ":"))
                output.write(f"{name}_matrix={value}\n")


if __name__ == "__main__":
    main()
