# Orion O6/O6N ACPI Table Upgrade Support

Linux can optionally load replacement or supplemental ACPI tables from an
initramfs. The kernel documentation for this mechanism is:

`Documentation/admin-guide/acpi/initrd_table_override.rst`

The table sources shipped by this package target Radxa Orion O6 and O6N boards
running Radxa vendor firmware `1.2.1`.

## Available Profiles

There are two initramfs source-list profiles: an SSDT-only lower-impact
profile, and a full profile that layers whole-table replacements on top of the
same SSDT payloads.

- SSDT-only profile: enable the smaller table-upgrade set through a board
  `initramfs.list` or `--acpi-table-upgrade ssdt`. This profile contains only
  additive SSDT payloads. On O6 it repairs the captured `_CPC`
  reference-performance values, updates the RTS5453 Type-C PD controller nodes
  to use shared IRQ resources, adds SCMI mailbox shared-memory windows, marks
  the GPU non-coherent, describes BusPerf fabric performance devices, exposes
  the DSU PMU, keeps the isolated `ECTZ` critical trip overlay, supplies the
  combined DTB/MemoryMap-backed SoC thermal monitor sensor table, describes the
  Sky1 reboot-reason register, and adds DTB-aligned audio DMA/HDA metadata
  including the HDA `_DMA` translation window. On O6N, the SSDT profile keeps
  only the overlays that are compatible with the O6N ACPI namespace and leaves
  O6-only EC, Type-C, audio, and extra thermal-zone overlays out.
- DSDT/whole-table profile: enable the full replacement profile through
  a board `initramfs-dsdt.list` or `--acpi-table-upgrade dsdt`. This profile
  includes the same board-specific SSDT payloads, plus that board's
  Radxa-`1.2.1`-derived `DSDT.aml`. On O6, the DSDT replacement carries the
  newer OEM revision, mainline-only PCIe/USB device-model policy, DTB-aligned
  eDP backlight brightness levels, and the ACPI `RAOP` ramoops description used
  by the pstore/ramoops driver. It also replaces the O6 `ORIONO6` board SSDT so
  the three fixed USB VBUS regulators consume the `pinctrl_usb0`,
  `pinctrl_usb4`, and `pinctrl_usb5` groups actually published by `MUX1`, and
  adds fail-closed, read-only EC fan diagnostic methods for target RPM, raw
  measured-RPM bytes, and auto/manual mode readback. On
  O6N, the DSDT source is the O6N-compatible base DSDT captured from an O6N
  `1.2.1` system so the full profile can share the whole-table payload structure
  without using the O6 DSDT or O6 board SSDT on O6N hardware. Both boards also
  include the replacement `PPTT.aml` cache topology and, when enabled by USE
  flags, the generated `IORT.aml` SMMU table update.

The O6 DSDT replacement keeps the generic Linux-visible `PNP0A08` PCIe and
`PNP0D10` USB hierarchies and marks the duplicate vendor-specific CIX/Cadence
PCIe/USB hierarchy not-present. The `DSDT.aml` payload itself does not change
CPU numbering, APIC, IORT, or the AML CPU topology; those whole-table updates
are separate payloads included only in the DSDT/whole-table profile.

## Table Payloads

The installed AML filenames below are the files placed in
`/kernel/firmware/acpi` inside the generated initramfs source lists. Rows marked
`ssdt, dsdt` are included by both the SSDT-only and DSDT/whole-table profiles.
Rows marked `dsdt only` are included only by the DSDT/whole-table profile.

| Board(s) | Profile(s) | Installed AML | Table ID/source | Subsystem(s) | Effect |
| --- | --- | --- | --- | --- | --- |
| O6 | `ssdt`, `dsdt` | `O6AUD.aml` | `O6AUDMD` / `orion-o6-audio-dtb-metadata.asl` | Audio DMA, HDA, clocks | Aligns O6 audio metadata with the vendor DT layout: makes the `DMA1` reserved-memory entry a `12 MiB` window at `0xd0000000`, removes the legacy HDA `RSVL` carveout, adds the HDA `_DMA` translation window from device DMA `0x00000000`-`0x7fffffff` to CPU physical `0x90000000`-`0x10fffffff`, and points `DMA1.CLKT` at the AUDSS DMAC AXI clock. |
| O6, O6N | `ssdt`, `dsdt` | `O6BPF.aml`, `O6NBPF.aml` | `O6BPERF`, `O6NBPERF` / `*-busperf.asl` | SCMI performance domains, fabric clocks | Adds `CIXHA030` (`CI70`) and `CIXHA031` (`MMHB`) ACPI devices with SCMI DVFS performance-domain references to domains `10` and `11`, allowing the Linux `CIX_BUS_PERF` driver to bind the CI700 and NI700/MMHUB fabric performance controls. |
| O6, O6N | `ssdt`, `dsdt` | `O6CPPC.aml`, `O6NCPPC.aml` | `O6CPPC`, `O6NCPPC` / `*-cppc-reference-performance.asl` | CPU performance, CPPC | Repairs `_CPC` `ReferencePerformance` values that stock firmware reports as `1000` for every CPU. The overlay derives replacement values from nominal performance/frequency and the `1 GHz` architectural timer, while leaving CPU topology and numbering unchanged. |
| O6, O6N | `ssdt`, `dsdt` | `O6DSUP.aml`, `O6NDSUP.aml` | `O6DSUP`, `O6NDSUP` / `*-dsu-pmu.asl` | PMU, CPU cluster observability | Adds the DSU PMU as an `ARMHD500` ACPI device using GSI `34` (`SPI 2`), matching the vendor DTB's shared cluster/L3 PMU description. |
| O6, O6N | `ssdt`, `dsdt` | `O6GPU.aml`, `O6NGPU.aml` | `O6GPUCCA`, `O6NGPUCA` / `*-gpu-noncoherent.asl` | GPU DMA coherency | Sets `\_SB.GPU._CCA` to `0` so Linux treats Sky1 GPU DMA as non-coherent instead of trusting the stock coherent ACPI metadata. |
| O6 | `ssdt`, `dsdt` | `O6RTS.aml` | `O6RTSIRQ` / `orion-o6-rts5453-shared-irq.asl` | USB Type-C, RTS5453, GPIO IRQs | Replaces `\_SB.I2C1.PD10._CRS` and `\_SB.I2C1.PD11._CRS` with resources that keep the original I2C addresses `0x30`/`0x31` but mark the shared `\_SB.GPI4` pin `8` interrupt as `Shared`, matching the actual O6 RTS5453 wiring. |
| O6, O6N | `ssdt`, `dsdt` | `O6SCMI.aml`, `O6NSCMI.aml` | `O6MBX`, `O6NMBX` / `*-scmi-mailbox-window.asl` | SCMI mailbox resources | Replaces `MBX6` and `MBX7` `_CRS` windows so the mailbox register ranges start at `0x06590080` and `0x065a0080`, leaving the leading `0x80` bytes for `SHM0`/`SHM1` and avoiding the stock mailbox/shared-memory resource overlap. |
| O6 | `ssdt`, `dsdt` | `O6ECTZ.aml` | `O6ECTZ` / `orion-o6-ectz-critical-trip.asl` | ACPI thermal, EC thermal zone | Adds a critical trip point to the stock `\_SB.ECTZ` EC thermal zone by supplying `_CRT = 0x0e80` (`3680 dK`, about `95 C`). This remains separate from the sensor-zone overlay so it can be excluded independently. |
| O6, O6N | `ssdt`, `dsdt` | `O6RBRR.aml`, `O6NRBRR.aml` | `O6RBRR`, `O6NRBRR` / `*-reboot-reason.asl` | Reboot reason, diagnostics | Adds a `PRP0001` device compatible with `cix,sky1-reboot-reason` over the read-only reboot-reason registers at `0x16000500` and `0x16000218`, allowing the Linux reboot-reason driver to expose both the software reboot reason and hardware reset source. |
| O6 | `ssdt`, `dsdt` | `O6TZSNS.aml` | `O6TZSNS` / `orion-o6-thermal-sensors.asl` | ACPI thermal, PMMX sensors | Adds PMMX.SENG-backed thermal zones for VPU, GPU bottom/top, SoC bridge, DDR bottom/top, CI700 interconnect, NPU, SoC trace, and two board NTC sensors. Each zone has a critical trip point, a `10` decisecond polling period, and returns `Ones` on PMMX status failure rather than exposing a false temperature. |
| O6, O6N | `dsdt only` | `DSDT.aml` | board-specific `dsdt/DSDT.asl` | ACPI namespace, PCIe, USB, pstore, display | Replaces the stock DSDT with a board-specific Radxa `1.2.1`-derived DSDT. The O6 payload keeps the generic Linux-visible `PNP0A08` PCIe and `PNP0D10` USB model, suppresses overlapping vendor PCIe/USB controller models, adds/tightens PCIe I/O and memory windows, carries the PCIe `_OSC` handoff policy, updates the PRC1 `bus-range` property to `0x90` to `0xaf`, exposes the `RAOP` `ramoops` device, adds the standard GPU `mali-supply` alias for the GPUP power resource, keeps PMMX mailbox helper ASL compatible with current ACPICA, fixes stale I2S5-I2S8 pinctrl consumer names to match the firmware-published IOMUX groups, removes the unresolvable I2S9 pinctrl consumer reference, and carries the display/backlight metadata cleanup. The O6N payload uses an O6N-compatible DSDT source and carries the same GPU supply and I2S pinctrl metadata fixes, but does not import O6-only SSDT overlays. |
| O6 | `dsdt only` | `ORIONO6.aml` | `ORIONO6` / `ssdt-replacement/ORIONO6.asl` | USB VBUS regulators, pinctrl, EC fan diagnostics | Replaces the Radxa `1.2.1` O6 board SSDT with an otherwise equivalent OEM-revision-`2` table whose `VUS0`, `VUS4`, and `VUS5` fixed-regulator resources consume the `pinctrl_usb0`, `pinctrl_usb4`, and `pinctrl_usb5` groups published by `MUX1`, rather than the nonexistent `usb_drive_vbus0`, `usb_drive_vbus4`, and `usb_drive_vbus5` groups. It also adds independent read-only `CIXHA024` methods for target RPM, raw measured-RPM memory-map bytes, the supported fan-mode command-version mask, and auto/manual mode readback. Every method returns an unavailable sentinel on transport, response-length, checksum, EC-result, or capability failure, so unsupported EC firmware preserves the existing PWM-only interface. The revision bump is required because Linux accepts an initrd table as an upgrade only when its OEM revision is newer than the firmware table. |
| O6, O6N | `dsdt only` | `PPTT.aml` | `pptt/PPTT.asl` | CPU/cache topology | Replaces PPTT with a conservative cache topology model: `32 KiB` L1I + `32 KiB` L1D for A520 cores, `64 KiB` L1I + `64 KiB` L1D plus private `512 KiB` L2 for A720 cores, and a shared `12 MiB` system cache. The shared cache carries an explicit revision-3 Cache ID so Linux 6.18, 7.0, and 7.1 group CPUs that see it at the same architectural cache level instead of treating every CPU path as a separate cache instance. It does not renumber CPUs. |
| O6, O6N | `dsdt only`, optional | `IORT.aml` | generated from `iort/IORT.dat` by `build_iort_upgrade.py` | IOMMU, SMMUv3, MSI domains | Generated only when `acpi-table-upgrade-dsdt` is enabled and at least one IORT USE flag is active. `acpi-table-upgrade-iort-httu` marks SMMUv3 nodes coherent and advertises hardware access/dirty table updates. `acpi-table-upgrade-iort-msi` adds or validates ITS mappings for the Sky1 PCIe and platform SMMUv3 nodes at `0x0b010000` and `0x0b1b0000`, marks their device-ID mapping valid, and avoids Linux falling back to wired IRQs for those SMMU nodes. |

## ebuild usage

Build and install the SSDT-only profile:

```sh
USE=acpi-table-upgrade emerge sys-kernel/cix-sources
```

Build and install both profiles, including the full DSDT/whole-table profile:

```sh
USE="acpi-table-upgrade acpi-table-upgrade-dsdt" emerge sys-kernel/cix-sources
```

The `acpi-table-upgrade` flag adds a build-time dependency on
`>=sys-power/iasl-20241212`. Two IORT table-upgrade flags are enabled by
default and may be disabled individually: `acpi-table-upgrade-iort-httu`
enables hardware-managed SMMUv3 access/dirty table updates, and
`acpi-table-upgrade-iort-msi` marks the PCIe SMMUv3 node's ITS mapping as a
valid MSI-domain parent. The ebuild emits one generated `IORT.aml` into the
DSDT/whole-table profile when `acpi-table-upgrade-dsdt` is enabled and one or
both IORT flags are enabled. The SSDT-only profile never includes `IORT.aml`.

During `src_compile`, the ebuild compiles the SSDT-only profile and, when
requested, the DSDT/whole-table profile. The install tree contains the ASL
sources, compiled AML payloads, and generated initramfs source lists:

```text
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/o6/orion-o6-radxa-1.2.1/
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/o6n/orion-o6n-radxa-1.2.1/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/o6n/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
```

`<board>/initramfs.list` selects the SSDT-only profile for `o6` or `o6n`.
`<board>/initramfs-dsdt.list` selects the same board-specific SSDT payloads
plus the DSDT, PPTT, and enabled IORT whole-table replacements. The historical
top-level `initramfs.list` and `initramfs-dsdt.list` paths remain O6 aliases.

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
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6/initramfs.list"
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6n/initramfs.list"
```

For the DSDT-replacement profile:

```text
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6/initramfs-dsdt.list"
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6n/initramfs-dsdt.list"
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
file /kernel/firmware/acpi/<table>.aml /usr/src/linux-<version>/cix-acpi-table-upgrade/<board>/<profile>/kernel/firmware/acpi/<table>.aml 0644 0 0
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
kernel version from `KERNEL_TREE/Makefile`.

SSDT-only profile:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode fragment \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --cix-patches yes \
  --acpi-table-upgrade ssdt
```

DSDT/whole-table profile:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode fragment \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --cix-patches yes \
  --acpi-table-upgrade dsdt
```

Use `--board-profile o6n-acpi` instead to select the O6N board-specific
initramfs source list.

Print a diff for an existing config without changing it:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode update \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --cix-patches yes \
  --acpi-table-upgrade dsdt \
  /path/to/.config
```

Add `--apply` to update the target `.config` file in place. In apply mode, the
helper writes a backup before overwriting the target config.

## Validation After Boot

After booting with a table-upgrade profile, check `dmesg` for ACPI override
messages and for the repaired devices. For either profile:

```sh
dmesg | grep -Ei 'ACPI:.*(upgrade|override)|O6RBRR|O6TZSNS|rts5453|cppc|arm-scmi|GPU|PNP0A08|PNP0D10'
```

For the DSDT/whole-table profile, also check for the whole-table payloads:

```sh
dmesg | grep -Ei 'ACPI:.*(DSDT|IORT|PPTT|ORIONO6|RAOP)|Table Upgrade: override \[(DSDT|IORT|PPTT|SSDT)'
```
