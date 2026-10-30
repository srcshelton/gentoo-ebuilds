# ACPI xHCI Cadence stream-context opt-in — Phase 2J

Disposition: **IMPLEMENTED BUT TARGETING BLOCKED**. No controller is enabled.
No ACPI source/profile, kconfig policy, PHY, reset, PM, Cadence core or ring
implementation is changed. Native ARM64 compilation and hardware tests:
**NOT RUN**. No deployment, commit, push, PR or CI dispatch occurred.

## Source and hardware identities

Base overlay: `105d5fd107ee3027a78d88e429409dea9fb08048`. Work is isolated on
`codex/cix-usb-phase2j`; it does not change the master checkout or 7.3 work.
Kernel inputs remain Linux 6.18 + genpatches 65/66 for 6.18.57/58 and Linux 7.2
+ genpatches 13 for 7.2.12; CIX pin remains
`bc078a383042a6c14b05c56e12390e422f893088`. Existing 60010/60020/60030/60040
patches remain byte-identical (60030 exists only on 7.2).

Phase 2I evidence is retained at repository-root
`.agent-work/01a1836d-25d8-7f50-a27c-98ccbb1d7412-usb-phase2i/`, including the
2026-10-29 live capture and loaded AML. The board is Orion O6 revision 1.0,
DMI UEFI 1.2.4 dated 2026-06-29, with an initramfs-overridden DSDT/SSDT set.
Running kernel: `7.2.12-cix #36`, built 2026-10-21; GNU build ID
`840ea2e5d6302fd4ef3bd2c09ba44ab709b95345`. Cadence support is disabled;
ten physical `PNP0D10` hosts bind generic `xhci-hcd`, and vendor CIXH2030/2031
nodes report status zero. No new live access or hardware operation was needed
in Phase 2J. This evidence identifies topology, not a demonstrated stream fault.

## Applicability gate

The following rows come from the effective retained replacement DSDTs, with
full namespace paths, `_UID`, inclusive MMIO ranges and GIC interrupt numbers.
The live O6 1.2.4 namespace/resource rows match its retained replacement profile.
Linux-assigned IRQ numbers are different from the firmware GIC identifiers.
Exact resource overlap matches each generic node to a disabled CIXH2031 child;
it does not independently identify the hardware IP revision.

All rows remain **insufficient identification evidence**, with no opt-in.
No instance is claimed confirmed affected or confirmed unaffected silicon.
The live xHCI logs report HCI 1.10 on all ten instances. UIDs 0–5 report
HCCPARAMS1 `0x08007f0d` (MaxPSASize 7); UIDs 6–9 report `0x08000f8d`
(MaxPSASize 0), with USB2-only root hubs. Capability differences do not identify
a Cadence integration or establish its erratum revision. The four latter
controllers do not expose primary stream-array capability in this capture.

| Board / firmware family | Namespace | UID | MMIO inclusive | GIC IRQ | Disabled vendor child | Existing _DSD |
|---|---|---|---|---|---|---|
| o6/1.2 | `\_SB_.XHC0` | 0 | 0x9018000–0x901ffff | 0x126 | `\_SB_.SUB0.CUB0` | no |
| o6/1.2 | `\_SB_.XHC1` | 1 | 0x9088000–0x908ffff | 0x12c | `\_SB_.SUB1.CUB1` | no |
| o6/1.2 | `\_SB_.XHC2` | 2 | 0x90f8000–0x90fffff | 0x132 | `\_SB_.SUB2.CUB2` | no |
| o6/1.2 | `\_SB_.XHC3` | 3 | 0x9168000–0x916ffff | 0x138 | `\_SB_.SUB3.CUB3` | no |
| o6/1.2 | `\_SB_.XHC4` | 4 | 0x91d8000–0x91dffff | 0x11c | `\_SB_.SUB4.CUB4` | no |
| o6/1.2 | `\_SB_.XHC5` | 5 | 0x91e8000–0x91effff | 0x121 | `\_SB_.SUB5.CUB5` | no |
| o6/1.2 | `\_SB_.USB0` | 6 | 0x9268000–0x926ffff | 0x110 | `\_SB_.HUB0.CUB0` | no |
| o6/1.2 | `\_SB_.USB1` | 7 | 0x9298000–0x929ffff | 0x113 | `\_SB_.HUB1.CUB1` | no |
| o6/1.2 | `\_SB_.USB2` | 8 | 0x92c8000–0x92cffff | 0x116 | `\_SB_.HUB2.CUB2` | no |
| o6/1.2 | `\_SB_.USB3` | 9 | 0x92f8000–0x92fffff | 0x119 | `\_SB_.HUB3.CUB3` | no |
| o6/1.3 | `\_SB_.XHC0` | 0 | 0x9018000–0x901ffff | 0x126 | `\_SB_.SUB0.CUB0` | no |
| o6/1.3 | `\_SB_.XHC1` | 1 | 0x9088000–0x908ffff | 0x12c | `\_SB_.SUB1.CUB1` | no |
| o6/1.3 | `\_SB_.XHC2` | 2 | 0x90f8000–0x90fffff | 0x132 | `\_SB_.SUB2.CUB2` | no |
| o6/1.3 | `\_SB_.XHC3` | 3 | 0x9168000–0x916ffff | 0x138 | `\_SB_.SUB3.CUB3` | no |
| o6/1.3 | `\_SB_.XHC4` | 4 | 0x91d8000–0x91dffff | 0x11c | `\_SB_.SUB4.CUB4` | no |
| o6/1.3 | `\_SB_.XHC5` | 5 | 0x91e8000–0x91effff | 0x121 | `\_SB_.SUB5.CUB5` | no |
| o6/1.3 | `\_SB_.USB0` | 6 | 0x9268000–0x926ffff | 0x110 | `\_SB_.HUB0.CUB0` | no |
| o6/1.3 | `\_SB_.USB1` | 7 | 0x9298000–0x929ffff | 0x113 | `\_SB_.HUB1.CUB1` | no |
| o6/1.3 | `\_SB_.USB2` | 8 | 0x92c8000–0x92cffff | 0x116 | `\_SB_.HUB2.CUB2` | no |
| o6/1.3 | `\_SB_.USB3` | 9 | 0x92f8000–0x92fffff | 0x119 | `\_SB_.HUB3.CUB3` | no |
| o6n/1.2 | `\_SB_.XHC0` | 0 | 0x9018000–0x901ffff | 0x126 | `\_SB_.SUB0.CUB0` | no |
| o6n/1.2 | `\_SB_.XHC1` | 1 | 0x9088000–0x908ffff | 0x12c | `\_SB_.SUB1.CUB1` | no |
| o6n/1.2 | `\_SB_.XHC2` | 2 | 0x90f8000–0x90fffff | 0x132 | `\_SB_.SUB2.CUB2` | no |
| o6n/1.2 | `\_SB_.XHC3` | 3 | 0x9168000–0x916ffff | 0x138 | `\_SB_.SUB3.CUB3` | no |
| o6n/1.2 | `\_SB_.XHC4` | 4 | 0x91d8000–0x91dffff | 0x11c | `\_SB_.SUB4.CUB4` | no |
| o6n/1.2 | `\_SB_.XHC5` | 5 | 0x91e8000–0x91effff | 0x121 | `\_SB_.SUB5.CUB5` | no |
| o6n/1.2 | `\_SB_.USB0` | 6 | 0x9268000–0x926ffff | 0x110 | `\_SB_.HUB0.CUB0` | no |
| o6n/1.2 | `\_SB_.USB1` | 7 | 0x9298000–0x929ffff | 0x113 | `\_SB_.HUB1.CUB1` | no |
| o6n/1.2 | `\_SB_.USB2` | 8 | 0x92c8000–0x92cffff | 0x116 | `\_SB_.HUB2.CUB2` | no |
| o6n/1.2 | `\_SB_.USB3` | 9 | 0x92f8000–0x92fffff | 0x119 | `\_SB_.HUB3.CUB3` | no |

O6N 1.3.1 has an SSDT-only upgrade and no retained replacement DSDT/live
namespace sufficient for this mapping. Its namespace, UID mapping, existing
`_DSD` and instance revision are **unverified**; none is guessed from O6 or O6N
1.2.4. Its profile remains unchanged.

CIX's vendor USBSSP glue describes the CIXH2031 child family, and the upstream
Cadence host path selects `XHCI_CDNS_SCTX_QUIRK` for CDNSP V2. However, the 7.2
ACPI probe assigns V2 without reading an IP identifier. This software policy,
the shared register ranges and the standard HCI version are not an authoritative
instance-level silicon/erratum mapping. CIX's posted Sky1 USBSSP binding/glue
series ([CIX binding submission](https://lists.openwall.net/linux-kernel/2026/09/03/172)) describes USB4/USB5 support but does not provide the retained per-board
ACPI revision/erratum evidence required to enable these profiles. This report
therefore does not infer an affected allowlist from those descriptions.

Missing evidence: an authoritative instance-specific CIX/Cadence integration,
revision and erratum-applicability mapping tied to the exact controller resources
and supported board/firmware layout, or a trustworthy already-available IP-ID
diagnostic. No undocumented MMIO experiment is proposed to obtain it.

## Kernel property contract

`cdns,stream-context-quirk` is a downstream ACPI-only extension using the standard
Device Properties UUID, following the [Linux _DSD rules](https://www.kernel.org/doc/html/next/firmware-guide/acpi/DSD-properties-rules.html) and [UEFI implementation guide](https://github.com/UEFI/DSD-Guide/blob/main/dsd-guide.adoc). Existing Cadence bindings use the `cdns,` prefix; generic
xHCI already reads firmware properties for quirks. No existing property with
this spelling was found in the inspected effective bindings/sources. This is
not represented as an upstream accepted DT property.

The property must provide one numeric u32 value equal to `1` (canonical ASL
`One`). A one-element numeric array accepted by the firmware-property API is
also one value. Zero, other integers, overflow, strings, empty/multiple values
and API errors are no-ops. The numeric contract deliberately differs from a
presence-only boolean: ACPI's `.property_read_bool` maps to property presence,
which would also accept an integer zero. Malformed `_DSD` rejected by ACPI
cannot enable the workaround. Firmware-property validation is provided by the
existing ACPI property core; no new AML parser is introduced.

`xhci_plat_acpi_quirks()` first requires the actual platform device's own ACPI
companion and exact HID PNP0D10 (not a CID match), then uses typed firmware
property APIs on that device. It never walks parents. Its single OR operation
preserves existing quirk bits. The probe calls it immediately after obtaining
`struct xhci_hcd`, before any `usb_add_hcd()`/core setup; later private-platform
quirks are still ORed by the existing callback. No boot option, DMI/architecture
quirk or hard-coded controller UID/address list is added. PCI's separate probe
and DT/no-ACPI platform devices do not enter the opt-in path. Existing unrelated
platform properties, private data and PM paths are untouched.

All three effective xhci-plat.c preimages and independent generated diffs are
byte-identical, so one shared overlay follow-up is used:
`files/60050-usb-xhci-plat-add-acpi-cadence-stream-context-opt-in.patch`. All three
ebuilds select it immediately after their existing 60040 fixes. Separate family
copies would duplicate identical maintenance. Full-stack qualification used
these exact bytes; relocation to the shared source path was independently
checked against all preimages, with byte-equivalent stack receipts retained.
The patches were generated from edited real source using `git diff`; no patch
hunk was hand-edited.

## ACPI integration decision

**No enabling ASL/AML or profile entry is supplied.** All existing ASL tables,
profile-selection code, initramfs lists, compilation and packaging inputs remain
unchanged. No target selector is shipped, so a selector mismatch cannot add a
property to a neighbour. The three retained DSDTs have no `_DSD` on their generic
host nodes; this would permit a supplemental `Name (_DSD, ...)` in an existing
device scope only after identity is established and each stock/full/SSDT-only
profile's namespace is checked. That condition is not met here, especially for
O6N 1.3. Never add duplicate `_DSD`, replace a whole DSDT for convenience or
bypass the existing upgrade loader.

Production AML compilation, namespace/round-trip and new-table selection tests
are **NOT APPLICABLE: no ACPI table changed or was added**. This is not a claim
of successful new-AML qualification. Existing profile bytes and source metadata
are compared against the base commit. No real-controller property fixture is
packaged or deployed. The opt-in kernel reader can be reviewed independently
while hardware targeting remains blocked.

## Regression and qualification

The executable `.github/scripts/cix-sources/test-xhci-acpi-stream-quirk.py`
extracts and compiles the actual new selector, existing platform quirk callback
and complete existing `xhci_handle_cmd_set_deq()` function from supplied final
source. It does not rewrite the selection algorithm. Firmware API returns,
ACPI metadata and unrelated xHCI lifecycle/list operations are mocked. Tests
run as portable host C on macOS ARM64; they are not Linux filesystem-sensitive
tests, kernel/ARM64 compilation or runtime USB qualification.

Per release, 15 selector cases run with ACPI enabled and again with it disabled.
They cover exact-HID opt-in, absent/zero/invalid/multiple/overflow/error values,
PNP0D15 and CID-only matches, no own ACPI node, parent-only properties, child
isolation, independent controllers and preservation of existing quirk/private
bits. Positive identities are synthetic firmware-contract fixtures, not a
claim that a physical controller was verified. PCI behavior is additionally
protected by unchanged PCI source and the unchanged separate PCI entry point.

Sixty cases per release exercise the complete existing Set TR Dequeue completion
function across stream/nonstream, quirk/no-quirk, success/four error statuses and
missing endpoint/ring combinations. Reserved stream fields clear only for
successful stream completion with the existing quirk. No xhci-ring.c or xhci.h
change is needed. No new stream behavior is applied to other commands.

Exact preimages, generated diffs and zero-fuzz/zero-offset dry-run plus actual
application pass on all three releases. Full final stack reconstruction and postimage comparison passed: **226 patches
for 6.18.57, 227 for 6.18.58 and 182 for 7.2.12**. Every later overlay applied;
all selected final files equal the independently reconstructed expected
postimages. Exact stacks, logs and actual-final-source test receipts are retained
in the task state. No hunk fuzz/offset or application failure was reported. Native ARM64 object
compilation, full linkage/modpost, AML deployment and hardware stream testing
are **NOT RUN**. No full kernel build runs on the O6.

## CI and publication boundary

No CI workflow is changed or dispatched. The base branch contains the native
ARM64 `cix-kernel-debs.yml` package workflow; it discovers its kernel matrix and
dispatch accepts only `publish_release` (default false), not a version filter.
The previously successful focused USB workflow/helper exist on USB branch
commit `223d9b5a3c5c4e51043f4224230ab8fea0e64e25`, not on this base branch.
Their historical run is not compilation evidence for 60050. The focused helper
compiles xhci-plat.o but does not run the new host regression automatically.
Do not dispatch that old ref expecting it to contain this implementation.

After explicit publication approval and review of the exact changed-file list:

```sh
git diff --check
git diff --stat
git add .github/scripts/cix-sources/test-xhci-acpi-stream-quirk.py
git add sys-kernel/cix-sources/Manifest \
  sys-kernel/cix-sources/cix-sources-{6.18.57,6.18.58,7.2.12}.ebuild \
  sys-kernel/cix-sources/files/ACPI_TABLE_UPGRADE.md \
  sys-kernel/cix-sources/files/USB_ACPI_STREAM_QUIRK.md \
  sys-kernel/cix-sources/files/60050-usb-xhci-plat-add-acpi-cadence-stream-context-opt-in.patch
git diff --cached --check
git diff --cached
git commit -m 'usb: add dormant ACPI Cadence stream-context opt-in [skip ci]'
git push -u origin codex/cix-usb-phase2j
# Only after separate CI approval; existing package workflow runs its full matrix:
gh workflow run cix-kernel-debs.yml --ref codex/cix-usb-phase2j -f publish_release=false
```

The focused alternative first requires separately approved integration of the
existing USB workflow/helper from the tested tooling commits. Those commits
must be reviewed because the source branch includes more than tooling. Do not
blindly cherry-pick the source branch or register a duplicate workflow. Once
that tooling is on the reviewed ref, its existing native ARM64 helper can run
6.18.57, 6.18.58 and 7.2.12 sequentially in a separate admitted Linux build
environment. Before substantial Linux qualification, use local Linux storage
for checkout, Git and all outputs, verify unprivileged chmod/access/Git
prerequisites and disk headroom, and record admission. A macOS Docker bind mount
is not an admitted substitute. No build infrastructure is created here.

`USB-ROLE-FALLBACK` and `USB-MARKER-TWO-READ` remain separate **UNRESOLVED**
items. This change neither resolves the no_drd power-loss contract nor establishes
a stream-corruption fault on the live O6.
