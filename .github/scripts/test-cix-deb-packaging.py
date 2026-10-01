#!/usr/bin/env python3
"""Exercise package identities, payload sharing and failure gates with real .debs."""

import importlib.util
import os
from pathlib import Path
import shutil
import tempfile
import unittest
import uuid


SCRIPTS = Path(__file__).resolve().parent
ROOT = SCRIPTS.parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


MATRIX = load("discover-cix-matrix")
ASSEMBLE = load("assemble-cix-debs")


class PackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        parent = ROOT / ".worktrees"
        parent.mkdir(exist_ok=True)
        session = os.environ.get("CODEX_THREAD_ID") or os.environ.get("GITHUB_RUN_ID") or str(uuid.uuid4())
        cls.workspace = tempfile.TemporaryDirectory(prefix=f"codex-agent-{session}-deb-tests-", dir=parent)
        cls.addClassCleanup(cls.workspace.cleanup)

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(dir=self.workspace.name)
        self.addCleanup(self.directory.cleanup)
        self.work = Path(self.directory.name)

    def matrix(self):
        package = self.work / "ebuilds"
        package.mkdir()
        for version in ("6.18.54", "7.2.8-r1"):
            (package / f"cix-sources-{version}.ebuild").touch()
        return MATRIX.expand_build_matrix(MATRIX.select_ebuilds(package))

    def test_revision_mapping(self):
        package = self.work / "ebuilds"
        package.mkdir()
        for suffix, expected in (("", 1), ("-r0", 1), ("-r1", 2), ("-r9", 10)):
            for line in ("6.18.54", "7.2.8"):
                (package / f"cix-sources-{line}{suffix}.ebuild").touch()
            selected = MATRIX.select_ebuilds(package)
            self.assertEqual({row["deb_revision"] for row in selected}, {expected})
            self.assertEqual({row["deb_version"] for row in selected},
                             {f"6.18.54-{expected}", f"7.2.8-{expected}"})
            for ebuild in package.iterdir():
                ebuild.unlink()

    def test_flavours_and_firmware_names(self):
        rows = self.matrix()["include"]
        self.assertEqual(len(rows), 16)
        self.assertEqual({row["board_package"] for row in rows}, {
            f"{board}-acpi-fw{firmware}-{flavour}"
            for board in ("o6", "o6n") for firmware in ("1.2", "1.3")
            for flavour in ("arm64", "arm64-64k")
        })
        for row in rows:
            expected = "arm64-64k" if row["config_flavour"] == "generic-64k" else "arm64"
            self.assertEqual(row["config_package"], expected)

    def test_package_flavour_matches_frozen_page_size(self):
        for seed in MATRIX.UBUNTU_CONFIG_ARTIFACT_BY_SEED:
            directory = ROOT / ".github/fallbacks/cix-external-inputs/ubuntu-configs" / seed
            for flavour, symbol in (("generic", "CONFIG_ARM64_4K_PAGES=y"),
                                    ("generic-64k", "CONFIG_ARM64_64K_PAGES=y")):
                config = (directory / f"arm64-{flavour}.config").read_text().splitlines()
                self.assertIn(symbol, config)
                self.assertNotIn("CONFIG_ARM64_16K_PAGES=y", config)

    def make_inputs(self, matrix):
        inputs = self.work / "inputs"
        inputs.mkdir()
        for index, row in enumerate(matrix["include"]):
            destination = inputs / f"variant-{index}"
            destination.mkdir()
            release = f"{row['pv']}-cix-{row['board_package']}"
            for kind in ("image", "headers", "libc-dev"):
                name = "linux-libc-dev" if kind == "libc-dev" else f"linux-{kind}-{release}"
                root = self.work / f"root-{index}-{kind}"
                root.mkdir()
                fields = {"Package": name, "Version": row["deb_version"],
                          "Architecture": "arm64", "Section": "kernel",
                          "Maintainer": "CIX Test <test@example.invalid>",
                          "Description": "Test package"}
                ASSEMBLE.write_control(root, fields)
                doc = root / "usr/share/doc" / name
                doc.mkdir(parents=True)
                (doc / "changelog.Debian.gz").write_bytes(f"metadata-{index}".encode())
                (doc / "copyright").write_text("GPL-2.0\n")
                if kind == "headers":
                    tree = root / "usr/src" / name
                    for path, content in {
                        "Makefile": "all:\n\t@cat include/test.h\n",
                        "include/test.h": f"/* common {row['pv']} */\n",
                        "scripts/tool": "#!/bin/sh\necho common\n",
                        "include/same.h": "same bytes but different permissions\n",
                        "include/config/auto.conf": f"CONFIG_FLAVOUR={index}\n",
                        "include/config/kernel.release": release + "\n",
                        "include/generated/autoconf.h": f"#define VARIANT {index}\n",
                        "arch/arm64/include/generated/same.h": "generated, keep private\n",
                        "Module.symvers": f"symbol-{index}\n",
                    }.items():
                        file = tree / path
                        file.parent.mkdir(parents=True, exist_ok=True)
                        file.write_text(content)
                    (tree / "scripts/tool").chmod(0o755)
                    (tree / "include/same.h").chmod(0o600 if index % 2 else 0o644)
                    (tree / "include/alias.h").symlink_to("test.h")
                    link = root / "lib/modules" / release / "build"
                    link.parent.mkdir(parents=True)
                    link.symlink_to(f"/usr/src/{name}")
                    # Force different archive timestamps without changing data.
                    os.utime(tree / "include/test.h", (1700000000 + index, 1700000000 + index))
                elif kind == "image":
                    boot = root / "boot"
                    boot.mkdir()
                    (boot / f"vmlinuz-{release}").write_bytes(f"image-{index}".encode())
                else:
                    include = root / "usr/include/linux"
                    include.mkdir(parents=True)
                    (include / "version.h").write_text(f"/* userspace {row['pv']} */\n")
                ASSEMBLE.build_package(root, destination)
        return inputs

    def assemble(self, inputs, matrix):
        return ASSEMBLE.assemble(inputs, self.work / "output", self.work / "assembly", matrix)

    def test_real_packages_reconstruct_every_original_headers_tree(self):
        matrix = self.matrix()
        inputs = self.make_inputs(matrix)
        originals = {}
        for deb in inputs.rglob("linux-headers-*.deb"):
            root = self.work / (deb.parent.name + "-original")
            ASSEMBLE.run("dpkg-deb", "-R", deb, root)
            originals[deb.name] = ASSEMBLE.inventory(root)
        report = self.assemble(inputs, matrix)
        output = self.work / "output"
        self.assertEqual(len(list(output.glob("*.deb"))), 36)
        self.assertEqual(len(list(output.glob("linux-libc-dev_*.deb"))), 2)
        self.assertEqual(len(list(output.glob("*-cix-common_*.deb"))), 2)
        for version, result in report.items():
            self.assertEqual(result["libc_variants_verified"], 8)
            self.assertEqual(result["shared_files"], 3)
        # Install the common and flavour payloads into one filesystem namespace.
        installed = self.work / "installed"
        installed.mkdir()
        for deb in output.glob("*-cix-common_*.deb"):
            ASSEMBLE.run("dpkg-deb", "-x", deb, installed)
        for deb in output.glob("linux-headers-*.deb"):
            if "-cix-common_" in deb.name:
                continue
            root = self.work / (deb.stem + "-check")
            ASSEMBLE.run("dpkg-deb", "-R", deb, root)
            fields = ASSEMBLE.read_control((root / "DEBIAN/control").read_text())
            pv = fields["Package"].split("-cix-", 1)[0].removeprefix("linux-headers-")
            self.assertEqual(fields["Depends"], f"linux-headers-{pv}-cix-common (= {fields['Version']})")
            ASSEMBLE.run("dpkg-deb", "-x", deb, installed)
            original = originals[deb.name]
            rebuilt = ASSEMBLE.inventory(root)
            for name, entry in rebuilt.items():
                if entry[0] == "link" and original[name][0] == "file":
                    rebuilt[name] = ASSEMBLE.signature((installed / name).resolve())
            self.assertEqual(rebuilt, original)
            tree = installed / "usr/src" / fields["Package"]
            self.assertEqual(ASSEMBLE.run("make", "-s", "-C", tree).strip(), f"/* common {pv} */")

    def test_reject_different_userspace_payload(self):
        matrix = self.matrix()
        inputs = self.make_inputs(matrix)
        deb = next((inputs / "variant-1").glob("linux-libc-dev_*.deb"))
        root = self.work / "changed-libc"
        ASSEMBLE.run("dpkg-deb", "-R", deb, root)
        (root / "usr/include/linux/version.h").write_text("unexpected ABI difference\n")
        deb.unlink()
        ASSEMBLE.build_package(root, deb.parent)
        with self.assertRaisesRegex(ValueError, "userspace headers differ"):
            self.assemble(inputs, matrix)

    def test_reject_missing_or_duplicate_variant(self):
        matrix = self.matrix()
        inputs = self.make_inputs(matrix)
        deb = next((inputs / "variant-0").glob("linux-headers-*.deb"))
        shutil.copy2(deb, deb.with_name("duplicate.deb"))
        with self.assertRaisesRegex(ValueError, "unexpected or duplicate package"):
            self.assemble(inputs, matrix)
        deb.with_name("duplicate.deb").unlink()
        next((inputs / "variant-0").glob("linux-libc-dev_*.deb")).unlink()
        with self.assertRaisesRegex(ValueError, "incomplete userspace-header variants"):
            self.assemble(inputs, matrix)


if __name__ == "__main__":
    if shutil.which("dpkg-deb") is None:
        raise SystemExit("dpkg-deb is required: run these checks in Debian/Ubuntu")
    unittest.main()
