# Orion O6/O6N ACPI Table Upgrade Support

Linux can optionally load replacement or supplemental ACPI tables from an
initramfs. The kernel documentation for this mechanism is:

`Documentation/admin-guide/acpi/initrd_table_override.rst`

The table sources shipped by this package target Radxa Orion O6 and O6N boards
running Radxa vendor firmware families `1.2` and `1.3`.

## Available Profiles

Firmware profile names are deliberately coarse: `1.2` covers the Radxa `1.2.x`
series, and `1.3` covers the Radxa `1.3.x` series. The unversioned board paths
remain compatibility aliases for the `1.2` profile.

There are two initramfs source-list profiles for firmware `1.2`: an SSDT-only
lower-impact profile, and a full profile that layers whole-table replacements
on top of the same SSDT payloads. Firmware `1.3` has an SSDT-only profile for
both boards, plus an O6 DSDT profile built from the stock `1.3.0` DSDT. O6N
firmware `1.3` remains SSDT-only until an O6N `1.3.x` DSDT is qualified.

- Firmware `1.2` SSDT-only profile: enable the smaller table-upgrade set
  through a board `1.2/initramfs.list`, the compatibility `initramfs.list`, or
  `--acpi-table-upgrade ssdt`. This profile contains only SSDT payloads. On O6
  it repairs the captured `_CPC`
  reference-performance values, updates the RTS5453 Type-C PD controller nodes
  to use shared IRQ resources, adds SCMI mailbox shared-memory windows, marks
  the GPU non-coherent, describes BusPerf fabric performance devices, exposes
  the DSU PMU, keeps the isolated `ECTZ` critical trip overlay, supplies the
  combined DTB/MemoryMap-backed SoC thermal monitor sensor table, describes the
  Sky1 reboot-reason register, and adds DTB-aligned audio DMA/HDA metadata
  including the HDA `_DMA` translation window. On O6N, the SSDT profile keeps
  only the overlays that are compatible with the O6N ACPI namespace and leaves
  O6-only EC, Type-C, audio, and extra thermal-zone overlays out.
- Firmware `1.3` SSDT-only profile: enable the qualified lower-impact set
  through a board `1.3/initramfs.list` or `--firmware 1.3
  --acpi-table-upgrade ssdt`. On O6 it keeps the non-CPPC SSDT overlays from
  the `1.2` profile: audio metadata, BusPerf, DSU PMU, GPU non-coherency, SCMI
  mailbox windows, RTS5453 shared IRQs, reboot reason, the EC critical trip,
  and the supplemental thermal-sensor zones. It deliberately drops `O6CPPC`
  because the stock `1.3.0` CPU SSDT already carries the same
  `ReferencePerformance` values in the expected CIX-visible CPU order: CPU0/1
  and CPU6-CPUB use `0x0c4e`, while CPU2-CPU5 use `0x04d8`. On O6N, the
  `1.3` profile keeps the board-compatible BusPerf, DSU PMU, GPU
  non-coherency, SCMI mailbox-window, and reboot-reason overlays. It leaves
  `O6NCPPC` out until an O6N `1.3.x` table dump confirms whether stock firmware
  has made the same CPPC repair there. O6N firmware `1.3` still has no DSDT,
  PPTT, or IORT replacement profile.
- Firmware `1.2` DSDT/whole-table profile: enable the full replacement profile
  through a board `1.2/initramfs-dsdt.list`, the compatibility
  `initramfs-dsdt.list`, or `--firmware 1.2 --acpi-table-upgrade dsdt`. This
  profile includes the same board-specific SSDT payloads, plus that board's
  Radxa-`1.2`-derived `DSDT.aml`. On O6, the DSDT replacement carries the
  newer OEM revision, mainline-only PCIe/USB device-model policy, DTB-aligned
  eDP backlight brightness levels, and the ACPI `RAOP` ramoops description used
  by the pstore/ramoops driver. It also replaces the O6 `ORIONO6` board SSDT so
  the three fixed USB VBUS regulators consume the `pinctrl_usb0`,
  `pinctrl_usb4`, and `pinctrl_usb5` groups actually published by `MUX1`, and
  preserves the proven PWM fan-control methods. On O6N, the DSDT source is the
  O6N-compatible base DSDT captured from an O6N `1.2.1` system so the full
  profile can share the whole-table payload structure without using the O6
  DSDT or O6 board SSDT on O6N hardware. Both boards also include the
  replacement `PPTT.aml` cache topology and, when enabled by USE flags, the
  generated `IORT.aml` SMMU table update. The shared PPTT carries an explicit
  revision-3 cache ID for the 12 MiB system cache so Linux groups all CPUs
  which see it at the same architectural cache level.
- Firmware `1.3` O6 DSDT profile: enable through
  `o6/1.3/initramfs-dsdt.list` or `--board-profile o6-acpi --firmware 1.3
  --acpi-table-upgrade dsdt`. This profile includes the O6 `1.3` SSDT payloads
  plus an O6 DSDT rebuilt from stock Radxa `1.3.0`. It suppresses the duplicate
  vendor PCIe controller model, adds the standard GPU `mali-supply` alias,
  keeps the PMMX mailbox helper ASL compatible with current ACPICA, carries the
  I2S5-I2S8/I2S9 pinctrl metadata fixes, and updates the eDP backlight
  brightness table to match the vendor DTB. It also carries a replacement
  `ORIONO6` board SSDT derived from the stock `1.3.0` table, correcting the
  same three USB VBUS pin-group consumers as the `1.2` replacement while
  retaining the proven PWM fan-control interface. It deliberately does not
  replay the remaining firmware `1.2` display graph, USB, or Type-C DSDT edits
  until those changed `1.3` device graphs are qualified, and it does not
  include PPTT or IORT replacement tables.

The firmware `1.2` O6 DSDT replacement keeps the generic Linux-visible
`PNP0A08` PCIe and `PNP0D10` USB hierarchies and marks the duplicate
vendor-specific CIX/Cadence PCIe/USB hierarchy not-present. The O6 firmware
`1.3` DSDT replacement currently suppresses only the duplicate vendor PCIe
controller model. The `DSDT.aml` payload itself does not change CPU numbering,
APIC, IORT, or the AML CPU topology; those whole-table updates are separate
payloads included only in the firmware `1.2` DSDT/whole-table profile.

## Table Payloads

The installed AML filenames below are the files placed in
`/kernel/firmware/acpi` inside the generated initramfs source lists. Rows marked
`ssdt, dsdt` are included by both the SSDT-only and DSDT/whole-table profiles.
Rows marked `dsdt only` are included only by DSDT/whole-table profiles. The
firmware `1.3` SSDT-only profile uses the same rows except that it excludes
`O6CPPC.aml` and `O6NCPPC.aml`, excludes all `dsdt only` rows, and excludes the
O6-only overlays from O6N just as the `1.2` O6N profile does. The O6 firmware
`1.3` DSDT profile additionally includes the `DSDT.aml` and `ORIONO6.aml`
whole-table rows; PPTT and IORT replacements remain firmware `1.2` only for
now.

The source tree is a board/firmware matrix without symlinks or duplicate source
bodies. `shared/shared/` applies to every profile, `shared/1.2/` applies to
every firmware-`1.2` board, `o6/shared/` and `o6n/shared/` apply to every
firmware version of one board, and `o6/1.2/`, `o6/1.3/`, and their O6N
equivalents are exact board/firmware inputs. The ebuild composes those four
scopes from least to most specific and rejects duplicate AML output names.

| Board(s) | Profile(s) | Installed AML | Table ID/source | Subsystem(s) | Effect |
| --- | --- | --- | --- | --- | --- |
| O6 | `ssdt`, `dsdt` | `O6AUD.aml` | `O6AUDMD` / `orion-o6-audio-dtb-metadata.asl` | Audio DMA, HDA, clocks | Aligns O6 audio metadata with the vendor DT layout: makes the `DMA1` reserved-memory entry a `12 MiB` window at `0xd0000000`, removes the legacy HDA `RSVL` carveout, adds the HDA `_DMA` translation window from device DMA `0x00000000`-`0x7fffffff` to CPU physical `0x90000000`-`0x10fffffff`, and points `DMA1.CLKT` at the AUDSS DMAC AXI clock. |
| O6, O6N | `ssdt`, `dsdt` | `O6BPF.aml`, `O6NBPF.aml` | `O6BPERF`, `O6NBPERF` / `*-busperf.asl` | SCMI performance domains, fabric clocks | Adds `CIXHA030` (`CI70`) and `CIXHA031` (`MMHB`) ACPI devices with SCMI DVFS performance-domain references to domains `10` and `11`, allowing the Linux `CIX_BUS_PERF` driver to bind the CI700 and NI700/MMHUB fabric performance controls. |
| O6, O6N | `ssdt`, `dsdt` | `O6CPPC.aml`, `O6NCPPC.aml` | `O6CPPC`, `O6NCPPC` / `*-cppc-reference-performance.asl` | CPU performance, CPPC | Repairs `_CPC` `ReferencePerformance` values that stock firmware `1.2` reports as `1000` for every CPU. The overlay derives replacement values from nominal performance/frequency and the `1 GHz` architectural timer, while leaving CPU topology and numbering unchanged. O6 firmware `1.3.0` already carries the same corrected values in the same CPU order, so `O6CPPC.aml` is intentionally not included in the O6 `1.3` profile. |
| O6, O6N | `ssdt`, `dsdt` | `O6DSUP.aml`, `O6NDSUP.aml` | `O6DSUP`, `O6NDSUP` / `*-dsu-pmu.asl` | PMU, CPU cluster observability | Adds the DSU PMU as an `ARMHD500` ACPI device using GSI `34` (`SPI 2`), matching the vendor DTB's shared cluster/L3 PMU description. |
| O6, O6N | `ssdt`, `dsdt` | `O6GPU.aml`, `O6NGPU.aml` | `O6GPUCCA`, `O6NGPUCA` / `*-gpu-noncoherent.asl` | GPU DMA coherency | Sets `\_SB.GPU._CCA` to `0` so Linux treats Sky1 GPU DMA as non-coherent instead of trusting the stock coherent ACPI metadata. |
| O6 | `ssdt`, `dsdt` | `O6RTS.aml` | `O6RTSIRQ` / `orion-o6-rts5453-shared-irq.asl` | USB Type-C, RTS5453, GPIO IRQs | Replaces `\_SB.I2C1.PD10._CRS` and `\_SB.I2C1.PD11._CRS` with resources that keep the original I2C addresses `0x30`/`0x31` but mark the shared `\_SB.GPI4` pin `8` interrupt as `Shared`, matching the actual O6 RTS5453 wiring. |
| O6, O6N | `ssdt`, `dsdt` | `O6SCMI.aml`, `O6NSCMI.aml` | `O6MBX`, `O6NMBX` / `*-scmi-mailbox-window.asl` | SCMI mailbox resources | Replaces `MBX6` and `MBX7` `_CRS` windows so the mailbox register ranges start at `0x06590080` and `0x065a0080`, leaving the leading `0x80` bytes for `SHM0`/`SHM1` and avoiding the stock mailbox/shared-memory resource overlap. |
| O6 | `ssdt`, `dsdt` | `O6ECTZ.aml` | `O6ECTZ` / `orion-o6-ectz-critical-trip.asl` | ACPI thermal, EC thermal zone | Adds a critical trip point to the stock `\_SB.ECTZ` EC thermal zone by supplying `_CRT = 0x0e80` (`3680 dK`, about `95 C`). This remains separate from the sensor-zone overlay so it can be excluded independently. |
| O6, O6N | `ssdt`, `dsdt` | `O6RBRR.aml`, `O6NRBRR.aml` | `O6RBRR`, `O6NRBRR` / `*-reboot-reason.asl` | Reboot reason, diagnostics | Adds a `PRP0001` device compatible with `cix,sky1-reboot-reason` over the read-only reboot-reason registers at `0x16000500` and `0x16000218`, allowing the Linux reboot-reason driver to expose both the software reboot reason and hardware reset source. |
| O6 | `ssdt`, `dsdt` | `O6TZSNS.aml` | `O6TZSNS` / `orion-o6-thermal-sensors.asl` | ACPI thermal, PMMX sensors | Adds PMMX.SENG-backed thermal zones for VPU, GPU bottom/top, SoC bridge, DDR bottom/top, CI700 interconnect, NPU, SoC trace, and two board NTC sensors. Each zone has a critical trip point, a `10` decisecond polling period, and returns `Ones` on PMMX status failure rather than exposing a false temperature. |
| O6, O6N | `dsdt only` | `DSDT.aml` | board-specific `dsdt/DSDT.asl` | ACPI namespace, PCIe, USB, pstore, display | Replaces the stock DSDT with a board/firmware-specific DSDT. The firmware `1.2` O6 payload keeps the generic Linux-visible `PNP0A08` PCIe and `PNP0D10` USB model, suppresses overlapping vendor PCIe/USB controller models, adds/tightens PCIe I/O and memory windows, carries the PCIe `_OSC` handoff policy, updates the PRC1 `bus-range` property to `0x90` to `0xaf`, exposes the `RAOP` `ramoops` device, adds the standard GPU `mali-supply` alias for the GPUP power resource, keeps PMMX mailbox helper ASL compatible with current ACPICA, fixes stale I2S5-I2S8 pinctrl consumer names to match the firmware-published IOMUX groups, removes the unresolvable I2S9 pinctrl consumer reference, and carries the display/backlight metadata cleanup. The O6N `1.2` payload uses an O6N-compatible DSDT source and carries the same GPU supply and I2S pinctrl metadata fixes, but does not import O6-only SSDT overlays. The O6 firmware `1.3` payload is rebuilt from stock Radxa `1.3.0`, keeps the `1.3` firmware's existing RAOP and PRC1 bus-range changes, suppresses duplicate vendor PCIe controller devices, adds `mali-supply`, keeps PMMX mailbox helper ASL compatible with current ACPICA, carries the I2S pinctrl metadata fixes, and updates the eDP backlight brightness table to match the vendor DTB. |
| O6 | `dsdt only` | `ORIONO6.aml` | firmware-specific `ssdt-replacement/ORIONO6.asl` | USB VBUS regulators, pinctrl, EC fan control | Replaces the stock O6 board SSDT with an otherwise equivalent OEM-revision-`2` table whose `VUS0`, `VUS4`, and `VUS5` regulators consume `pinctrl_usb0`, `pinctrl_usb4`, and `pinctrl_usb5`, matching the groups published by `MUX1`. It retains the firmware-proven PWM fan-control interface. Experimental target-RPM, tachometer, and mode-query wrappers are deliberately absent: testing proved the target query but found no supported actual-RPM or mode interface, so those methods could not diagnose fan health. The vendor board-table source is unchanged from firmware `1.2.1` through `1.2.4`, while firmware `1.3` uses a separate source derived from its changed stock table. The revision bump is required because Linux accepts an initrd table as an upgrade only when its OEM revision is newer than the firmware table. |
| O6, O6N | firmware `1.2`, `dsdt only` | `PPTT.aml` | `shared/1.2/pptt/PPTT.asl` | CPU/cache topology | Replaces PPTT with a conservative cache topology model: `32 KiB` L1I + `32 KiB` L1D for A520 cores, `64 KiB` L1I + `64 KiB` L1D plus private `512 KiB` L2 for A720 cores, and a shared `12 MiB` system cache. The shared cache carries an explicit revision-3 Cache ID so Linux 6.18, 7.0, and 7.1 group CPUs that see it at the same architectural cache level instead of treating every CPU path as a separate cache instance. It does not renumber CPUs. |
| O6, O6N | `dsdt only`, optional | `IORT.aml` | generated from `iort/IORT.dat` by `build_iort_upgrade.py` | IOMMU, SMMUv3, MSI domains | Generated only when `acpi-table-upgrade-dsdt` is enabled and at least one IORT USE flag is active. `acpi-table-upgrade-iort-httu` marks SMMUv3 nodes coherent and advertises hardware access/dirty table updates. `acpi-table-upgrade-iort-msi` adds or validates ITS mappings for the Sky1 PCIe and platform SMMUv3 nodes at `0x0b010000` and `0x0b1b0000`, marks their device-ID mapping valid, and avoids Linux falling back to wired IRQs for those SMMU nodes. |

### PPTT evidence status

[CIX PR #44][cix-pr-44] proposes a different revision-3 PPTT for another Sky1
board.  It
agrees with this payload on the broad CPU grouping, the private A720 L1 and
512 KiB L2 caches, and the shared 12 MiB system cache.  It differs in two
material ways:

- it places CPU IDs 2 through 5 behind one shared 2 MiB L2 cache; and
- it assigns an explicit Cache ID to every cache rather than only to the
  shared system cache.

The current payload gives CPU IDs 2 through 5 private 32 KiB instruction and
data caches whose next level is the 12 MiB system cache.  The Sky1
device-tree source used by this package also links its four efficiency cores
directly to that system cache and does not describe a 2 MiB shared L2.

PR #44 therefore does not yet prove a correction to this payload.  No PPTT
change should be made until a board-independent architectural source, a
cache-register capture with a proven sharing map, or authoritative CIX
documentation establishes the proposed 2 MiB cache.  The Orange Pi 6 Plus
SSDT changes in the pull request are board-specific and are not candidates
for direct use on Orion O6 or O6N.

## ebuild usage

Build and install the SSDT-only profiles:

```sh
USE=acpi-table-upgrade emerge sys-kernel/cix-sources
```

Build and install SSDT profiles plus the available DSDT/whole-table profiles:

```sh
USE="acpi-table-upgrade acpi-table-upgrade-dsdt" emerge sys-kernel/cix-sources
```

The `acpi-table-upgrade` flag adds a build-time dependency on
`>=sys-power/iasl-20241212`. Release validation uses the newest available
ACPICA compiler, currently `iasl 20260408`, because newer releases generally
apply stricter ASL checks. Two IORT table-upgrade flags are enabled by
default and may be disabled individually: `acpi-table-upgrade-iort-httu`
enables hardware-managed SMMUv3 access/dirty table updates, and
`acpi-table-upgrade-iort-msi` marks the PCIe SMMUv3 node's ITS mapping as a
valid MSI-domain parent. The ebuild emits one generated `IORT.aml` into the
firmware `1.2` DSDT/whole-table profile when `acpi-table-upgrade-dsdt` is
enabled and one or both IORT flags are enabled. SSDT-only profiles never include
`IORT.aml`, and the O6 firmware `1.3` DSDT profile currently does not include
an IORT replacement table.

During `src_compile`, the ebuild compiles the SSDT-only profile and, when
requested, the DSDT/whole-table profile. The install tree contains the ASL
sources, compiled AML payloads, and generated initramfs source lists:

```text
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/shared/1.2/pptt/
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/o6/shared/ssdt/
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/o6/1.2/
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/o6/1.3/
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/o6n/shared/ssdt/
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/o6n/1.2/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/1.2/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/1.2/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/1.2/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/1.2/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/1.3/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/1.3/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/1.3/initramfs-dsdt/kernel/firmware/acpi/  # with acpi-table-upgrade-dsdt
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/1.3/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/1.2/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/1.2/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/1.2/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/1.2/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/1.3/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/1.3/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
```

`<board>/1.2/initramfs.list` selects the `1.2` SSDT-only profile for `o6` or
`o6n`. `<board>/1.2/initramfs-dsdt.list` selects the same board-specific SSDT
payloads plus the DSDT, PPTT, and enabled IORT whole-table replacements.
`<board>/1.3/initramfs.list` selects the firmware `1.3` SSDT-only profile.
`o6/1.3/initramfs-dsdt.list` selects the O6 firmware `1.3` DSDT profile. O6N
firmware `1.3` has no `initramfs-dsdt.list` until an O6N `1.3.x` DSDT is
qualified. The unversioned `<board>/initramfs*.list` paths remain `1.2`
compatibility aliases, and the historical top-level `initramfs*.list` paths
remain O6 `1.2` aliases.

Keep `/usr/src/linux` pointing at the kernel source tree being built if you want
one reusable `.config` across kernel version bumps. The kernel build resolves
relative `CONFIG_INITRAMFS_SOURCE` paths from the build output directory when
`O=...` is used, so the recommended value uses the stable `/usr/src/linux`
symlink rather than a path relative to the source tree.

## Kernel Configuration

For either table-upgrade profile, enable the built-in uncompressed initramfs
ACPI override path:

```text
CONFIG_BLK_DEV_INITRD=y
CONFIG_ACPI_TABLE_UPGRADE=y
CONFIG_ACPI_TABLE_OVERRIDE_VIA_BUILTIN_INITRD=y
CONFIG_INITRAMFS_COMPRESSION_NONE=y
```

For the SSDT-only profile:

```text
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6/1.2/initramfs.list"
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6n/1.2/initramfs.list"
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6/1.3/initramfs.list"
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6n/1.3/initramfs.list"
```

For the available DSDT-replacement profiles:

```text
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6/1.2/initramfs-dsdt.list"
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6n/1.2/initramfs-dsdt.list"
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6/1.3/initramfs-dsdt.list"
```

The selected source list includes the kernel's minimal default initramfs
entries and the ACPI override layout:

```text
dir /dev 0755 0 0
nod /dev/console 0600 0 0 c 5 1
dir /root 0700 0 0
dir /kernel 0755 0 0
dir /kernel/firmware 0755 0 0
dir /kernel/firmware/acpi 0755 0 0
file /kernel/firmware/acpi/<table>.aml /usr/src/linux-<version>/cix-acpi-table-upgrade/<board>/<firmware>/<profile>/kernel/firmware/acpi/<table>.aml 0644 0 0
```

## Boot-Time Controls

The kernel patch queue adds two early command-line controls for diagnostics and
safe one-off recovery boots:

```text
acpi_table_upgrade=off
```

This disables ACPI table upgrade processing completely, even when AML files are
built into the kernel image through `CONFIG_INITRAMFS_SOURCE`. The kernel logs
that table upgrades were disabled before returning from the upgrade scanner.

```text
acpi_table_upgrade.exclude=O6TZNP.aml
acpi_table_upgrade.exclude=kernel/firmware/acpi/O6TZNP.aml
acpi_table_upgrade.exclude=/kernel/firmware/acpi/O6TZNP.aml
```

This leaves ACPI table upgrade enabled, but skips selected AML files. Entries
are comma-separated and may be specified as a basename or as the cpio path with
or without a leading `/`. The kernel still logs discovered candidate AML files,
marks excluded entries in that discovery line, and emits an explicit `Table
Upgrade: skip [...] (<path>)` line for each skipped table. Override and install
messages also include enough table identity to match the action back to the
corresponding discovery line, which includes the backing cpio path.

The supplemental SoC thermal sensor zones are combined in `O6TZSNS.aml`. The
existing EC thermal-zone critical trip remains separate as `O6ECTZ.aml` so it
can still be isolated independently from the PMMX.SENG sensor table.

## kconfig_update.py

The helper can print `.config` fragments, print update diffs for an existing
`.config`, or apply those update diffs with `--apply`. In fragment and update
modes, `--kernel-version` is normally unnecessary because the helper detects the
kernel version from `KERNEL_TREE/Makefile`. `--firmware` selects the coarse
firmware family used for ACPI table-upgrade paths. Omit it, or pass
`--firmware auto`, to infer the firmware family from local DMI/sysfs data; if
that cannot be inferred, the helper falls back to `1.2` and prints a warning.

Firmware `1.2` SSDT-only profile:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode fragment \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --firmware 1.2 \
  --cix-patches yes \
  --acpi-table-upgrade ssdt
```

Firmware `1.3` SSDT-only profile:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode fragment \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --firmware 1.3 \
  --cix-patches yes \
  --acpi-table-upgrade ssdt
```

Firmware `1.2` DSDT/whole-table profile:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode fragment \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --firmware 1.2 \
  --cix-patches yes \
  --acpi-table-upgrade dsdt
```

Firmware `1.3` O6 DSDT profile:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode fragment \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --firmware 1.3 \
  --cix-patches yes \
  --acpi-table-upgrade dsdt
```

`--board-profile o6n-acpi --firmware 1.3 --acpi-table-upgrade dsdt` is rejected
until a qualified O6N firmware `1.3` DSDT profile exists.

Use `--board-profile o6n-acpi` instead to select the O6N board-specific
initramfs source list.

Print a diff for an existing config without changing it:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode update \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --firmware 1.2 \
  --cix-patches yes \
  --acpi-table-upgrade dsdt \
  /path/to/.config
```

Add `--apply` to update the target `.config` file in place. In apply mode, the
helper writes a backup before overwriting the target config.

## Capturing Stock Firmware Tables

To qualify the firmware `1.3` SSDT profile against a live system, ask someone
booted on stock firmware with ACPI table upgrades disabled to run the following.
Set `BOARD=o6n` for O6N hardware.

```sh
BOARD=o6 FW=1.3.0
OUT="$HOME/acpi-captures/${BOARD}-${FW}-$(hostname)-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT"
{
  printf 'board=%s\n' "$BOARD"
  printf 'firmware=%s\n' "$FW"
  printf 'captured_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'kernel=%s\n' "$(uname -a)"
  printf 'cmdline=%s\n' "$(cat /proc/cmdline)"
} > "$OUT/README.txt"
dmesg > "$OUT/dmesg.txt" 2>&1 || sudo dmesg > "$OUT/dmesg.txt" 2>&1 || true
for f in bios_vendor bios_version bios_date product_name product_version \
         board_vendor board_name board_version sys_vendor; do
  [ -r "/sys/class/dmi/id/$f" ] && \
    cat "/sys/class/dmi/id/$f" > "$OUT/dmi-$f.txt"
done
sudo acpidump > "$OUT/acpidump.txt"
sudo cp -a /sys/firmware/acpi/tables "$OUT/sysfs-acpi-tables"
sudo chown -R "$(id -u):$(id -g)" "$OUT"
if command -v acpixtract >/dev/null 2>&1; then
  ( cd "$OUT" && acpixtract -a acpidump.txt > acpixtract.log 2>&1 || true )
fi
if command -v iasl >/dev/null 2>&1; then
  ( cd "$OUT" && set -- DSDT.dat SSDT*.dat && [ -e "$1" ] && \
    iasl -e SSDT*.dat -d "$@" > iasl.log 2>&1 || true )
fi
tar -C "$(dirname "$OUT")" -cJf "$OUT.tar.xz" "$(basename "$OUT")"
sha256sum "$OUT.tar.xz" > "$OUT.tar.xz.sha256"
printf 'Created %s\n' "$OUT.tar.xz"
```

## Validation After Boot

After booting with a table-upgrade profile, check `dmesg` for ACPI override
messages and for the repaired devices. For either profile:

```sh
dmesg | grep -Ei \
  'ACPI:.*(upgrade|override)|O6RBRR|O6TZSNS|rts5453|cppc|arm-scmi|GPU|PNP0A08|PNP0D10'
```

For the DSDT/whole-table profile, also check for the whole-table payloads:

```sh
dmesg | grep -Ei \
  'ACPI:.*(DSDT|IORT|PPTT|ORIONO6|RAOP)|Table Upgrade: override \[(DSDT|IORT|PPTT|SSDT)'
```

[cix-pr-44]: https://github.com/cixtech/cix-linux-main/pull/44
