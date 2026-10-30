#!/usr/bin/env python3
"""Validate actual compiled profile payloads against the approved USB allowlist.

Usage: test-acpi-xhci-stream-quirk.py BASELINE_BUNDLE MODIFIED_BUNDLE NEW_OUTPUT
       [--iasl /path/to/iasl]
Bundles are cix-acpi-table-upgrade directories produced by src_compile/helper.
Requires ACPICA >= 20241212. Does not evaluate AML or access hardware.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

PROPERTY = '"cdns,stream-context-quirk"'
UUID = 'daffd814-6eba-4d8c-8a91-bc9bbf4aa301'
PROFILES = {'o6/1.2', 'o6/1.3', 'o6n/1.2'}
TARGETS = {f'\\_SB_.XHC{i}' for i in range(6)}
WINDOWS = [0x09018000, 0x09088000, 0x090F8000, 0x09168000, 0x091D8000, 0x091E8000]
IRQS = [0x126, 0x12C, 0x132, 0x138, 0x11C, 0x121]
DSD = f'Name (_DSD, Package (2) {{ ToUUID ("{UUID}"), Package (1) {{ Package (2) {{ {PROPERTY}, One }} }} }})'
TOKEN = re.compile(r'"(?:\\.|[^"\\])*"|/\*.*?\*/|//[^\n]*|[\\^A-Za-z_][\\^A-Za-z_0-9.]*|0[xX][\dA-Fa-f]+|\d+|[^\s]', re.S)


def tokens(text):
    return [m[0] for m in TOKEN.finditer(text) if not m[0].startswith(('/*', '//'))]


def number(t):
    if t in ('Zero', 'One'):
        return int(t == 'One')
    return int(t, 0)


def canonical(ts):
    return [str(number(t)) if t in ('Zero', 'One') or re.fullmatch(r'0[xX][\dA-Fa-f]+|\d+', t) else t for t in ts]


def namespace(name, parent):
    result = name if name.startswith('\\') else parent.rstrip('.') + ('' if parent == '\\' else '.') + name
    return '\\_SB_' if result == '\\_SB' else result.replace('\\_SB.', '\\_SB_.')


def structure(text):
    ts = tokens(text)
    stack, pairs = [], {}
    for i, t in enumerate(ts):
        if t in ('(', '{'):
            stack.append((t, i))
        elif t in (')', '}'):
            opening, begin = stack.pop()
            assert (opening, t) in (('(', ')'), ('{', '}'))
            pairs[begin] = i
    assert not stack
    nodes, names = [], []
    for i, t in enumerate(ts[:-2]):
        if t in ('Device', 'Scope') and ts[i+1] == '(':
            end_args = pairs[i+1]
            assert ts[end_args+1] == '{'
            parents = [n for n in nodes if n['start'] < i < n['end']]
            parent = parents[-1]['path'] if parents else '\\'
            nodes.append({'path': namespace(ts[i+2], parent), 'start': i, 'end': pairs[end_args+1], 'brace': end_args+1, 'kind': t})
        elif t == 'Name' and ts[i+1] == '(':
            parents = [n for n in nodes if n['start'] < i < n['end']]
            names.append({'name': ts[i+2], 'start': i, 'end': pairs[i+1], 'owner': parents[-1]['path'] if parents else '\\'})
    return ts, nodes, names


def properties(text, expected):
    ts, nodes, names = structure(text)
    dsds = [n for n in names if n['name'] == '_DSD']
    found = [n for n in dsds if PROPERTY in ts[n['start']:n['end']+1]]
    assert ts.count(PROPERTY) == len(found), 'property outside one canonical _DSD object'
    assert Counter(n['owner'] for n in found) == Counter(expected), 'unapproved target or payload: '+str([n['owner'] for n in found])
    for n in found:
        assert sum(d['owner'] == n['owner'] for d in dsds) == 1, 'duplicate _DSD'
        assert canonical(ts[n['start']:n['end']+1]) == canonical(tokens(DSD)), 'UUID/package/type/value must be numeric one'
        uid = int(n['owner'][-1])
        own = {v['name']: ts[v['start']:v['end']+1] for v in names if v['owner'] == n['owner']}
        assert '"PNP0D10"' in own['_HID'], 'wrong own HID'
        assert number(own['_UID'][4]) == uid, 'UID selector mismatch'
        device = next(d for d in nodes if d['path'] == n['owner'] and d['kind'] == 'Device')
        body = ts[device['start']:device['end']+1]
        if 'Memory32Fixed' in body:
            at = body.index('Memory32Fixed')
            assert number(body[at+4]) == WINDOWS[uid] and number(body[at+6]) == 0x8000, 'MMIO selector mismatch'
            irq = body.index('{', body.index('Interrupt'))
            assert number(body[irq+1]) == IRQS[uid], 'interrupt selector mismatch'
        else:
            # iasl can retain a method-returned resource template as raw AML
            # Buffer bytes. Decode the standard fixed-memory/extended-IRQ
            # descriptors instead of assuming a particular disassembly style.
            at = body.index('Buffer', body.index('_CRS'))
            begin = body.index('{', at)+1
            end = body.index('}', begin)
            data = bytes(number(t) for t in body[begin:end] if t != ',')
            expected = (bytes([0x86, 9, 0, 1]) + struct.pack('<II', WINDOWS[uid], 0x8000)
                        + bytes([0x89, 6, 0, 1, 1]) + struct.pack('<I', IRQS[uid]) + bytes([0x79, 0]))
            assert data == expected, 'compiled resource selector mismatch'
    removed = {i for n in found for i in range(n['start'], n['end']+1)}
    return canonical([t for i, t in enumerate(ts) if i not in removed]), found


def run(command, log):
    r = subprocess.run(command, text=True, capture_output=True)
    log.write_text(r.stdout+r.stderr)
    assert r.returncode == 0, f'command failed; see {log}'
    return r.stdout+r.stderr


class Checker:
    def __init__(self, iasl, out):
        self.iasl, self.out, self.cache = iasl, out, {}

    def disassemble(self, aml):
        digest = hashlib.sha256(aml.read_bytes()).hexdigest()
        if digest not in self.cache:
            prefix = self.out/digest
            run([self.iasl, '-p', str(prefix), '-d', str(aml)], prefix.with_suffix('.log'))
            self.cache[digest] = prefix.with_suffix('.dsl').read_text()
        return self.cache[digest]

    def payload(self, paths, expected):
        seen = []
        for path in paths:
            if path.read_bytes()[:4] not in (b'DSDT', b'SSDT'):
                continue
            text = self.disassemble(path)
            targets = expected if path.name == 'DSDT.aml' else set()
            _, found = properties(text, targets)
            seen.extend(n['owner'] for n in found)
        assert Counter(seen) == Counter(expected), 'missing DSDT in payload'


def manifest(bundle, listfile):
    relative = listfile.relative_to(bundle)
    profile = relative.parent / relative.stem
    paths, normalized = [], []
    for line in listfile.read_text().splitlines():
        fields = line.split()
        if fields and fields[0] == 'file':
            assert fields[1].startswith('/kernel/firmware/acpi/')
            suffix = fields[2].split('/cix-acpi-table-upgrade/', 1)[1]
            assert suffix == str(profile / fields[1].lstrip('/')), 'wrong initramfs source selector'
            p = bundle/suffix
            assert p.is_file()
            paths.append(p)
            fields[2] = suffix
        normalized.append(fields)
    assert {p.name for p in paths} == {p.name for p in (bundle/profile/'kernel/firmware/acpi').glob('*.aml')}, 'unlisted table'
    return paths, normalized


def profile_id(relative):
    parent = str(relative.parent)
    if parent == '.':
        return 'o6/1.2'
    return parent+'/1.2' if parent in ('o6', 'o6n') else parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('modified', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--iasl', default='iasl')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    version = run([args.iasl, '-v'], args.output/'iasl-version.log')
    assert int(re.search(r'version (\d{8})', version)[1]) >= 20241212, 'unsupported ACPICA'
    checker = Checker(args.iasl, args.output)
    baseline, modified = args.baseline.resolve(), args.modified.resolve()
    lists = sorted(p.relative_to(modified) for p in modified.rglob('*.list'))
    assert lists == sorted(p.relative_to(baseline) for p in baseline.rglob('*.list'))
    assert len(lists) == 13 and not (modified/'o6n/1.3/initramfs-dsdt.list').exists()
    results = []
    for rel in lists:
        before, before_list = manifest(baseline, baseline/rel)
        after, after_list = manifest(modified, modified/rel)
        assert before_list == after_list, 'initramfs selection changed'
        enabled = rel.stem == 'initramfs-dsdt' and profile_id(rel) in PROFILES
        checker.payload(before, set())
        checker.payload(after, TARGETS if enabled else set())
        for b, a in zip(before, after):
            assert a.name == b.name
            if enabled and a.name == 'DSDT.aml':
                stripped, _ = properties(checker.disassemble(a), TARGETS)
                original, _ = properties(checker.disassemble(b), set())
                assert stripped == original, 'unrelated compiled DSDT semantic change'
            else:
                assert b.read_bytes() == a.read_bytes(), 'unrelated table bytes changed'
        if rel.stem == 'initramfs':
            # Direct ebuild outputs have identical installed paths. The helper
            # rewrites only the root prefix; normalized lists above must match.
            if '/usr/src/' in (baseline/rel).read_text() and '/usr/src/' in (modified/rel).read_text():
                assert (baseline/rel).read_bytes() == (modified/rel).read_bytes()
        results.append({'list': str(rel), 'canonical_profile': profile_id(rel), 'properties': 6 if enabled else 0, 'unrelated_AML_byte_identical': True})
    namespace_checks = []
    for profile in sorted(PROFILES):
        aml = modified/profile/'initramfs-dsdt/kernel/firmware/acpi/DSDT.aml'
        text = checker.disassemble(aml)
        prefix = args.output/('roundtrip-'+profile.replace('/', '-'))
        asl = prefix.with_suffix('.dsl'); asl.write_text(text)
        run([args.iasl, '-p', str(prefix), '-tc', str(asl)], prefix.with_suffix('.compile.log'))
        rebuilt = checker.disassemble(prefix.with_suffix('.aml'))
        assert canonical(tokens(text)) == canonical(tokens(rebuilt)), 'round-trip semantics changed'
        properties(rebuilt, TARGETS)
        # Use a fresh ACPICA namespace for each main input while loading every
        # other AML table for symbol resolution. Multi-input -da retains state
        # across inputs and can report duplicate external loads in this release.
        payload = aml.parent
        tables = [p for p in sorted(payload.glob('*.aml')) if p.read_bytes()[:4] in (b'DSDT', b'SSDT')]
        for table in tables:
            prefix = args.output/('namespace-'+profile.replace('/', '-')+'-'+table.stem)
            diagnostics = run([args.iasl, '-p', str(prefix), '-e',
                               *[str(p) for p in tables if p != table], '-d', str(table)],
                              prefix.with_suffix('.log'))
            assert 'AE_ALREADY_EXISTS' not in diagnostics, 'namespace name collision'
            properties(prefix.with_suffix('.dsl').read_text(), TARGETS if table.name == 'DSDT.aml' else set())
            namespace_checks.append({'profile': profile, 'table': table.name, 'status': 'PASS'})
    # Negative controls compile actual AML rather than testing fabricated parsed data.
    text = checker.disassemble(modified/'o6/1.2/initramfs-dsdt/kernel/firmware/acpi/DSDT.aml')
    ts, nodes, _ = structure(text)
    usb0 = next(n for n in nodes if n['path'] == '\\_SB_.USB0')
    positions = [m for m in TOKEN.finditer(text) if not m[0].startswith(('/*', '//'))]
    insertion = positions[usb0['brace']].end()
    prefix = args.output/'negative-seventh-target'
    prefix.with_suffix('.dsl').write_text(text[:insertion]+'\n'+DSD+'\n'+text[insertion:])
    run([args.iasl, '-p', str(prefix), '-tc', str(prefix.with_suffix('.dsl'))], prefix.with_suffix('.compile.log'))
    try:
        properties(checker.disassemble(prefix.with_suffix('.aml')), TARGETS)
    except AssertionError as exc:
        assert 'unapproved target' in str(exc)
        seventh = str(exc)
    else:
        raise AssertionError('negative seventh target was accepted')
    # A DSDT mistakenly copied/listed in an SSDT-only payload must be rejected.
    ssdt_paths, _ = manifest(modified, modified/'o6/1.2/initramfs.list')
    try:
        checker.payload(ssdt_paths+[modified/'o6/1.2/initramfs-dsdt/kernel/firmware/acpi/DSDT.aml'], set())
    except AssertionError as exc:
        assert 'unapproved target' in str(exc)
        leak = str(exc)
    else:
        raise AssertionError('negative SSDT-only payload leak was accepted')
    # Aliases must retain the exact corresponding canonical table bytes.
    for alias, canonical_profile in [('', 'o6/1.2'), ('o6', 'o6/1.2'), ('o6n', 'o6n/1.2')]:
        for mode in ('initramfs', 'initramfs-dsdt'):
            a = modified/alias/mode/'kernel/firmware/acpi'
            b = modified/canonical_profile/mode/'kernel/firmware/acpi'
            assert {p.name:p.read_bytes() for p in a.glob('*.aml')} == {p.name:p.read_bytes() for p in b.glob('*.aml')}, 'alias selection changed'
    receipt = {'profiles': results, 'approved_static_instances': 18, 'roundtrips': 3, 'namespace_checks': namespace_checks, 'negative_seventh_target_rejected': seventh, 'negative_ssdt_only_payload_rejected': leak, 'aliases': 'PASS', 'scope': 'offline compiled AML; not firmware execution or hardware qualification'}
    (args.output/'receipt.json').write_text(json.dumps(receipt, indent=2)+'\n')
    print('PASS: 18 approved instances, 13 payloads, 3 round-trips, both compiled-AML negative controls and aliases')


if __name__ == '__main__':
    main()
