#!/usr/bin/env python3
"""Check locally provable Markdown facts; arbitrary prose is outside this check."""
import argparse
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit
from cix_repo import PACKAGE, VERSION, Repository

PATCH_NAME = re.compile(r'(?<![\w-])((?:vendor:)?[\w.+/-]+\.patch)\b')
DEB_NAME = re.compile(r'\b(linux-(?:image|headers|libc-dev)[\w.+-]*_[\w.+~-]+_\w+\.deb)\b')


def check(repo):
    files = PACKAGE / 'files'
    latest = repo.latest()
    current = {v for _, v, _ in latest.values()}
    pins = {values['EGIT_CIX_COMMIT'] for _, _, values in repo.ebuilds.values()}
    patch_names = {p.name for p in repo.paths if p.is_relative_to(files) and p.suffix == '.patch'}
    # Vendor case labels are archive inputs, not missing local patches.
    vendor_names = set()
    for path in repo.ebuilds:
        for line in repo.read(path).splitlines():
            if '${FILESDIR}' not in line and not line.lstrip().startswith('#'):
                vendor_names.update(PATCH_NAME.findall(line))
    documented = set()
    inventory = files / 'README.md'
    root_dirs = {p.parts[0] for p in repo.paths}
    for path in sorted(p for p in repo.paths if p.suffix.lower() == '.md'):
        historical = False
        for number, line in enumerate(repo.read(path).splitlines(), 1):
            if re.fullmatch(r'\s*<!-- cix-check: historical start: .+ -->\s*', line):
                historical = True
                continue
            if line.strip() == '<!-- cix-check: historical end -->':
                historical = False
                continue
            if historical:
                continue
            def fail(message):
                repo.fail(path, number, message)
            for match in re.finditer(r'\bcix-sources-(' + VERSION + r')(?:\.ebuild)?\b', line):
                expected = PACKAGE / f'cix-sources-{match[1]}.ebuild'
                if expected not in repo.paths:
                    fail(f'stale cix-sources-{match[1]}; maintained versions: {", ".join(sorted(current))}')
            for match in re.finditer(r'\[Linux (' + VERSION + r')\]', line):
                if match[1] not in current:
                    fail(f'stale current kernel {match[1]}; expected {", ".join(sorted(current))}')
            if re.match(r'\| Kernel \|', line) and re.search(r'`\d', line):
                stated = set(re.findall(r'`(' + VERSION + r')`', line))
                if stated != current:
                    fail(f'expected maintained kernels: {", ".join(sorted(current))}')
            # Supported-kernel rows bind version, genpatches selections and CIX pin.
            if line.startswith('|') and '[Linux ' in line:
                m = re.search(r'\[Linux (' + VERSION + r')\]', line)
                if m and m[1] in current:
                    _, v, values = latest['.'.join(m[1].split('.')[:2])]
                    cells = line.split('|')
                    expected = '.'.join(v.split('.')[:2]) + '-' + values['K_GENPATCHES_VER']
                    kinds = values['K_WANT_GENPATCHES'].split()
                    if len(cells) < 5 or f'`{expected}`' not in cells[3]:
                        fail(f'expected Gentoo genpatches {expected}')
                    elif set(re.findall(r'\b(base|extras|experimental)\b', cells[3])) != set(kinds):
                        fail(f'expected Gentoo selections: {" ".join(kinds)}')
            for pin in re.findall(r'https://github\.com/cixtech/cix-linux-main/commit/([0-9a-f]+)', line):
                if pin not in pins:
                    fail(f'stale CIX source pin {pin}; expected {", ".join(sorted(pins))}')
            for pin in re.findall(r'EGIT_CIX_COMMIT=[\"\']([0-9a-f]+)', line):
                if pin not in pins:
                    fail(f'stale CIX source pin {pin}; expected {", ".join(sorted(pins))}')
            for short in re.findall(r'`(?:cix-linux-main|CIX source)` at `([0-9a-f]+)`', line):
                if not any(pin.startswith(short) for pin in pins):
                    fail(f'stale CIX source pin {short}; expected {", ".join(sorted(pins))}')
            for name in DEB_NAME.findall(line):
                valid = False
                for _, v, _ in latest.values():
                    kernel, _, revision = v.partition('-r')
                    debver = f'{kernel}-{int(revision or 0) + 1}'
                    names = {f'linux-libc-dev_{debver}_arm64.deb',
                             f'linux-headers-{kernel}-cix-common_{debver}_arm64.deb'}
                    for kind in ('image', 'headers'):
                        for board in ('o6', 'o6n'):
                            for firmware in ('1.2', '1.3'):
                                for flavour in ('arm64', 'arm64-64k'):
                                    names.add(f'linux-{kind}-{kernel}-cix-{board}-acpi-fw{firmware}-{flavour}_{debver}_arm64.deb')
                    valid |= name in names
                if not valid:
                    fail(f'stale/invalid package example {name}; expected current kernel {", ".join(sorted(current))} and matching Debian revision/board/firmware/flavour')
            for ref in PATCH_NAME.findall(line):
                name = Path(ref).name
                if ref.startswith('vendor:') or (repo.root / ref.lstrip('/')).is_file():
                    continue
                if name in patch_names:
                    if '/' in ref and files / ref not in repo.paths:
                        fail(f'documented local patch path does not exist: {ref}')
                    if path == inventory:
                        documented.add(name)
                elif name not in vendor_names and not re.match(r'^\d+_', name):
                    # Explicit links to external patch sources are outside local scope.
                    if not re.search(r'https?://[^\s)]*' + re.escape(name), line):
                        fail(f'documented local patch does not exist: {ref}')
            targets = re.findall(r'\[[^\]]*\]\(([^\s)]+)(?:\s+"[^"]*")?\)', line)
            targets += re.findall(r'^\s*\[[^\]]+\]:\s*(\S+)', line)
            for target in targets:
                target = target.strip('<>')
                url = urlsplit(target)
                if url.scheme or url.netloc or target.startswith('#'):
                    continue
                dest = unquote(url.path)
                if not dest:
                    continue
                candidate = (repo.root / (dest.lstrip('/') if dest.startswith('/') else str(path.parent / dest))).resolve()
                if not candidate.is_relative_to(repo.root.resolve()) or not candidate.exists():
                    fail(f'broken repository-local link: {target}')
            for target in re.findall(r'`([^`]+)`', line):
                if any(c in target for c in (' ', '$', '*', '<', '>')):
                    continue
                # Bare category/package names are Gentoo atoms, not file paths.
                if target.startswith(('./', '../')) or (target.count('/') >= 2 and target.split('/')[0] in root_dirs):
                    candidate = repo.root / target if not target.startswith(('./', '../')) else repo.root / path.parent / target
                    if not candidate.exists():
                        fail(f'broken repository-local path: {target}')
        if historical:
            repo.fail(path, number, 'unclosed historical example block; expected <!-- cix-check: historical end -->')
    for name in sorted({Path(ref).name for ref in repo.active()} - documented):
        repo.fail(inventory, 1, f'active maintained patch missing from inventory: {name}')
    return repo.errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('.'))
    args = parser.parse_args()
    errors = check(Repository(args.root))
    print('\n'.join(errors) if errors else 'Markdown local facts: OK')
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
