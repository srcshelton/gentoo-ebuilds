# Orion O6 ACPI Table Upgrade Support

Linux can optionally load replacement or supplemental ACPI tables from an
initramfs. The kernel documentation for this mechanism is:

`Documentation/admin-guide/acpi/initrd_table_override.rst`

The table sources shipped by this package target the Radxa Orion O6 running
Radxa vendor firmware `1.2.1`.

## Available Profiles

There are two supported choices.

- Supplemental table profile: enable the smaller table-upgrade set. This
  repairs the captured `_CPC` reference-performance values, updates the Radxa
  O6 RTS5453 Type-C PD controller nodes to use shared IRQ resources, SCMI
  mailbox shared-memory windows, GPU coherency attribute,
  BusPerf fabric performance devices, DSU PMU exposure, an isolated ECTZ
  critical-trip overlay, a combined DTB/MemoryMap-backed SoC thermal monitor sensor table,
  DTB-aligned audio DMA/HDA metadata including the HDA `_DMA` translation
  window, and the PPTT cache topology.
- DSDT replacement: enable the full replacement profile. This profile includes
  the same supplemental tables and also supplies a Radxa `1.2.1`-derived `DSDT.aml`
  with a newer OEM revision, mainline-only PCIe/USB device-model policy, and
  DTB-aligned eDP backlight brightness levels.

The DSDT replacement keeps the generic Linux-visible `PNP0A08` PCIe and
`PNP0D10` USB hierarchies and marks the duplicate vendor-specific CIX/Cadence
PCIe/USB hierarchy not-present. It does not change CPU numbering, APIC, IORT,
or the AML CPU topology. The common profile supplies a replacement `PPTT.aml`
that describes the register-confirmed private L1/L2 caches and shared 12 MiB
last-level cache.

## ebuild usage

Build and install the SSDT profile:

```sh
USE=acpi-table-upgrade emerge sys-kernel/cix-sources
```

Build and install both profiles, including the DSDT replacement:

```sh
USE="acpi-table-upgrade acpi-table-upgrade-dsdt" emerge sys-kernel/cix-sources
```

The `acpi-table-upgrade` flag adds a build-time dependency on `>=sys-power/iasl-20241212`.
Two IORT table-upgrade flags are enabled by default and may be disabled
individually: `acpi-table-upgrade-iort-httu` enables hardware-managed SMMUv3
access/dirty table updates, and `acpi-table-upgrade-iort-msi` marks the PCIe
SMMUv3 node's ITS mapping as a valid MSI-domain parent. These are emitted as one
generated `IORT.aml` when one or both flags are enabled.

During `src_compile`, the ebuild compiles the supplemental-table profile
and, when requested, the DSDT-replacement profile. The install tree contains the
ASL sources, compiled AML payloads, and generated initramfs source lists:

```text
/usr/src/linux-<version>/cix-acpi-table-upgrade/source/orion-o6-radxa-1.2.1/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs-dsdt/kernel/firmware/acpi/
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs.list
/usr/src/linux-<version>/cix-acpi-table-upgrade/initramfs-dsdt.list  # with acpi-table-upgrade-dsdt
```

`initramfs.list` selects the supplemental-table profile. `initramfs-dsdt.list`
selects the same supplemental tables plus the full DSDT replacement.

Keep `/usr/src/linux` pointing at the kernel source tree being built if you want
one reusable `.config` across kernel version bumps. The kernel build resolves
relative `CONFIG_INITRAMFS_SOURCE` paths from the build output directory when
`O=...` is used, so the recommended value uses the stable `/usr/src/linux`
symlink rather than a path relative to the source tree.

## Kernel Configuration

For either table-upgrade profile, enable the built-in uncompressed
initramfs ACPI override path:

```text
CONFIG_BLK_DEV_INITRD=y
CONFIG_ACPI_TABLE_UPGRADE=y
CONFIG_ACPI_TABLE_OVERRIDE_VIA_BUILTIN_INITRD=y
CONFIG_INITRAMFS_COMPRESSION_NONE=y
```

For the supplemental-table profile:

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

This leaves ACPI table upgrade enabled, but skips selected AML files. Entries are
comma-separated and may be specified as a basename or as the cpio path with or
without a leading `/`. The kernel still logs discovered candidate AML files, marks
excluded entries in that discovery line, and emits an explicit `Table Upgrade:
skip [...] (<path>)` line for each skipped table. Override and install messages
also include enough table identity to match the action back to the corresponding
discovery line, which includes the backing cpio path.

The supplemental SoC thermal sensor zones are now combined in `O6TZSNS.aml`.
The existing EC thermal-zone critical trip remains separate as `O6ECTZ.aml` so
it can still be isolated independently from the PMMX.SENG sensor table.

## kconfig_update.py

The helper can print or apply the same kernel config choices.

Supplemental table profile:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode fragment \
  --kernel-version 7.0 \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --cix-patches yes \
  --acpi-table-upgrade ssdt
```

DSDT replacement:

```sh
python3 sys-kernel/cix-sources/files/kconfig_update.py \
  --mode fragment \
  --kernel-version 7.0 \
  --kernel-tree /usr/src/linux-<version> \
  --board-profile o6-acpi \
  --cix-patches yes \
  --acpi-table-upgrade dsdt
```

Use `--mode update /path/to/.config` to update an existing config in place. The
script writes a backup before modifying the target config.

## Validation After Boot

After booting with a table-upgrade profile, check `dmesg` for ACPI override
messages and for the repaired devices:

```sh
dmesg | grep -Ei 'ACPI:.*(upgrade|override)|rts5453|cppc|arm-scmi|GPU|PNP0A08|PNP0D10'
```
