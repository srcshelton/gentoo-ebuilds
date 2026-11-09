#!/usr/bin/env python3
"""Check maintained CIX patch placement, selections and Manifest bytes."""
import argparse
import hashlib
import json
import re
from pathlib import Path
from cix_repo import PACKAGE, Repository, version


def check(repo):
    files = PACKAGE / 'files'
    lines = {line for _, line, _ in repo.ebuilds.values()}
    patches = {str(p.relative_to(files)): p for p in repo.paths
               if p.is_relative_to(files) and p.suffix == '.patch'}
    for p in sorted(repo.paths):
        if not p.is_relative_to(files):
            continue
        parts = p.relative_to(files).parts
        if len(parts) > 1 and parts[0] != 'acpi-table-upgrade':
            if parts[0] not in {line + '.x' for line in lines} or len(parts) != 2:
                repo.fail(p, 1, 'invalid patch directory; expected files/ or files/<major>.<minor>.x/')
    hashes = {}
    usage = {}
    for path, number, ref, guards in repo.references:
        v, line, values = repo.ebuilds[path]
        if ref not in patches or not (repo.root / files / ref).is_file():
            repo.fail(path, number, f'missing maintained patch: files/{ref}')
            continue
        usage.setdefault(ref, []).append(v)
        if '/' in ref and ref.split('/')[0] != line + '.x':
            repo.fail(path, number, f'expected patch for kernel line {line}.x: {ref}')
        for marker, flag in (('experimental', 'experimental'), ('radxa', 'radxa-menu')):
            if marker in Path(ref).name and (
                not re.search(r'\buse\s+' + flag + r'\b', guards)
                or re.search(r'!\s*use\s+' + flag + r'\b', guards)
                or flag not in values['IUSE'].replace('+', '').split()
            ):
                repo.fail(path, number, f'{ref}: expected explicit use {flag} selection and IUSE')
    manifest = PACKAGE / 'Manifest'
    entries = {}
    for number, row in enumerate(repo.read(manifest).splitlines(), 1):
        words = row.split()
        if not words or words[0] != 'AUX':
            continue
        if len(words) < 5 or len(words) % 2 != 1:
            repo.fail(manifest, number, 'malformed AUX entry')
            continue
        ref = words[1]
        if ref in entries:
            repo.fail(manifest, number, f'duplicate AUX entry: {ref}')
        entries[ref] = number
        p = files / ref
        if p not in repo.paths or not (repo.root / p).is_file():
            repo.fail(manifest, number, f'AUX file does not exist: {ref}')
            continue
        data = (repo.root / p).read_bytes()
        if words[2] != str(len(data)):
            repo.fail(manifest, number, f'{ref}: expected size {len(data)}')
        sums = dict(zip(words[3::2], words[4::2]))
        for kind, algorithm in (('BLAKE2B', 'blake2b'), ('SHA512', 'sha512')):
            expected = hashlib.new(algorithm, data).hexdigest()
            if sums.get(kind) != expected:
                repo.fail(manifest, number, f'{ref}: expected {kind} {expected}')
    for ref, versions in usage.items():
        if '/' not in ref and len({'.'.join(v.split('.')[:2]) for v in versions}) < 2:
            repo.fail(files / ref, 1, 'line-specific patch must be under files/<major>.<minor>.x/')
    provenance_path = Path('.github/scripts/cix-patch-boundaries.json')
    provenance = json.loads(repo.read(provenance_path)) if (repo.root / provenance_path).exists() else {}
    for ref, p in sorted(patches.items()):
        if ref not in entries:
            repo.fail(manifest, 1, f'missing AUX entry for {ref}')
        if not (repo.root / p).exists():
            continue
        digest = hashlib.sha256((repo.root / p).read_bytes()).digest()
        hashes.setdefault(digest, []).append(ref)
        if ref not in usage and ref not in repo.retained:
            repo.fail(p, 1, 'unapplied patch needs an explicit commented FILESDIR reference (retained/quarantined)')
        boundary = re.match(r'(?:\d+|linux)-(\d+\.\d+\.\d+)-', p.name)
        if not boundary:
            continue
        threshold = boundary[1]
        peers = [other for other in usage if other != ref and
                 Path(other).parent == Path(ref).parent and
                 Path(other).name == p.name.replace(threshold + '-', '', 1)]
        # Current usage proves a boundary only when both sides still exist.
        proven = bool(peers) and min(map(version, usage.get(ref, [threshold]))) == version(threshold)
        proven = proven and all(version(v) < version(threshold) for peer in peers for v in usage[peer])
        evidence = provenance.get(ref, {})
        if not proven and not (evidence.get('boundary') == threshold and
                               re.fullmatch(r'[0-9a-f]{40}', evidence.get('commit', '')) and
                               evidence.get('reason')):
            repo.fail(p, 1, f'version qualifier {threshold} needs two-sided ebuild usage or explicit compatibility provenance in {provenance_path}')
        if any(version(v) < version(threshold) for v in usage.get(ref, [])):
            repo.fail(p, 1, f'used before compatibility boundary {threshold}')
    for copies in hashes.values():
        if len(copies) > 1:
            repo.fail(files / copies[0], 1, 'byte-identical patches must share one files/ entry: ' + ', '.join(copies))
    return repo.errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('.'))
    args = parser.parse_args()
    errors = check(Repository(args.root))
    print('\n'.join(errors) if errors else 'CIX patch layout: OK')
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
