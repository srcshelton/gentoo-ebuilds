# Verified ACPI xHCI stream-context enablement — Phase 2L

Disposition: **READY FOR CI**. Native ARM64 kernel compilation and hardware
validation: **NOT RUN**. No deployment, commit, push, PR or CI dispatch occurred.

This completes the ACPI side of Phase 2J's 60050 reader using the approved Phase
2K decision. Those reports and receipts remain historical evidence; no hardware
identity investigation or kernel-reader redesign was repeated.

## Implementation and exact scope

Alternative A was selected: add six `_DSD` objects directly to each **existing**
replacement DSDT. Ordinary `ssdt/` inputs enter both initramfs modes; a dedicated
full-profile SSDT mechanism would require unnecessary packaging changes. No new
whole-table replacement, source category, loader or ebuild logic is introduced.

| Existing replacement source under `acpi-table-upgrade/` | Firmware | Enabled devices |
|---|---|---|
| `o6/1.2/dsdt/DSDT.asl` | O6 1.2.4 | `\_SB_.XHC0`–`XHC5`, UIDs 0–5 |
| `o6/1.3/dsdt/DSDT.asl` | O6 1.3.1 | `\_SB_.XHC0`–`XHC5`, UIDs 0–5 |
| `o6n/1.2/dsdt/DSDT.asl` | O6N 1.2.4 | `\_SB_.XHC0`–`XHC5`, UIDs 0–5 |

Each device receives exactly one Device Properties UUID
`daffd814-6eba-4d8c-8a91-bc9bbf4aa301` package containing only
`cdns,stream-context-quirk = One`, a numeric integer. None previously had `_DSD`.
There are **18 canonical profile/controller combinations**. Removing precisely
these added blocks reproduces all three exact preimages byte for byte.

USB0–USB3, vendor wrappers/children, O6N 1.3.1 and all SSDT-only payloads remain
unchanged. `_HID`, `_UID`, `_STA`, `_CRS`, interrupts, PHYs and other properties
are unchanged. Generic PNP0D10 xHCI remains authoritative; no CDNS driver is
enabled. The compatibility aliases still select firmware 1.2, with top-level
aliases selecting O6 and board aliases selecting their corresponding board.

60050 remains SHA-256
`8f952e2365fd628b25477e402472faaf38a2b6c079d3a8aabd29bdbf520fe8d9`.
60010/60020/60030/60040, all three Phase 2J ebuild selections, kconfig policy,
vendor pins, workflows and unrelated integrations remain byte-identical.
The new fields are consumed by the already-qualified exact-own-HID PNP0D10,
typed-integer reader before HCD registration. No other controller opts in.

## Qualification

Source baseline: isolated `codex/cix-usb-phase2j`, overlay base
`105d5fd107ee3027a78d88e429409dea9fb08048`, with preserved Phase 2J changes.
The Phase 2K allowlist, source hashes, TRM identity and preservation receipt were
read and verified before editing. No new live O6 access occurred.

ACPICA **20260408**, the version already pinned by the existing CI fallback,
compiled all baseline and modified profiles through the actual `src_compile()`
functions in every maintained ebuild and through complete production
`create-patched-kernel.sh --compile-acpi-tables` preparations. The installed
20200925 compiler was below the ebuild minimum and was not used for qualification.
The unmodified ACPICA source built locally on macOS ARM64; linking required
`LDFLAGS=-Wl,-no_fixup_chains`. Source archive/binary hashes and commands are retained.

| Maintained release | Full stack replay | Existing actual-source host cases | AML checks via ebuild / preparation helper |
|---|---:|---:|---|
| 6.18.57 | 226 patches, exact | 90 pass | pass / pass |
| 6.18.58 | 227 patches, exact | 90 pass | pass / pass |
| 7.2.12 | 182 patches, exact | 90 pass | pass / pass |

Every ordered patch receipt equals Phase 2J, with zero hunk fuzz or offsets.
Retained final-source hashes, including `xhci-plat.c`, match Phase 2J exactly.
The 270 host cases exercise the original extracted selector and stream-command
completion functions; these are portable C tests, not a native kernel build.

The executable `.github/scripts/cix-sources/test-acpi-xhci-stream-quirk.py`
validates **compiled AML**. For each release and both production routes it checks:

- All 13 canonical/compatibility initramfs lists and every listed AML table.
- Exactly six numeric-one properties per approved full profile; exact own HID,
  UID, MMIO and host IRQ mapping; no duplicate target `_DSD` or other target.
- Unchanged SSDT-only lists byte for byte for direct ebuild outputs, and identical
  normalized selection for helper lists, whose source-root paths are rewritten.
  All SSDT-only AML and O6N 1.3 AML remain byte-identical to baseline.
- Unrelated table bytes and disassembled DSDT semantics unchanged after removing
  only the six opt-ins; three successful disassembly/recompilation round-trips.
- Namespace consistency using a fresh iasl process for each AML table, with every
  other payload AML table supplied for external resolution: 33 checks per route.
- A compiled DSDT with an added seventh USB0 property is rejected. A modified
  compiled DSDT mistakenly included in an SSDT-only payload is also rejected.

An exploratory multi-input `iasl -da` run produced duplicate external-load
diagnostics on both baseline and modified payloads. Fresh-process resolution of
the same complete payloads passes for every table. The failed attempt and the
successful checks are retained; no audio/DMA firmware defect is inferred or fixed.
Namespace checks cover the produced upgrade payload, not execution of a complete
live firmware namespace. No AML method was evaluated.

Manifest sizes/BLAKE2B/SHA512, ebuild/helper syntax and whitespace pass. Strict
60050 source checkpatch passes with `--no-tree --strict --no-signoff` (standalone
overlay patches do not supply commit sign-offs); the patch bytes are unchanged.
No native ARM64 objects, module linkage/modpost, boot or runtime USB result is
claimed. No full kernel build was run on the live O6.

## Reproduction and publication handoff

Retained evidence is in repository-root
`.agent-work/01a1836d-25d8-7f50-a27c-98ccbb1d7412-usb-phase2l/`.
It includes baseline/current compiled bundles, exact commands, stack TSVs,
selected effective sources, host/AML receipts, failed-attempt diagnostics,
changed-file hashes and resource cleanup. Phase 2J/2K evidence is untouched.

Example offline AML check using those retained bundles (output must be new):

```sh
evidence=.agent-work/01a1836d-25d8-7f50-a27c-98ccbb1d7412-usb-phase2l
python3 .github/scripts/cix-sources/test-acpi-xhci-stream-quirk.py \
  "$evidence/baseline-7.2.12/cix-acpi-table-upgrade" \
  "$evidence/helper-7.2.12" "$evidence/review-aml-check" \
  --iasl "$evidence/toolchain/iasl"
```

For a separately authorised native ARM64 builder, use local Linux storage with
the documented filesystem/resource admission, then prepare each version and run
the retained host tests before building. Do not use the live O6 as that builder.
The production preparation command shape is:

```sh
bash .github/scripts/cix-sources/create-patched-kernel.sh \
  --distdir /build/distfiles --compile-acpi-tables \
  --acpi-table-profile dsdt --board-profile o6-acpi --firmware 1.2 \
  --patch-log /build/usb-7.2.12-stack.tsv \
  sys-kernel/cix-sources/cix-sources-7.2.12.ebuild /build/linux-7.2.12
python3 .github/scripts/cix-sources/test-xhci-acpi-stream-quirk.py \
  /build/linux-7.2.12 /build/usb-7.2.12-host-tests
```

Repeat for 6.18.57/6.18.58 using distinct output names. The preparation produces
every board/firmware bundle, not just the selected initramfs list. Compare its
AML bundle with the retained corresponding baseline using the new validator.

Only after separate publication and CI authorisation, stage the exact reviewed
Phase 2J+2L file list (13 files; no unrelated work), commit with `[skip ci]`, and
publish an isolated review branch:

```sh
git diff --check
git switch -c codex/cix-usb-phase2l-review
# The evidence changed-files-combined.txt is the exact reviewed 13-file list.
while IFS= read -r file; do git add -- "$file"; done < \
  .agent-work/01a1836d-25d8-7f50-a27c-98ccbb1d7412-usb-phase2l/changed-files-combined.txt
git diff --cached --check
git diff --cached
git commit -m 'usb: enable verified Orion ACPI stream-context opt-ins [skip ci]'
git push -u origin codex/cix-usb-phase2l-review
# Separate explicit CI authorisation is required for this command:
gh workflow run cix-kernel-debs.yml --ref codex/cix-usb-phase2l-review \
  -f publish_release=false
```

The existing ARM64 package workflow runs its discovered full matrix; it has no
per-version dispatch input. It was inspected, not changed or dispatched. The old
focused USB workflow is not present on this base ref and must not be dispatched
as though it contains this implementation. The new offline validator is supplied
for explicit qualification; no existing workflow was silently changed to run it.

## Later live gate — separate approval required

After an authorised ARM64 build and deployment plan, separately approve booting
the matching artifact. Preserve the current kernel/initramfs and firmware-table
identities, console access and an independent power/recovery route first. Remote
power access alone is not test authorisation.

Initial live validation should be passive: confirm board/firmware/kernel/build
identity, loaded DSDT hash and generic xHCI bindings; capture loaded AML and verify
six numeric-one properties only on XHC0–XHC5. Inspect already-available kernel
quirk reporting and require bit `XHCI_CDNS_SCTX_QUIRK` only on those six, with all
other existing bits preserved and USB0–USB3 unchanged. If existing reporting
cannot establish the bit, plan a narrowly scoped diagnostic separately; do not
invent MMIO reads or enable intrusive tracing.

Abort on identity/property/quirk mismatch, new host errors, missing devices or
unexpected controller binding. Do not unbind, reset, suspend, change PM policy,
or run UAS/storage stress as part of this passive gate. Any functional stream
test requires a further bounded plan with disposable media and explicit approval.

`USB-ROLE-FALLBACK` and `USB-MARKER-TWO-READ` remain separate **UNRESOLVED**,
dormant Cadence-path limitations. Neither is part of this generic-xHCI change.
