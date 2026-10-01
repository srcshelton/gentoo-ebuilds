#!/usr/bin/env python3
"""Share identical headers and publish one verified userspace-header package per kernel."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess


def run(*args: str | Path) -> str:
    return subprocess.check_output([str(arg) for arg in args], text=True)


def read_control(text: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    key = ""
    for line in text.splitlines():
        if line.startswith((" ", "\t")):
            if not key:
                raise ValueError("orphan control continuation")
            fields[key] += "\n" + line
        elif line:
            key, value = line.split(":", 1)
            fields[key] = value.strip()
    return fields


def write_control(root: Path, fields: dict[str, str]) -> None:
    (root / "DEBIAN").mkdir(exist_ok=True)
    (root / "DEBIAN/control").write_text(
        "".join(f"{key}: {value}\n" for key, value in fields.items()), encoding="utf-8"
    )


def signature(path: Path) -> tuple:
    info = path.lstat()
    mode = stat.S_IMODE(info.st_mode)
    if path.is_symlink():
        return ("link", mode, os.readlink(path))
    if path.is_file():
        with path.open("rb") as source:
            digest = hashlib.file_digest(source, "sha256").hexdigest()
        return ("file", mode, digest)
    if path.is_dir():
        return ("dir", mode)
    raise ValueError(f"unsupported payload entry: {path}")


def inventory(root: Path, *, active_only: bool = False) -> dict[str, tuple]:
    result = {}
    for parent, dirs, files in os.walk(root, followlinks=False):
        relative = Path(parent).relative_to(root)
        if relative == Path("."):
            dirs[:] = [name for name in dirs if name != "DEBIAN"]
        if active_only and relative == Path("usr/share"):
            dirs[:] = [name for name in dirs if name != "doc"]
        # Documentation can otherwise create a variant-dependent empty parent.
        for name in dirs + files:
            path = Path(parent) / name
            key = path.relative_to(root).as_posix()
            if active_only and key in ("usr/share", "usr/share/doc"):
                continue
            result[key] = signature(path)
    return result


def build_package(root: Path, output: Path) -> Path:
    fields = read_control((root / "DEBIAN/control").read_text(encoding="utf-8"))
    payload = inventory(root)
    fields["Installed-Size"] = str(
        sum(((root / name).lstat().st_size + 1023) // 1024 for name in payload)
    )
    write_control(root, fields)
    sums = []
    for name, entry in sorted(payload.items()):
        if entry[0] == "file":
            with (root / name).open("rb") as source:
                digest = hashlib.file_digest(source, "md5").hexdigest()
            sums.append(f"{digest}  {name}\n")
    (root / "DEBIAN/md5sums").write_text("".join(sums), encoding="utf-8")
    filename = f"{fields['Package']}_{fields['Version']}_{fields['Architecture']}.deb"
    target = output / filename
    if target.exists():
        raise ValueError(f"duplicate output identity: {filename}")
    run("dpkg-deb", "--root-owner-group", "-b", root, target)
    return target


def split_headers(roots: list[Path], pv: str, version: str, output: Path) -> dict:
    """Keep every original path, replacing shared regular files with relative symlinks."""
    common_name = f"linux-headers-{pv}-cix-common"
    common = roots[0].parent / "common"
    common.mkdir()
    common_tree = common / "usr/src" / common_name
    common_tree.mkdir(parents=True)
    trees = []
    originals = []
    snapshots = []
    for root in roots:
        fields = read_control((root / "DEBIAN/control").read_text(encoding="utf-8"))
        release = fields["Package"].removeprefix("linux-headers-")
        tree = root / "usr/src" / fields["Package"]
        if not tree.is_dir():
            raise ValueError(f"missing headers tree: {tree}")
        link = root / "lib/modules" / release / "build"
        if not link.is_symlink() or os.readlink(link) != f"/usr/src/{fields['Package']}":
            raise ValueError(f"unexpected module build link: {link}")
        trees.append(tree)
        originals.append(inventory(root))
        snapshots.append(inventory(tree))

    shared = set(snapshots[0])
    for snapshot in snapshots[1:]:
        shared.intersection_update(snapshot)
    # These are build inputs tied to an individual release, even if some happen
    # to match today. Never replace them with shared writable configuration.
    shared = {
        name for name in shared
        if snapshots[0][name][0] == "file"
        and name != "Module.symvers"
        and not name.startswith(("include/config/", "include/generated/"))
        and "/include/generated/" not in name
        and all(snapshot[name] == snapshots[0][name] for snapshot in snapshots[1:])
    }
    if not shared:
        raise ValueError(f"no identical headers to share for {pv}")

    shared_bytes = 0
    for name in sorted(shared):
        target = common_tree / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(trees[0] / name, target)
        shared_bytes += target.stat().st_size
        for tree in trees:
            source = tree / name
            source.unlink()
            # Both trees will be siblings under /usr/src after installation.
            installed_target = Path("/usr/src") / common_name / name
            installed_parent = Path("/usr/src") / tree.name / Path(name).parent
            source.symlink_to(os.path.relpath(installed_target, installed_parent))

    common_fields = {
        "Package": common_name,
        "Source": "linux-cix",
        "Version": version,
        # The shared intersection can contain arm64 build tools, not just text.
        "Architecture": "arm64",
        "Section": "kernel",
        "Priority": "optional",
        "Maintainer": read_control(
            (roots[0] / "DEBIAN/control").read_text(encoding="utf-8")
        )["Maintainer"],
        "Description": f"Common kernel headers and build tools for CIX Linux {pv}\n"
        " Shared by the matching ACPI board, firmware and page-size flavours.",
    }
    copyright_file = roots[0] / "usr/share/doc" / trees[0].name / "copyright"
    if copyright_file.is_file():
        destination = common / "usr/share/doc" / common_name / "copyright"
        destination.parent.mkdir(parents=True)
        shutil.copy2(copyright_file, destination)
    write_control(common, common_fields)
    build_package(common, output)

    for root, tree, original in zip(roots, trees, originals):
        reconstructed = inventory(root)
        for name in shared:
            path = tree / name
            link = os.readlink(path)
            # Package scratch roots differ; check links in the namespace they
            # will share after installation, then compare the target bytes.
            installed = os.path.normpath(str(
                Path("/usr/src") / tree.name / Path(name).parent / link
            ))
            if installed != str(Path("/usr/src") / common_name / name):
                raise ValueError(f"incorrect shared header link: {name}")
            reconstructed[path.relative_to(root).as_posix()] = signature(common_tree / name)
        if reconstructed != original:
            raise ValueError(f"headers split changed effective payload: {tree.name}")
        fields = read_control((root / "DEBIAN/control").read_text(encoding="utf-8"))
        dependency = f"{common_name} (= {version})"
        existing = fields.get("Depends", "").replace("\n", " ").strip()
        fields["Depends"] = f"{existing}, {dependency}" if existing else dependency
        write_control(root, fields)
        build_package(root, output)
    return {"common_package": common_name, "shared_files": len(shared),
            "shared_bytes": shared_bytes, "flavour_packages": len(roots)}


def assemble(inputs: Path, output: Path, work: Path, matrix: dict) -> dict:
    if output.exists() or work.exists():
        raise ValueError("output and work directories must not already exist")
    if not matrix.get("include"):
        raise ValueError("empty build matrix")
    expected = {}
    for row in matrix["include"]:
        release = f"{row['pv']}-cix-{row['board_package']}"
        for kind in ("image", "headers"):
            name = f"linux-{kind}-{release}"
            if name in expected:
                raise ValueError(f"duplicate matrix package: {name}")
            expected[name] = row
    packages = {}
    libc = {}
    for deb in sorted(inputs.rglob("*.deb")):
        fields = read_control(run("dpkg-deb", "-f", deb))
        name = fields["Package"]
        if fields["Architecture"] != "arm64":
            raise ValueError(f"unexpected architecture: {deb}")
        if name == "linux-libc-dev":
            libc.setdefault(fields["Version"], []).append(deb)
        elif name in expected and name not in packages:
            if fields["Version"] != expected[name]["deb_version"]:
                raise ValueError(f"unexpected package version: {deb}")
            packages[name] = deb
        else:
            raise ValueError(f"unexpected or duplicate package: {deb}")
    if packages.keys() != expected.keys():
        raise ValueError(f"missing packages: {sorted(expected.keys() - packages.keys())}")
    kernels = {}
    for row in matrix["include"]:
        kernels.setdefault((row["pv"], row["deb_version"]), []).append(row)
    if set(libc) != {version for _, version in kernels}:
        raise ValueError("userspace-header versions do not match the matrix")
    # Require one libc input from each original variant artifact. Their names
    # collide deliberately, so download-artifact must keep artifact directories.
    for pv, version in kernels:
        rows = kernels[(pv, version)]
        expected_parents = {packages[f"linux-headers-{pv}-cix-{row['board_package']}"].parent for row in rows}
        if len(libc[version]) != len(rows) or {deb.parent for deb in libc[version]} != expected_parents:
            raise ValueError(f"incomplete userspace-header variants for {version}")
    output.mkdir(parents=True)
    work.mkdir(parents=True)
    report = {}
    for (pv, version), rows in kernels.items():
        group = work / version
        group.mkdir()
        headers = []
        active_libc = None
        canonical_libc = None
        for index, row in enumerate(rows):
            release = f"{pv}-cix-{row['board_package']}"
            for kind in ("image", "headers"):
                name = f"linux-{kind}-{release}"
                deb = packages[name]
                if kind == "image":
                    target = output / f"{name}_{version}_arm64.deb"
                    shutil.copy2(deb, target)
                else:
                    root = group / name
                    run("dpkg-deb", "-R", deb, root)
                    headers.append(root)
            libc_deb = next(deb for deb in libc[version] if deb.parent == packages[f"linux-headers-{release}"].parent)
            libc_root = group / f"libc-{index}"
            run("dpkg-deb", "-R", libc_deb, libc_root)
            payload = inventory(libc_root, active_only=True)
            if active_libc is None:
                active_libc = payload
                canonical_libc = libc_root
            elif active_libc != payload:
                differing = sorted(name for name in active_libc.keys() | payload.keys()
                                   if active_libc.get(name) != payload.get(name))
                raise ValueError(f"userspace headers differ for {version}: {differing[:10]}")
            else:
                shutil.rmtree(libc_root)
        report[version] = split_headers(headers, pv, version, output)
        fields = read_control((canonical_libc / "DEBIAN/control").read_text(encoding="utf-8"))
        fields["Source"] = "linux-cix"
        write_control(canonical_libc, fields)
        build_package(canonical_libc, output)
        report[version]["libc_variants_verified"] = len(rows)
    (output / "package-sharing.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--matrix", type=Path, required=True)
    args = parser.parse_args()
    matrix = json.loads(args.matrix.read_text(encoding="utf-8"))
    try:
        report = assemble(args.input_dir, args.output_dir, args.work_dir, matrix)
    except (ValueError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from error
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
