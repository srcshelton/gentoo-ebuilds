# Orion O6 ACPI Table Upgrade Support

Linux can optionally load replacement or supplemental ACPI tables from an
initramfs. The kernel documentation for this mechanism is:

`Documentation/admin-guide/acpi/initrd_table_override.rst`

The table sources shipped by this package target the Radxa Orion O6 running
Radxa vendor firmware `1.2.1`.

## Available Profiles

There are two initramfs source-list profiles: an SSDT-only lower-impact
profile, and a full profile that layers whole-table replacements on top of the
same SSDT payloads.

- SSDT-only profile: enable the smaller table-upgrade set through
  `initramfs.list` or `--acpi-table-upgrade ssdt`. This profile contains only
  additive SSDT payloads. It repairs the captured `_CPC` reference-performance
  values, updates the Radxa O6 RTS5453 Type-C PD controller nodes to use shared
  IRQ resources, adds SCMI mailbox shared-memory windows, marks the GPU
  non-coherent, describes BusPerf fabric performance devices, exposes the DSU
  PMU, keeps the isolated `ECTZ` critical trip overlay, supplies the combined
  DTB/MemoryMap-backed SoC thermal monitor sensor table, describes the Sky1
  reboot-reason register, and adds DTB-aligned audio DMA/HDA metadata including
  the HDA `_DMA` translation window.
- DSDT/whole-table profile: enable the full replacement profile through
  `initramfs-dsdt.list` or `--acpi-table-upgrade dsdt`. This profile includes
  the same SSDT payloads, plus a Radxa `1.2.1`-derived `DSDT.aml` with a newer
  OEM revision, mainline-only PCIe/USB device-model policy, DTB-aligned eDP
  backlight brightness levels, and the ACPI `RAOP` ramoops description used by
  the pstore/ramoops driver. It also adds the replacement `PPTT.aml` cache
  topology and, when enabled by USE flags, the generated `IORT.aml` SMMU table
  update.

The DSDT replacement keeps the generic Linux-visible `PNP0A08` PCIe and
`PNP0D10` USB hierarchies and marks the duplicate vendor-specific CIX/Cadence
PCIe/USB hierarchy not-present. The `DSDT.aml` payload itself does not change
CPU numbering, APIC, IORT, or the AML CPU topology; those whole-table updates
are separate payloads included only in the DSDT/whole-table profile.

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
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/orion-o6-radxa-1.2.1/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
```

`initramfs.list` selects the SSDT-only profile. `initramfs-dsdt.list` selects
the same SSDT payloads plus the DSDT, PPTT, and enabled IORT whole-table
replacements.

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
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/initramfs.list"
```

For the DSDT-replacement profile:

```text
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/initramfs-dsdt.list"
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
file /kernel/firmware/acpi/<table>.aml /usr/src/linux-<version>/cix-acpi-table-upgrade/<profile>/kernel/firmware/acpi/<table>.aml 0644 0 0
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
dmesg | grep -Ei 'ACPI:.*(DSDT|IORT|PPTT|RAOP)|Table Upgrade: override \[(DSDT|IORT|PPTT)'
```
