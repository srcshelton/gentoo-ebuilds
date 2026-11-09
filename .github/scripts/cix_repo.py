"""Shared, read-only inputs for CIX repository checks (no ebuild execution)."""
import re
import subprocess
from pathlib import Path

PACKAGE = Path('sys-kernel/cix-sources')
REFERENCE = re.compile(r'\$\{FILESDIR\}["\']?/([^\s"\'\\]+\.patch)')
VERSION = r'\d+\.\d+\.\d+(?:-r\d+)?'


def tracked(root):
    """Use the index as the scope; unrelated untracked work is not maintained input."""
    result = subprocess.run(['git', '-C', str(root), 'ls-files', '-z'],
                            capture_output=True, check=True)
    return {Path(p.decode()) for p in result.stdout.split(b'\0') if p}


def version(value):
    return tuple(int(n) for n in re.findall(r'\d+', value))


class Repository:
    def __init__(self, root, paths=None):
        self.root = Path(root)
        self.paths = tracked(self.root) if paths is None else set(paths)
        self.ebuilds = {}
        self.references = []
        self.retained = set()
        self.errors = []
        for path in sorted(self.paths):
            match = re.fullmatch(r'cix-sources-(' + VERSION + r')\.ebuild', path.name)
            if path.parent != PACKAGE or not match:
                continue
            v = match[1]
            text = self.read(path)
            values = {}
            for key in ('K_WANT_GENPATCHES', 'K_GENPATCHES_VER', 'EGIT_CIX_COMMIT', 'IUSE'):
                assignment = re.search(r'^' + key + r'="([^"]*)"', text, re.M)
                if not assignment:
                    self.fail(path, 1, f'expected literal {key} assignment')
                values[key] = assignment[1] if assignment else ''
            self.ebuilds[path] = (v, '.'.join(v.split('.')[:2]), values)
            guards = []
            for number, line in enumerate(text.splitlines(), 1):
                if line.lstrip().startswith('#'):
                    self.retained.update(REFERENCE.findall(line))
                    continue
                # Only the package's explicit USE conditionals are relevant here.
                if re.match(r'\s*if\b', line):
                    guards.append(line)
                elif re.match(r'\s*(else|elif)\b', line) and guards:
                    guards[-1] = line
                for ref in REFERENCE.findall(line.split(' #', 1)[0]):
                    self.references.append((path, number, ref, '\n'.join(guards)))
                if re.match(r'\s*fi\b', line) and guards:
                    guards.pop()

    def read(self, path):
        return (self.root / path).read_text(encoding='utf-8')

    def fail(self, path, line, message):
        self.errors.append(f'{path}:{line}: {message}')

    def latest(self):
        result = {}
        for path, (v, line, values) in self.ebuilds.items():
            if line not in result or version(v) > version(result[line][1]):
                result[line] = (path, v, values)
        return result

    def active(self):
        return {ref for _, _, ref, _ in self.references}
