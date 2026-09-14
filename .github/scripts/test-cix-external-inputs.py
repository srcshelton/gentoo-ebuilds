#!/usr/bin/env python3
"""Check compact metadata, retained-input refresh and version-check consumers."""

import argparse
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from cix_external_inputs import (
    compact_acpica_metadata,
    compact_gentoo_metadata,
    load_json,
    validate_directory,
    write_checksums,
)


SCRIPTS = Path(__file__).resolve().parent
ROOT = SCRIPTS.parents[1]
FALLBACK = ROOT / ".github/fallbacks/cix-external-inputs"


def load_script(name):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


REFRESH = load_script("refresh-cix-external-inputs")
VERSIONS = load_script("check-cix-source-versions")
MATRIX = load_script("discover-cix-matrix")


class MetadataTests(unittest.TestCase):
    def test_latest_maintained_versions_only(self):
        entries = [
            {"name": f"gentoo-sources-{version}.ebuild", "unused": "discard"}
            for version in (
                "6.18.9-r9", "6.18.10", "7.1.13-r2", "7.1.13-r10",
                "7.2.6", "7.2.5-r99", "6.1.200", "7.3.1",
            )
        ] + [{"name": "Manifest"}, {"name": "metadata.xml"}]
        compact = compact_gentoo_metadata(entries)
        self.assertEqual(compact, [
            {"name": "gentoo-sources-6.18.10.ebuild"},
            {"name": "gentoo-sources-7.2.6.ebuild"},
        ])
        self.assertEqual(compact_gentoo_metadata(list(reversed(entries))), compact)
        self.assertEqual(compact_gentoo_metadata(compact), compact)
        self.assertEqual(
            VERSIONS.select_versions([e["name"] for e in entries], "gentoo-sources-"),
            VERSIONS.select_versions([e["name"] for e in compact], "gentoo-sources-"),
        )

    def test_retained_matrix_matches_metadata(self):
        selected = MATRIX.select_ebuilds(ROOT / "sys-kernel/cix-sources")
        self.assertEqual({entry["line"] for entry in selected}, {"6.18", "7.2"})
        self.assertEqual(MATRIX.REQUIRED_LINES, set(VERSIONS.REQUIRED_LINES))
        build = MATRIX.expand_build_matrix(selected)["include"]
        self.assertEqual(len(build), 16)
        self.assertEqual(len({
            (entry["line"], entry["board_profile"], entry["firmware"],
             entry["config_flavour"]) for entry in build
        }), 16)
        for entry in selected:
            metadata = load_json(FALLBACK / "ubuntu-configs" /
                                 entry["ubuntu_config_seed"] / "metadata.json")
            self.assertIn(entry["line"], metadata["consumer_lines"])

    def test_retired_ebuild_cannot_reenter_matrix(self):
        with tempfile.TemporaryDirectory(prefix="cix-matrix-test-") as directory:
            package = Path(directory)
            for version in ("6.18.53", "7.1.13", "7.2.7"):
                (package / f"cix-sources-{version}.ebuild").touch()
            with self.assertRaisesRegex(SystemExit, "Linux 7.1 has no declared"):
                MATRIX.select_ebuilds(package)

    def test_incomplete_gentoo_metadata_rejected(self):
        for entries in ({}, [None], [], [{"name": "gentoo-sources-6.18.52.ebuild"}]):
            with self.subTest(entries=entries), self.assertRaises(ValueError):
                compact_gentoo_metadata(entries)

    def test_acpica_keeps_only_used_asset_fields(self):
        source = {
            "name": "acpica-unix-20260408.tar.gz",
            "browser_download_url": (
                "https://github.com/open-acpica/acpica/releases/download/"
                "20260408/acpica-unix-20260408.tar.gz"
            ),
        }
        release = {
            "body": "unused release notes",
            "author": {"login": "unused"},
            "assets": [
                {"name": "iasl.exe"},
                dict(source, uploader={"login": "unused"}, download_count=100),
            ],
        }
        self.assertEqual(compact_acpica_metadata(release), {"assets": [source]})
        self.assertEqual(compact_acpica_metadata({"assets": [source]}), {"assets": [source]})

    def test_invalid_acpica_metadata_rejected(self):
        for release in ([], {}, {"assets": {}}, {"assets": [{
            "name": "acpica-unix-20260408.tar.gz",
            "browser_download_url": "https://example.invalid/archive.tar.gz",
        }]}):
            with self.subTest(release=release), self.assertRaises(ValueError):
                compact_acpica_metadata(release)

    def test_repository_fallback_is_compact_and_valid(self):
        validate_directory(FALLBACK)
        gentoo = load_json(FALLBACK / "gentoo-sources/contents.json")
        acpica = load_json(FALLBACK / "acpica/latest-release.json")
        self.assertEqual(gentoo, compact_gentoo_metadata(gentoo))
        self.assertEqual(acpica, compact_acpica_metadata(acpica))


class RefreshTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cix-metadata-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.fallback = self.root / "fallback"
        shutil.copytree(FALLBACK, self.fallback)
        # Simulate an artifact produced by the old, unfiltered refresh code.
        gentoo_path = self.fallback / "gentoo-sources/contents.json"
        self.gentoo = load_json(gentoo_path)
        self.gentoo[0]["unused"] = "old artifact metadata"
        self.gentoo.append({"name": "gentoo-sources-6.1.200.ebuild"})
        gentoo_path.write_text(json.dumps(self.gentoo), encoding="utf-8")
        acpica_path = self.fallback / "acpica/latest-release.json"
        self.acpica = load_json(acpica_path)
        self.acpica["body"] = "old release notes"
        acpica_path.write_text(json.dumps(self.acpica), encoding="utf-8")
        write_checksums(self.fallback)
        self.output = self.root / "output"

    def refresh(self, offline=False):
        args = argparse.Namespace(
            fallback_dir=self.fallback, output_dir=self.output,
            work_dir=self.root / "work", offline=offline,
        )
        with patch.object(REFRESH, "parse_args", return_value=args):
            with contextlib.redirect_stdout(io.StringIO()):
                REFRESH.main()
        validate_directory(self.output)
        self.assertEqual(
            load_json(self.output / "gentoo-sources/contents.json"),
            compact_gentoo_metadata(self.gentoo),
        )
        self.assertEqual(
            load_json(self.output / "acpica/latest-release.json"),
            compact_acpica_metadata(self.acpica),
        )
        for path in (self.fallback / "ubuntu-configs").rglob("*"):
            if path.is_file():
                self.assertEqual(path.read_bytes(),
                                 (self.output / path.relative_to(self.fallback)).read_bytes())

    def assert_retained_timestamps(self):
        before = load_json(self.fallback / "retention.json")["components"]
        after = load_json(self.output / "retention.json")["components"]
        for name in before:
            self.assertEqual(after[name]["state"], "retained")
            self.assertEqual(after[name]["last_refreshed_at"],
                             before[name]["last_refreshed_at"])

    def test_offline_refresh_compacts_older_artifact_without_network(self):
        with patch.object(REFRESH.urllib.request, "urlopen") as fetch:
            self.refresh(offline=True)
        fetch.assert_not_called()
        self.assert_retained_timestamps()

    def test_successful_fetch_is_compacted(self):
        self.gentoo[0]["name"] = "gentoo-sources-6.18.999.ebuild"
        self.acpica["assets"][0] = {
            "name": "acpica-unix-20260409.tar.gz",
            "browser_download_url": (
                "https://github.com/acpica/acpica/releases/download/"
                "20260409/acpica-unix-20260409.tar.gz"
            ),
            "download_count": 1,
        }

        def response(request, **kwargs):
            payload = self.gentoo if request.full_url == REFRESH.GENTOO_URL else self.acpica
            return io.BytesIO(json.dumps(payload).encode())

        with patch.object(REFRESH.urllib.request, "urlopen", side_effect=response):
            with patch.object(REFRESH.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
                self.refresh()
        records = load_json(self.output / "retention.json")["components"]
        self.assertEqual(records["gentoo-sources"]["state"], "refreshed")
        self.assertEqual(records["acpica"]["state"], "refreshed")

    def test_failed_fetch_retains_and_compacts_old_metadata(self):
        for payload in (None, b"not JSON", b"{}"):
            with self.subTest(payload=payload):
                if self.output.exists():
                    shutil.rmtree(self.output)
                fetch = {"side_effect": OSError("offline")} if payload is None else {
                    "side_effect": lambda *args, **kwargs: io.BytesIO(payload)
                }
                with patch.object(REFRESH.urllib.request, "urlopen", **fetch):
                    with patch.object(REFRESH.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
                        self.refresh()
                self.assert_retained_timestamps()

    def test_restored_bundle_and_version_checker_cli(self):
        restored = self.root / "restored"
        subprocess.run(
            [SCRIPTS / "restore-cix-external-inputs.sh", self.fallback, restored],
            env={**os.environ, "CIX_EXTERNAL_INPUTS_OFFLINE": "1"},
            check=True, capture_output=True,
        )
        self.assertEqual(load_json(restored / "gentoo-sources/contents.json"), self.gentoo)
        subprocess.run([
            sys.executable, SCRIPTS / "refresh-cix-external-inputs.py", "--offline",
            "--fallback-dir", restored, "--output-dir", self.output,
            "--work-dir", self.root / "work",
        ], check=True, capture_output=True)
        # The checker must still detect a newer upstream version, not copy local versions.
        package = self.root / "package"
        package.mkdir()
        entries = load_json(self.output / "gentoo-sources/contents.json")
        for entry in entries:
            (package / entry["name"].replace("gentoo-", "cix-", 1)).touch()
        command = [
            sys.executable, SCRIPTS / "check-cix-source-versions.py",
            "--package-dir", package, "--upstream-json",
            self.output / "gentoo-sources/contents.json",
        ]
        subprocess.run(command, check=True, capture_output=True)
        (package / entries[0]["name"].replace("gentoo-", "cix-", 1)).unlink()
        (package / "cix-sources-6.18.0.ebuild").touch()
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("out of date: Linux 6.18:", result.stdout)


if __name__ == "__main__":
    unittest.main()
