#!/usr/bin/env python3
"""Focused static-check regressions; all patch fixtures are source-tree diffs."""
import difflib
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from cix_repo import PACKAGE, Repository, tracked


def load(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


layout = load('check-cix-patch-layout')
markdown = load('check-markdown-staleness')
changes = load('cix-build-changes')


class Checks(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.paths = set()
        self.patch('shared.patch', 'shared')
        self.patch('6.18.x/local.patch', '6.18')
        self.patch('7.2.x/local.patch', '7.2')
        for v in ('6.18.62', '7.2.15'):
            line = '.'.join(v.split('.')[:2])
            self.write(PACKAGE / f'cix-sources-{v}.ebuild', f'''K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="70"
EGIT_CIX_COMMIT="{'a' * 40}"
IUSE="experimental +radxa-menu"
PATCHES=( "${{FILESDIR}}"/shared.patch "${{FILESDIR}}"/{line}.x/local.patch )
''')
        self.doc = PACKAGE / 'files/README.md'
        self.write(self.doc, '`shared.patch` `local.patch`\n')
        self.manifest()

    def write(self, path, text):
        self.paths.add(path)
        dest = self.root / path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text)

    def patch(self, ref, content):
        data = ''.join(difflib.unified_diff(['before\n'], [content + '\n'],
                                           fromfile='a/file', tofile='b/file'))
        self.write(PACKAGE / 'files' / ref, data)

    def manifest(self):
        rows = []
        for path in sorted(self.paths):
            if not path.is_relative_to(PACKAGE / 'files'):
                continue
            data = (self.root / path).read_bytes()
            rows.append(f'AUX {path.relative_to(PACKAGE / "files")} {len(data)} '
                        f'BLAKE2B {hashlib.blake2b(data).hexdigest()} SHA512 {hashlib.sha512(data).hexdigest()}')
        self.write(PACKAGE / 'Manifest', '\n'.join(rows) + '\n')

    def run_check(self, checker):
        return '\n'.join(checker.check(Repository(self.root, self.paths)))

    def append_doc(self, text):
        self.write(self.doc, (self.root / self.doc).read_text() + text + '\n')

    def edit_ebuild(self, old, new, v='6.18.62'):
        path = PACKAGE / f'cix-sources-{v}.ebuild'
        self.write(path, (self.root / path).read_text().replace(old, new))

    def test_valid(self):
        self.assertEqual(self.run_check(layout), '')
        self.assertEqual(self.run_check(markdown), '')

    def test_git_tracking_and_failure_stderr(self):
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        subprocess.run(['git', '-C', str(self.root), 'add', str(self.doc)], check=True)
        self.assertEqual(tracked(self.root), {self.doc})
        outside = self.root / 'not-a-repository'
        outside.mkdir()
        # Prevent Git from finding the parent fixture's repository.
        result = subprocess.run(
            [sys.executable, str(Path(__file__).with_name('check-cix-patch-layout.py')),
             '--root', str(outside)],
            env={**os.environ, 'GIT_CEILING_DIRECTORIES': str(self.root), 'LC_ALL': 'C'},
            capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('fatal: not a git repository', result.stderr)

    def test_bad_directories(self):
        for directory in ('6.18.62', 'unknown', '6.18.x/nested'):
            with self.subTest(directory=directory):
                self.patch(directory + '/bad.patch', directory)
                self.assertIn('invalid patch directory', self.run_check(layout))

    def test_missing_reference(self):
        self.edit_ebuild('shared.patch', 'missing.patch')
        self.assertIn('missing maintained patch', self.run_check(layout))

    def test_wrong_kernel_line(self):
        self.edit_ebuild('6.18.x/local.patch', '7.2.x/local.patch')
        self.assertIn('expected patch for kernel line', self.run_check(layout))

    def test_duplicate_shared(self):
        self.patch('6.18.x/copy.patch', 'shared')
        self.manifest()
        self.assertIn('byte-identical patches', self.run_check(layout))

    def test_line_specific_at_root(self):
        self.edit_ebuild('shared.patch', 'only.patch')
        self.patch('only.patch', 'only')
        self.manifest()
        self.assertIn('line-specific patch must be under', self.run_check(layout))

    def test_manifest_metadata(self):
        for old, new, diagnostic in (('BLAKE2B ', 'BLAKE2B f', 'expected BLAKE2B'),
                                     ('SHA512 ', 'SHA512 f', 'expected SHA512'),
                                     ('shared.patch ', 'shared.patch 0', 'expected size')):
            with self.subTest(diagnostic=diagnostic):
                self.manifest()
                path = PACKAGE / 'Manifest'
                self.write(path, (self.root / path).read_text().replace(old, new))
                self.assertIn(diagnostic, self.run_check(layout))

    def test_missing_manifest_entry(self):
        self.write(PACKAGE / 'Manifest', '')
        self.assertIn('missing AUX entry', self.run_check(layout))

    def test_duplicate_and_missing_aux(self):
        path = PACKAGE / 'Manifest'
        text = (self.root / path).read_text()
        self.write(path, text + text)
        self.assertIn('duplicate AUX entry', self.run_check(layout))
        self.write(path, text.replace('shared.patch', 'missing.patch'))
        self.assertIn('AUX file does not exist', self.run_check(layout))

    def test_retained_unapplied(self):
        self.patch('7.2.x/71140-retained.patch', 'retained')
        self.edit_ebuild('\nPATCHES=', '\n# "${FILESDIR}"/7.2.x/71140-retained.patch\nPATCHES=', '7.2.15')
        self.manifest()
        self.assertEqual(self.run_check(layout), '')
        self.assertEqual(self.run_check(markdown), '')

    def test_unexplained_orphan(self):
        self.patch('6.18.x/orphan.patch', 'orphan')
        self.manifest()
        self.assertIn('unapplied patch needs', self.run_check(layout))

    def test_qualified_name_is_not_introduction_guess(self):
        self.patch('6.18.x/0003-6.18.57-new.patch', 'new')
        self.edit_ebuild('6.18.x/local.patch', '6.18.x/0003-6.18.57-new.patch')
        self.manifest()
        self.assertIn('explicit compatibility provenance', self.run_check(layout))

    def test_explicit_boundary_provenance(self):
        ref = '6.18.x/0003-6.18.57-new.patch'
        self.patch(ref, 'new')
        self.edit_ebuild('6.18.x/local.patch', ref)
        self.edit_ebuild('\nPATCHES=', '\n# "${FILESDIR}"/6.18.x/local.patch\nPATCHES=')
        record = {ref: {'boundary': '6.18.57', 'commit': 'a' * 40,
                        'reason': 'SCMI lifetime preimage changed; older variant was retired.'}}
        self.write(Path('.github/scripts/cix-patch-boundaries.json'), json.dumps(record))
        self.manifest()
        self.assertEqual(self.run_check(layout), '')
        record[ref]['boundary'] = '6.18.56'
        self.write(Path('.github/scripts/cix-patch-boundaries.json'), json.dumps(record))
        self.assertIn('explicit compatibility provenance', self.run_check(layout))

    def test_valid_current_package_and_link(self):
        self.append_doc('`linux-libc-dev_6.18.62-1_arm64.deb` [inventory](README.md)')
        self.assertEqual(self.run_check(markdown), '')

    def test_stale_kernel_list(self):
        self.append_doc('| Kernel | `6.18.54`, `7.2.15` | Maintained |')
        self.assertIn('expected maintained kernels', self.run_check(markdown))

    def test_wrong_patch_path(self):
        self.append_doc('`6.18.62/local.patch`')
        self.assertIn('documented local patch path does not exist', self.run_check(markdown))

    def test_two_sided_boundary(self):
        self.patch('6.18.x/0003-new.patch', 'old')
        self.patch('6.18.x/0003-6.18.62-new.patch', 'new')
        self.edit_ebuild('6.18.x/local.patch', '6.18.x/0003-new.patch')
        old = PACKAGE / 'cix-sources-6.18.62.ebuild'
        self.write(PACKAGE / 'cix-sources-6.18.61.ebuild', (self.root / old).read_text())
        self.edit_ebuild('6.18.x/0003-new.patch', '6.18.x/0003-6.18.62-new.patch')
        self.edit_ebuild('\nPATCHES=', '\n# "${FILESDIR}"/6.18.x/local.patch\nPATCHES=')
        self.manifest()
        self.assertEqual(self.run_check(layout), '')

    def test_experimental_guard(self):
        self.patch('7.2.x/10070-experimental-policy.patch', 'experimental')
        self.edit_ebuild('7.2.x/local.patch', '7.2.x/10070-experimental-policy.patch', '7.2.15')
        self.manifest()
        self.assertIn('expected explicit use experimental', self.run_check(layout))
        self.edit_ebuild('\nPATCHES=', '\nif use experimental; then\nPATCHES=', '7.2.15')
        self.edit_ebuild(' )', ' )\nfi', '7.2.15')
        self.edit_ebuild('\nPATCHES=', '\n# "${FILESDIR}"/7.2.x/local.patch\nPATCHES=', '7.2.15')
        self.assertEqual(self.run_check(layout), '')

    def test_profile_guard(self):
        self.patch('7.2.x/90050-radxa-profile.patch', 'profile')
        self.edit_ebuild('7.2.x/local.patch', '7.2.x/90050-radxa-profile.patch', '7.2.15')
        self.manifest()
        self.assertIn('expected explicit use radxa-menu', self.run_check(layout))

    def test_stale_package(self):
        self.append_doc('`linux-image-6.18.54-cix-o6-acpi-fw1.2-arm64_6.18.54-1_arm64.deb`')
        self.assertIn('stale/invalid package example', self.run_check(markdown))

    def test_invalid_package_revision(self):
        self.append_doc('`linux-libc-dev_6.18.62-2_arm64.deb`')
        self.assertIn('stale/invalid package example', self.run_check(markdown))

    def test_stale_ebuild(self):
        self.append_doc('`cix-sources-6.18.54.ebuild`')
        self.assertIn('stale cix-sources', self.run_check(markdown))

    def test_kernel_and_genpatches(self):
        self.append_doc('| [Linux 6.18.62](https://example.org) | `cix-sources-6.18.62` | `6.18-69` base and extras | source |')
        self.assertIn('expected Gentoo genpatches 6.18-70', self.run_check(markdown))

    def test_genpatches_selection(self):
        self.append_doc('| [Linux 6.18.62](https://example.org) | `cix-sources-6.18.62` | `6.18-70` base, extras, experimental | source |')
        self.assertIn('expected Gentoo selections: base extras', self.run_check(markdown))

    def test_cix_pin(self):
        self.append_doc('https://github.com/cixtech/cix-linux-main/commit/' + 'b' * 40)
        self.assertIn('stale CIX source pin', self.run_check(markdown))

    def test_missing_documented_patch(self):
        self.append_doc('`99999-no-longer-here.patch`')
        self.assertIn('documented local patch does not exist', self.run_check(markdown))

    def test_missing_inventory(self):
        self.write(self.doc, '`shared.patch`\n')
        self.assertIn('active maintained patch missing from inventory: local.patch', self.run_check(markdown))

    def test_local_links(self):
        for text in ('[broken](missing.md)', '[broken]: missing.md', '`sys-kernel/cix-sources/missing.py`'):
            with self.subTest(text=text):
                self.write(self.doc, '`shared.patch` `local.patch`\n' + text)
                self.assertIn('broken repository-local', self.run_check(markdown))

    def test_external_vendor_and_historical(self):
        self.append_doc('''`vendor:0058-external.patch` `1510_gentoo.patch`
[external](https://example.org/no-such-file.md)
`dev-vcs/pre-commit`
<!-- cix-check: historical start: old installation example -->
`cix-sources-6.18.54` `99999-old-local.patch`
[removed](missing.md)
<!-- cix-check: historical end -->''')
        self.assertEqual(self.run_check(markdown), '')

    def test_unclosed_history(self):
        self.append_doc('<!-- cix-check: historical start: example -->')
        self.assertIn('unclosed historical', self.run_check(markdown))

    def test_documentation_build_filter(self):
        manifest = str(PACKAGE / 'Manifest')
        self.assertFalse(changes.requires_build(['README.md']))
        self.assertFalse(changes.requires_build(['README.md', manifest], 'AUX README.md 1', 'AUX README.md 2'))
        self.assertTrue(changes.requires_build([manifest], 'AUX change.patch 1', 'AUX change.patch 2'))
        self.assertTrue(changes.requires_build(['.github/scripts/check-cix-patch-layout.py']))
        self.assertTrue(changes.requires_build(['sys-kernel/cix-sources/cix-sources-7.2.15.ebuild']))


if __name__ == '__main__':
    unittest.main()
