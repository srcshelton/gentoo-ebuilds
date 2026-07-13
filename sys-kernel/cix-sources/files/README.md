# CIX kernel patch queue

This directory contains the downstream patch queue and support files used by
`sys-kernel/cix-sources`.  The ebuild is the authority for patch order.  This
document records the layout and numbering contract needed to keep that order
comprehensible.

Only Linux 6.18 and newer is in the maintained scope described here.  The
6.1.x and 6.6.x material is legacy and must not be used to infer current queue
policy.

## Maintained bases

The latest maintained ebuild in each series is:

| Series | Ebuild | CIX base | Sky1 base |
| --- | --- | --- | --- |
| 6.18 | `cix-sources-6.18.38` | `19f2947` | `57e018a` |
| 7.0 | `cix-sources-7.0.14-r1` | `19f2947` | `57e018a` |
| 7.1 | `cix-sources-7.1.3` | `19f2947` | `57e018a` |

Linux 7.1 reuses a 7.0 patch when the source preimage and required change are
the same.  A `7.1.x` variant exists when the source context or behaviour is
different.

## Directory layout

Current downstream patches live in `6.18.x`, `7.0.x`, `7.1.x`, or the shared
top level.  Patches needed only by superseded CIX bases are contained below:

```text
cix-3aad824/
    6.18.x/
    7.0.x/
    shared/
cix-759efc0/
    7.0.x/
    7.1.x/
    shared/
```

The outer directory records the CIX checkpoint.  The inner directory records
the kernel family, while `shared` is for a checkpoint-specific patch used by
more than one family.  Current `19f2947` ebuilds do not reference either
checkpoint directory.

When the last ebuild based on a checkpoint is removed, its directory can be
removed as a unit after confirming that no ebuild references it.  Do not put a
checkpoint hash in the filename of a current patch merely to record its
ancestry; the commit message and documentation carry that provenance.

## Numbering policy

The numbering model predates the `19f2947` uplift.  Repository history shows
that `90xxx` was already the durable CIX platform range.  The `99xxx`
retention overlays first appeared during the `19f2947` migration and were a
temporary staging device, not the definition of the whole `9xxxx` range.

| Range | Ownership |
| --- | --- |
| `0000`-`0999` | Direct replacements for a patch with the same vendor or upstream queue ordinal |
| `10000`-`19999` | Architecture, boot, and core build diagnostics |
| `20000`-`29999` | Core CPUFreq/topology, build, Kconfig, compiler, and section-lifetime corrections |
| `30000`-`39999` | ACPI, firmware, SCMI, clocks, reset, PM domains, and power policy |
| `40000`-`49999` | Enumeration, resource policy, pinctrl, and model arbitration |
| `50000`-`59999` | Runtime driver corrections not owned by a narrower range |
| `60000`-`69999` | USB, Type-C, and CIX PHY integration |
| `70000`-`70999` | DRM and display |
| `71000`-`71899` | CIX MVX video codec |
| `71900`-`71999` | ArmChina NPU |
| `72000`-`72999` | CIX ISP and camera |
| `73000`-`73999` | HDA and ASoC audio |
| `80000`-`89999` | Networking, PCI, and cross-module ordering |
| `90000`-`98999` | CIX SoC, platform, board profiles, and platform HWMON |
| `99000`-`99999` | Temporary, exceptional, or explicitly experimental overlays |

There are currently no active `99xxx` patches.  The former EC fan-diagnostic
experiment was removed after firmware testing proved only target-RPM readback,
not an actual tachometer reading or a supported mode-query interface.

Equivalent changes should use the same number across kernel families where
possible.  Direct follow-ons should be sequential.  Unrelated changes in the
same range should be spaced apart so that a future prerequisite or follow-on
can be inserted without renumbering the whole group.

### Vendor ordinals

A low ordinal such as `0047` is valid only when the local file directly
replaces vendor or upstream patch `0047` in that queue.  The 6.18 replacements
`0051`, `0071`, and `0118`, and the 7.1 CIX-queue replacement `0046`, follow
this rule.

The former local PL011 follow-on named `0047` did not replace CIX patch `0047`:
CIX already supplies its own, unrelated `0047`.  The follow-on is therefore
numbered `20071`.  If a future local patch really substitutes for the vendor
`0047`, retaining `0047` would be correct.

## Patch boundaries

Prefer one subsystem or one clearly named functional owner per patch.  A
thematic group is acceptable when its files jointly implement one behaviour,
or when splitting it would create many tiny patches without improving
maintenance.  Examples include the CIX ACPI model-discovery helpers and the
module soft-dependency declarations.

Do not use a final catch-all patch for unrelated migration leftovers.  The
former `990xx` retention overlays are now assigned to their owning ranges:

| Concern | Current location |
| --- | --- |
| CIX display retention | `70130` |
| Peripheral ACPI retention | `50100`, `50110`, `50120`, and `50130` |
| Regulator retention | `50095` |
| HDA and I2S retention | `73020` and `73030` |
| 7.1 compiler findings | subsystem-owned `20072`, `30022`, `40054`, `50022`, `60097`, `70140`, `72107`, `73040`, `80062`, and `90094` |

## CIX thermal configuration

All maintained kernels use `CIX_THERMAL` for the CIX CPU IPA implementation.
It requires built-in `THERMAL_GOV_POWER_ALLOCATOR` and
`ACPI_CPPC_CPUFREQ`, in addition to the thermal, CPU-frequency, and Energy
Model cores.  The ACPI board profiles and `kconfig_update.py` select those
dependencies explicitly; the DT profile does not select this ACPI-dependent
driver.  Building `power_allocator` does not make it the global default;
patch `30128` selects it only for CIX ACPI zones with a valid `SWIT` range.

The CIX `SSTP` ACPI method is an optional sustainable-power hint.  Thermal
zones without it must still register; a zero value lets the power-allocator
governor estimate sustainable power from attached power actors.  Patch
`30128` enforces that behaviour for every maintained family.

CIX originally published `SWIT` as an additional passive trip.  With the
normal `step_wise` default, the O6 CPU zones therefore started throttling at
60 degrees C instead of treating 60 degrees C as the IPA activation point for
an 85 degrees C control trip.  Patch `30128` retains one firmware `_PSV`
passive trip, records `SWIT` in its `switch_on_temp`, and assigns that zone to
`power_allocator`.  Other ACPI zones keep their configured default governor.

CIX also exposed one processor cooling state per CPPC OPP while retaining the
generic ACPI interpretation of each state as another 20 percent frequency
reduction.  O6 policies exposing seven or eight states could consequently
request a zero limit and then underflow the percentage calculation.  Patch
`30128` maps each CIX state to its corresponding CPPC OPP frequency.  If CIX
OPP discovery is unavailable, the standard bounded percentage model remains
the fallback.

CIX patch `0042` names each ACPI thermal zone after its firmware bus ID.
Patch `30128` retains those unique types for thermal-core lookup, sysfs,
netlink, and tracing, but supplies an independent `acpitz` hwmon type so the
readings share one adapter.  The retained ACPI `_STR` labels identify every
input individually.

Patch `30128` also makes absent optional `SPRG` and `DPRG` power methods
return zero instead of an uninitialised value, and rejects the out-of-range
Sky1 affinity index 12.  Patch `20045` keeps CPPC frequency scaling available
if CIX `PEFG` OPP discovery fails, while explicitly reporting the unavailable
CPU Energy Model and any later registration failure.

`CIX_SCMI_ENERGY_MODEL` is a separate library helper for a device driver that
calls `cix_scmi_register_em()`.  Its generic firmware-node parsing can consume
DT properties or equivalent ACPI `_DSD` data, but the current CIX display/GPU
stack has no caller.  It is therefore not selected automatically by
`CIX_THERMAL`; enabling it alone has no runtime effect.  Normal
`kconfig_update.py` fragment and update profiles explicitly disable it so
an `M` or `Y` inherited from the former forced selection is removed.

## CIX display configuration

The CIX eDP panel described by ACPI depends on the Sky1 PWM provider and the
generic PWM backlight driver.  The board profiles and `kconfig_update.py`
therefore select `PWM`, `PWM_SKY1`, `BACKLIGHT_CLASS_DEVICE`, and
`BACKLIGHT_PWM` with the CIX DRM display stack.  Without `BACKLIGHT_PWM`, the
`CIXH5041` backlight never registers, the `CIXH5040` panel probe remains
deferred, and the associated `CIXH5010:02` Linlon DPU cannot bind.

CIX `19f2947` added the `CIXH5041` ACPI match and converted the backlight
parser to generic firmware-property calls, but left that parser inside a
`CONFIG_OF` conditional.  An ACPI-only kernel consequently compiled a stub
which rejected the valid `_DSD` data with `-ENODEV`.  Patch `70150` builds the
firmware-property parser independently of Device Tree support while retaining
the OF match table's original guard.

An ACPI-derived DP encoder mask of `possible_crtcs=0x3` is expected: each
published DP endpoint is connected to both Linlon pipelines.  Patch `70130`
reports whether this mask came from the ACPI graph, DT, or the real fallback.
Thus the normal ACPI path is logged as `from ACPI`, rather than being
misleadingly described as a fallback.

The old display/backlight aggregate was also separated.  Its backlight half
was removed rather than retained because CIX `19f2947` already supplies the
`CIXH5041` ACPI match table.  Reapplying it produced a duplicate definition;
patch `70150` instead fixes the remaining source gating defect without
duplicating the vendor match table.

When changing a patch, reconstruct its exact source preimage, apply preceding
patches in ebuild order, edit the real source, regenerate the diff, and replay
it with zero fuzz.  Never repair a patch hunk by hand.  If a later patch is
made redundant, remove it from the queue rather than stacking a corrective
patch over it.

`create-patched-kernel.sh` passes `--fuzz=0` for files below this package's
`FILESDIR`.  A successful helper run is therefore also a zero-fuzz assertion
for our patches, without imposing that policy on Gentoo genpatches or imported
vendor archives which the ebuild may also pass through `eapply`.

## Prepared source helper

The helper materialises the exact ebuild-driven source tree:

```sh
sys-kernel/cix-sources/files/create-patched-kernel.sh \
  sys-kernel/cix-sources/cix-sources-7.1.3.ebuild \
  ./linux-7.1.3-cix
```

It fetches and verifies the kernel, Gentoo genpatches, and CIX/Sky1 archives,
then executes the selected ebuild's `src_prepare`.  Useful options include
`--force`, `--distdir`, and `--use`.

ACPI table-upgrade payloads require Python and ACPICA `iasl` version 20241212
or newer.  An explicit request is strict:

```sh
sys-kernel/cix-sources/files/create-patched-kernel.sh \
  --compile-acpi-tables \
  --acpi-table-profile dsdt \
  --board-profile o6-acpi \
  sys-kernel/cix-sources/cix-sources-7.1.3.ebuild \
  ./linux-7.1.3-cix
```

Missing tools, an old `iasl`, or an AML compile failure are errors when
`--compile-acpi-tables` was requested.

On hosts where `patch(1)` does not implement extended Git renames like GNU
`patch(1)`, the helper applies local rename-bearing Git diffs with `git apply`.
This keeps its prepared pathname layout consistent with Portage.

Linux 7.1.3 imports the ArmChina NPU source directly from
`cixtech/cix_opensource__npu_driver` commit `047b23e`, instead of using the
legacy Sky1 NPU patch as the source preimage.  It defaults that driver to the
R2P0 userspace ABI used by `cix-noe-umd` 2.0.2.  The imported R2P2
implementation remains opt-in through `npu-r2p2-abi`.  The R2P0 overlay
preserves all 32 ASID entries in `struct aipu_cap`, keeping
`AIPU_IOCTL_QUERY_CAP` at the `0x1a8` argument size encoded by that userspace
runtime, and carries both prepare-time and build-time
size assertions.

The R2P2 import renames the v3.2 register definitions from `v3_1.h` to
`v3_2.h`.  The R2P0 `71993` patch applies its debug-dispatch conversion
directly to that renamed header, matching the pathname produced by Portage.
`kconfig_update.py` also rejects trees whose ISA markers and ASID ABI width do
not agree.

## Upstream tracking

[CIX PR #37][cix-pr-37] is carried by
`7.0.x/60015-usb-cdnsp-sky1-tear-down-host-on-shutdown.patch` for both 7.0 and
7.1.  It reuses the normal remove path during shutdown so xHCI children are
torn down before Sky1 clocks and resets are disabled.

[CIX PR #44][cix-pr-44] does not currently replace our PPTT.  Its proposed
topology adds a
shared 2 MiB efficiency-core L2 and explicit IDs for every cache.  The Sky1
device-tree source used by this package instead links its four efficiency
cores directly to the 12 MiB system cache, and it does not prove the proposed
2 MiB cache.  The payload therefore remains unchanged pending board-independent
architectural evidence.  See `ACPI_TABLE_UPGRADE.md` for the exact comparison.

## Validation

For maintained releases, a queue change is complete only after:

1. all ebuild-referenced patch files exist;
2. each latest ebuild completes the helper-driven prepare;
3. no local patch reports fuzz;
4. affected objects compile for arm64 in a representative configuration;
5. `Manifest` is regenerated; and
6. `git diff --check` and documentation wrapping checks pass.

Gentoo genpatches and the imported Sky1 queue may have their own fuzzy hunks.
Those should be reported separately and must not be mistaken for local patch
fuzz.

See `AUDIT.md` for the latest validation set point and
`ACPI_TABLE_UPGRADE.md` for the firmware payload matrix and deployment rules.

[cix-pr-37]: https://github.com/cixtech/cix-linux-main/pull/37
[cix-pr-44]: https://github.com/cixtech/cix-linux-main/pull/44
