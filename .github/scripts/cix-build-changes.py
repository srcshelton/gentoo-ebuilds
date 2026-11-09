#!/usr/bin/env python3
"""Keep Markdown-only changes (including their AUX checksums) out of builds."""
import argparse
import subprocess
from pathlib import Path
from cix_repo import PACKAGE


def requires_build(paths, before_manifest='', after_manifest=''):
    for path in paths:
        if path.lower().endswith('.md'):
            continue
        if path == str(PACKAGE / 'Manifest'):
            def non_docs(text):
                return [row for row in text.splitlines() if not (
                    row.startswith('AUX ') and row.split()[1].lower().endswith('.md'))]
            if non_docs(before_manifest) == non_docs(after_manifest):
                continue
        return True
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', default='')
    parser.add_argument('--github-output', type=Path, required=True)
    args = parser.parse_args()
    def git(*arguments):
        return subprocess.check_output(['git', *arguments], text=True)
    # Dispatch, new branches, or unavailable base: preserve full qualification.
    required = True
    if args.base and set(args.base) != {'0'}:
        try:
            paths = [p for p in git('diff', '--name-only', '-z', args.base, 'HEAD').split('\0') if p]
            manifest = str(PACKAGE / 'Manifest')
            required = requires_build(paths, git('show', f'{args.base}:{manifest}'),
                                      Path(manifest).read_text())
        except subprocess.CalledProcessError:
            pass
    with args.github_output.open('a') as output:
        output.write(f'build_required={str(required).lower()}\n')


if __name__ == '__main__':
    main()
