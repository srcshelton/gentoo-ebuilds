# Maintained CIX kernel audit

Audit date: 2026-07-12.

This is the stable source-preparation set point for Linux 6.18 and newer.  It
does not cover the legacy 6.1.x or 6.6.x ebuilds.

## Bases tested

| Series | Ebuild | CIX base | Result |
| --- | --- | --- | --- |
| 6.18 | `cix-sources-6.18.38` | `19f2947` | Prepared successfully |
| 7.0 | `cix-sources-7.0.14-r1` | `19f2947` | Prepared successfully |
| 7.1 | `cix-sources-7.1.3` | `19f2947` | Prepared successfully |

All three preparations used the package helper so the ebuild, rather than a
reconstructed filename list, controlled patch order.

## Migration corrections

The `759efc0` to `19f2947` review found and corrected these local migration
problems:

- The 6.18 and 7.0 Cadence GPIO ports instantiated the removed
  `cdns_gpio_soc_data` type.  All maintained families now use the same
  explicit quirk model, preserve firmware-owned Sky1 ACPI GPIO state, and
  retain the AX3000 device-tree match.
- The old display/backlight patch added a second `CIXH5041` ACPI match table
  even though `19f2947` already provides it.  The redundant backlight change
  was removed; the still-needed CIX virtual-encoder gate remains as `70020`.
- The 7.0 SMMU, display, and GPIO patches were regenerated against their real
  `19f2947` preimages.  The 6.18 direct replacement for Sky1 `0118` was also
  regenerated against its post-CIX preimage.
- The temporary `990xx` retention overlays were split by subsystem and moved
  into their permanent ranges.  The final EC fan-diagnostic experiment was
  removed after it failed to expose a supported actual-RPM or mode interface;
  there are now no active `99xxx` patches.
- The compiler-warning aggregate was split among DRM, HWMON, irqchip, ISP,
  Realtek networking, PHY, pinctrl, PM-domain, PL011, and ASoC owners.
- The CIX CPU IPA driver no longer rejects ACPI thermal zones which omit the
  optional `SSTP` sustainable-power hint.  Its Kconfig no longer forces the
  unused SCMI Energy Model helper, and the board/configuration profiles now
  select every direct dependency of `CIX_THERMAL` explicitly.
- ACPI thermal zones retain both their firmware bus-ID thermal types and their
  individual `_STR` labels.  A separate `acpitz` hwmon type restores the
  single-adapter grouping without losing thermal-core identity.
- Missing optional `SPRG`, `DPRG`, and `PEFG` firmware data is handled
  deterministically.  CPPC frequency scaling remains available when CIX OPP
  discovery fails, while the missing CPU Energy Model is reported explicitly.
- Normal configuration-profile updates explicitly clear the unused
  `CIX_SCMI_ENERGY_MODEL` helper, including stale `M` or `Y` values
  inherited from the former `CIX_THERMAL` selection.
- The display profiles now include the Sky1 PWM and PWM-backlight providers.
  This closes the deterministic `CIXH5010:02` probe-defer path caused when the
  ACPI eDP panel's `CIXH5041` backlight provider was not built.
- The DP encoder diagnostic now distinguishes ACPI-graph and DT masks from a
  genuine fallback instead of labelling every non-DT mask as a fallback.
- The 7.1 NPU R2P0-ABI patch was regenerated after `19f2947` removed its
  former `v3_2.h` target.  The remaining changes apply to the current source
  files, followed by the existing R2P0 compatibility fix.
- Historical-only patches now live below `cix-3aad824` or `cix-759efc0`, with
  a kernel-family or `shared` directory inside the checkpoint.

Clean-room replay of each regenerated split reproduced the intended source
files exactly.  The Cadence GPIO, PWM backlight, ACPI thermal, ACPI processor
power, CPPC CPUFreq, CIX CPU IPA, and CIX DisplayPort objects compile with
Clang 19 for arm64 on all three prepared trees.  Kernel `olddefconfig` also
retained built-in `CIX_THERMAL`, its power-allocator and CPPC dependencies,
left the unused CIX SCMI Energy Model helper disabled, and retained the PWM,
Sky1 PWM, backlight class, and PWM-backlight display path.

The revised O6 firmware-`1.2` and firmware-`1.3` `ORIONO6` sources compile
with ACPICA `20260408`: both report zero errors and zero warnings.  The four
remaining remarks identify intentionally unused arguments in the established
PWM fan methods.

## Fuzz policy and result

No local patch in the latest 7.0 or 7.1 preparation used fuzz.  The final 6.18
local fuzzy hunk was the direct Sky1 `0118` replacement and has been
regenerated from its exact preimage.

The logs still contain fuzzy hunks in Gentoo genpatches and in the imported
Sky1 queue.  Those external patches are reported separately and are not
downstream patch-file defects in this repository.

## Upstream pull requests

[CIX PR #37][cix-pr-37] is technically coherent and has a positive 7.0.14
hardware test.
It replaces shutdown-only mitigations with the normal CDNSP remove path, which
tears down child xHCI devices before clocks and resets.  We carry that change
as `60015` in both the 7.0 and 7.1 maintained builds.

[CIX PR #44][cix-pr-44] does not match our current PPTT.  Both describe the
same broad
Sky1 split and 12 MiB system cache, but PR #44 adds a shared 2 MiB L2 for the
four efficiency cores and gives every cache an explicit ID.  Our table links
those cores directly to the system cache and gives only that shared cache an
explicit ID.

The Sky1 device-tree source used by this package also links its four
efficiency cores directly to the 12 MiB cache.  It therefore does not prove
PR #44's extra shared L2.  No PPTT payload was changed in this audit.  The
Orange Pi 6 Plus SSDT changes in that pull request are board-specific and must
not be imported into Orion O6 payloads merely because both boards use Sky1.

## Remaining evidence requirements

The PPTT alternative can be reconsidered when a board-independent source,
architectural cache-register capture, or authoritative CIX topology document
proves the 2 MiB shared efficiency-core L2 and its sharing relationship.

This audit proves source preparation, zero local fuzz, regenerated-patch
replay, and focused compilation.  It is not a substitute for an Orion O6 or
O6N boot test, suspend/resume test, PCIe endpoint test, or full distribution
kernel build.

[cix-pr-37]: https://github.com/cixtech/cix-linux-main/pull/37
[cix-pr-44]: https://github.com/cixtech/cix-linux-main/pull/44
