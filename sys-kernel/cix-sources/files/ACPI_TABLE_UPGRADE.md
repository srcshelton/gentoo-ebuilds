# ACPI table upgrades for Radxa Orion O6 and O6N

Linux can load supplemental or replacement ACPI tables from its initramfs.
This package uses that standard mechanism to correct firmware descriptions and
expose hardware which Linux can otherwise misconfigure or fail to enumerate.
It does not modify or flash the board firmware.

The profiles in this package target [Radxa Orion O6](https://docs.radxa.com/en/orion/o6)
and [O6N](https://docs.radxa.com/en/orion/o6n) boards. The maintained
stock firmware baselines are **1.2.4** for `1.2` (`fw1.2`) and **1.3.2**
for `1.3` (`fw1.3`). The 1.3 replacement DSDT was derived from 1.3.1.
The published 1.3.1 and 1.3.2 DSDTs are byte-identical on each board, as
are the O6N board SSDTs. The O6 full board SSDT incorporates the shared
RTS5453 interrupts from 1.3.2. Firmware 1.3.0 has a different DSDT and
board resources. Point releases outside the stated baselines have no
independent qualification.
The version-family selector in `kconfig_update.py` also accepts custom
version strings. Confirm the actual ACPI layout before selecting a profile.
Custom firmware that already supplies these corrections normally
needs table upgrades disabled. Stock-order CPU/PPTT and SCMI replacements
require stock CPU numbering.

The 1.3 profiles leave the stock IORT unchanged, including its absence of PCIe
SMMU mappings. The kernel mechanism is described in the
[Linux ACPI initrd table override documentation](https://docs.kernel.org/admin-guide/acpi/initrd_table_override.html).

> **Warning:** Select the exact board and firmware family. A table compiled for
> the wrong board or firmware can hide devices, describe incorrect resources,
> or prevent boot. Keep a known-good kernel and use `acpi_table_upgrade=off`
> for a recovery boot.

## Available profiles

An SSDT-only profile adds narrowly scoped supplemental tables. A full profile
contains the same SSDTs plus replacement tables such as DSDT, PPTT, the O6
board SSDT, and optionally IORT. It also adds the Cadence xHCI overlay.
Use a full profile only for the board and firmware shown.

On Linux 7.2, the O6/O6N firmware-1.2 full profile also contains one
`MPAM.aml` table describing the DSU-120 cache-allocation controller. Linux's
[arm64 MPAM documentation](https://docs.kernel.org/arch/arm64/mpam.html)
describes the architecture support and its use of the
[resctrl interface](https://docs.kernel.org/filesystems/resctrl.html).
The table is inert when `CONFIG_ARM64_MPAM` is disabled. Enabling that kernel
option together with `CONFIG_RESCTRL_FS` causes Linux to initialise the MPAM
hardware and must be followed by the checks below.

| Board and firmware | SSDT-only profile | Full profile | Profile embedded in GitHub `.deb` packages |
| --- | --- | --- | --- |
| O6, Radxa 1.2.4 | 11 AML files | 15 files on Linux 6.18; 16 on Linux 7.2; one additional file with IORT | Full, with both IORT transformations |
| O6, Radxa 1.3.2 | 10 AML files | 13 files | Full |
| O6N, Radxa 1.2.4 | 7 AML files | 10 files on Linux 6.18; 11 on Linux 7.2; one additional file with IORT | Full, with both IORT transformations |
| O6N, Radxa 1.3.2 | 7 AML files | Not available | SSDT-only |

The `arm64` and `arm64-64k` package variants use the same ACPI payload.
Their difference is the kernel page-size/configuration flavour.

### Exact profile contents

| Profile | AML files loaded from the built-in initramfs |
| --- | --- |
| O6 1.2 SSDT-only | `S1DMACLK.aml`, `S1AUD.aml`, `S1DMAR.aml`, `O6BPERF.aml`, `O6DSUP.aml`, `O6ECTZ.aml`, `O6GCRT.aml`, `O6RTS.aml`, `O6RBRR.aml`, `O6SCMI.aml`, `O6TZSNS.aml` |
| O6 1.2 full | The eleven files above, plus `S1XHCSCT.aml`, `DSDT.aml`, `ORIONO6.aml`, `PPTT.aml`, optional `IORT.aml`, and on Linux 7.2 `MPAM.aml` |
| O6 1.3 SSDT-only | `S1DMACLK.aml`, `S1AUD.aml`, `S1DMAR.aml`, `O6BPERF.aml`, `O6DSUP.aml`, `O6ECTZ.aml`, `O6RTS.aml`, `O6RBRR.aml`, `O6SCMI.aml`, `O6TZSNS.aml` |
| O6 1.3 full | The ten files above, plus `S1XHCSCT.aml`, `DSDT.aml` and `ORIONO6.aml` |
| O6N 1.2 SSDT-only | `S1DMACLK.aml`, `S1AUD.aml`, `S1DMAR.aml`, `O6NBPERF.aml`, `O6NDSUP.aml`, `O6NRBRR.aml`, `O6NSCMI.aml` |
| O6N 1.2 full | The seven files above, plus `S1XHCSCT.aml`, `DSDT.aml`, `PPTT.aml`, optional `IORT.aml`, and on Linux 7.2 `MPAM.aml` |
| O6N 1.3 SSDT-only | `S1DMACLK.aml`, `S1AUD.aml`, `S1DMAR.aml`, `O6NBPERF.aml`, `O6NDSUP.aml`, `O6NRBRR.aml`, `O6NSCMI.aml` |

## Changes supplied by the tables

Repository source paths below are relative to
`sys-kernel/cix-sources/files/acpi-table-upgrade/`. Installed source copies are
beneath `cix-acpi-table-upgrade/source/`. The table accounts for every retained
ASL source, both binary IORT inputs, and both IORT generator copies. The Python
generators are build tools and are not embedded in the kernel image.

| Installed AML | Source input | Applies to | Subsystem and practical benefit |
| --- | --- | --- | --- |
| `S1XHCSCT.aml` | `shared/shared/ssdt-full/sky1-xhci-stream-context.asl` | Every full profile | Opts the identified Cadence xHCI controllers into the maintained stream-context handling. |
| `S1DMACLK.aml` | `shared/shared/ssdt/sky1-audio-dma-clock-name.asl` | Every profile | Names the AUDSS-local DMA1 AXI clock `axiclk`, allowing the DMA350 driver to request the clock by the name it expects. |
| `S1AUD.aml` | `shared/shared/ssdt/sky1-audio-dma-api.asl` | Every profile | Gives HDA its standard DMA translation on O6 and O6N and neutralises the native DMA1/HDA fixed-pool tuples, which neither reserve memory nor have a retained ACPI consumer. DMA1 and HDA use normal DMA-API allocation instead. |
| `S1DMAR.aml` | `shared/shared/ssdt/sky1-audss-dma-range.asl` | Every profile | Describes DMA1's standard 32-bit DMA address translation window. The matching kernel refuses to start DMA1 when neither this table nor the native-firmware compatibility property supplies that essential mapping. |
| `O6DSUP.aml` | `o6/shared/ssdt/orion-o6-dsu-pmu.asl` | Every O6 profile | Exposes the DSU PMU for shared-cache and CPU-cluster performance monitoring. |
| `O6NDSUP.aml` | `o6n/shared/ssdt/orion-o6n-dsu-pmu.asl` | Every O6N profile | Exposes the equivalent DSU PMU device on O6N. |
| `O6BPERF.aml` | `o6/shared/ssdt/orion-o6-busperf.asl` | Every O6 profile | Exposes the firmware CI-700 and multimedia-fabric SCMI performance domains to the CIX bus-performance driver. The driver validates every advertised OPP and provides standard devfreq controls while preserving firmware policy until an administrator selects a frequency or fixed governor. |
| `O6NBPERF.aml` | `o6n/shared/ssdt/orion-o6n-busperf.asl` | Every O6N profile | Exposes the same Sky1 interconnect performance domains on O6N with identical validation and devfreq policy controls. |
| `O6RTS.aml` | `o6/shared/ssdt/orion-o6-rts5453-shared-irq.asl` | Every O6 profile | Corrects the two O6 Type-C port functions of one RTS5453H from `Exclusive` to `Shared`: both use the same level-low GPI4 pin 8 interrupt. Their I2C addresses and exclusive I2C-bus resources are unchanged. Linux on the maintained lines already requests two shared handlers independently, so this repairs the firmware contract rather than changing that Linux admission path. O6N exposes only one port function on this pin and does not use the table. |
| `O6SCMI.aml` | `o6/shared/ssdt/orion-o6-scmi-mailbox-window.asl` | Every O6 profile | Removes mailbox/shared-memory resource overlap and supplies the validated CPU-to-SCMI-domain and power-unit contract used by safe thermal power allocation. The heterogeneous CPU layout maps UIDs 0-1 to SCMI performance domain 4, 2-5 to domain 2, 6-7 to domain 5, 8-9 to domain 6, and 10-11 to domain 3. Invalid metadata causes a safe fallback. |
| `O6NSCMI.aml` | `o6n/shared/ssdt/orion-o6n-scmi-mailbox-window.asl` | Every O6N profile | Applies the same CPU-to-SCMI-domain and thermal contract to O6N, using the identical SoC CPU layout and safe invalid-metadata fallback. |
| `O6RBRR.aml` | `o6/1.2/ssdt/orion-o6-reboot-reason.asl` or `o6/1.3/ssdt/orion-o6-reboot-reason.asl` | Every O6 profile | Exposes the software reboot reason and hardware reset source through the CIX reboot-reason driver. Each firmware profile identifies its value layout, including the firmware-1.3 fastboot reason and shifted exception/watchdog values. |
| `O6NRBRR.aml` | `o6n/1.2/ssdt/orion-o6n-reboot-reason.asl` or `o6n/1.3/ssdt/orion-o6n-reboot-reason.asl` | Every O6N profile | Exposes the equivalent firmware-family-specific reboot-reason device on O6N. |
| `O6ECTZ.aml` | `o6/shared/ssdt/orion-o6-ectz-critical-trip.asl` | Every O6 profile | Adds an approximately 98 °C critical trip to the stock EC thermal zone. It is separate so it can be excluded independently. |
| `O6GCRT.aml` | `o6/1.2/ssdt/orion-o6-gpu-average-critical-trip.asl` | O6 1.2 | Adds the approximately 98 °C critical trip which firmware 1.3 supplies natively to the existing GPU-average thermal zone. |
| `O6TZSNS.aml` | `o6/shared/ssdt/orion-o6-thermal-sensors.asl` | Every O6 profile | Exposes VPU, GPU, DDR, interconnect, NPU, trace, and board NTC thermal zones with critical trips and failure-safe temperature reporting. Board-thermistor zero samples receive three bounded re-reads before being reported as unavailable. |
| `DSDT.aml` | `o6/1.2/dsdt/DSDT.asl` | O6 1.2 full | Provides the generic Linux PCIe/USB device model, corrected resources and bus range, ramoops, GPU supply metadata, and audio, pinctrl, display, and backlight fixes. It retains the five exact PNP0C02 PCI ECAM reservations so the windows remain represented in the ACPI namespace; kernel patch `40046` recognises only the corresponding already-owned duplicate. Active display and Type-C graph links use standard endpoint path strings; graph properties are removed from disabled virtual-display nodes. DMA dimensions remain discoverable from build registers, the unused clock-policy hint and fixed DMA1/HDA pool tuples are omitted, and DMA1 uses `S1DMAR.aml`. The HiFi5 node publishes XAF FIFO mailbox channel 9 and SOF doorbell channel 8 as separate resources, allowing either compile-time owner without sharing a live DSP. |
| `DSDT.aml` | `o6n/1.2/dsdt/DSDT.asl` | O6N 1.2 full | Provides the O6N-specific generic PCIe and USB device model, corrected PRC1 bus range, ramoops, GPU supply metadata, and audio, pinctrl, display, and backlight corrections without importing O6-only board overlays. It retains the combined PNP0C02 PCI ECAM reservation so the window remains represented in the ACPI namespace; kernel patch `40046` recognises only the corresponding already-owned duplicate. Active graph links use standard endpoint path strings and disabled virtual-display links are omitted. DMA dimensions remain discoverable from build registers, the unused clock-policy hint and fixed DMA1/HDA pool tuples are omitted, and DMA1 uses `S1DMAR.aml`. The HiFi5 node publishes XAF FIFO mailbox channel 9 and SOF doorbell channel 8 as separate resources, allowing either compile-time owner without sharing a live DSP. |
| `DSDT.aml` | `o6/1.3/dsdt/DSDT.asl` | O6 1.3 full | Derived from the stock 1.3.1 DSDT, which is byte-identical in 1.3.2. It retains the I2S2 pin-group resource. Suppresses duplicate vendor PCIe devices, describes the five PCI ECAM windows without reserving their intervening holes, and adds the pinctrl, ramoops, eDP-backlight, and canonical active graph corrections. Kernel patch `40046` recognises only the corresponding already-owned duplicate. It removes disabled virtual-display links and omits optional external-pad routes from the internal DisplayPort I2S5--I2S9 codecs. Its native GPU coherency declaration remains authoritative. Unused DMA dimensions, the clock-policy hint, and fixed DMA1/HDA pool tuples are removed; DMA1 uses `S1DMAR.aml`, while the firmware-owned 50 MiB audio HOB is unaffected. The HiFi5 node publishes XAF FIFO mailbox channel 9 and SOF doorbell channel 8 as separate resources. |
| `ORIONO6.aml` | `o6/1.2/ssdt-replacement/ORIONO6.asl` | O6 1.2 full | Splits each USB over-current input from its VBUS-drive GPIO, publishes the dedicated `usb_drive_vbus0`, `usb_drive_vbus4`, and `usb_drive_vbus5` pin groups, with the regulators owning the output lines through their GPIO resources, and expresses the reciprocal Type-C graph links as standard endpoint paths. Camera reset, power-down, and eDP-enable lines remain GPIO-owned instead of also being claimed by overlapping pin groups; the required camera MCLK and eDP mux pads remain represented. Redundant pin-group consumers are removed from GPIO-only board controls. The firmware-exposed EC PWM fan-control interface is retained. |
| `ORIONO6.aml` | `o6/1.3/ssdt-replacement/ORIONO6.asl` | O6 1.3 full | Applies the same USB over-current/VBUS-drive group split, camera/eDP GPIO ownership corrections, GPIO-only board-control cleanup and canonical Type-C graph links as the 1.2 profile. Both RTS5453 interrupt resources are shared in the replacement itself. It retains the firmware-1.3-specific board description and EC PWM fan interface with the fan-mode limitation below. |
| `PPTT.aml` | `shared/1.2/pptt/PPTT.asl` | O6/O6N 1.2 full | Describes the private CPU caches and shared 12 MiB system cache, including an ID that lets Linux report cache sharing consistently. It does not invent an additional 2 MiB A520 L2. |
| `MPAM.aml` | `shared/1.2/mpam/MPAM.asl` | O6/O6N 1.2 full profile on Linux 7.2 | Describes the DSU-120 MPAM controller at `0x0f010000` and links it to PPTT Cache ID 1. When arm64 MPAM is enabled, Linux resctrl exposes the six two-way cache-allocation portions of the shared 12 MiB cache. The optional `mbw_prop` resctrl mount mode also exposes its six-bit proportional-bandwidth stride. The table does not claim unavailable CI-700 partitioning or monitoring. Its optional error interrupt remains omitted. |
| `IORT.aml` | `o6/1.2/iort/IORT.dat` and `o6/1.2/iort/build_iort_upgrade.py` | O6 1.2 full, optional | Generates an upgraded 1.2 IORT. HTTU mode marks SMMUv3 coherent access and advertises hardware access/dirty-table updates; MSI mode supplies valid ITS mappings for the Sky1 PCIe and platform SMMUs. |
| `IORT.aml` | `o6n/1.2/iort/IORT.dat` and `o6n/1.2/iort/build_iort_upgrade.py` | O6N 1.2 full, optional | Generates the equivalent O6N IORT upgrade. The retained O6 and O6N inputs currently produce the same transformations. |

## Firmware settings and full replacements

Radxa changes AML during ReadyToBoot. The SSDT-only profiles leave these
firmware-selected values in place. The full profiles contain fixed snapshots:

| Object | Firmware meaning | Full-profile value |
| --- | --- | --- |
| `\_SB.SCMS` | Enable ACPI SCMI controls the DVFS and clock child devices. The transport has its own status. | 1 in each replacement DSDT |
| `\_SB.ECFM` | O6 EC fan mode used by the ACPI fan power-on method. | 0 (automatic) in each replacement O6 board SSDT |
| `\_SB.GNVA`, `\_SB.GNVL` | Firmware-allocated ACPI NVS address and length. AML reads this block for device availability, USB roles, PCIe and CPU idle settings. | Address `0xfffe0000`, length `0x4d` in each replacement DSDT |

A read-only capture on stock O6 firmware 1.2.4 found all four values
matching the replacements. Linux reported the entire 77-byte interval as
reserved. The EFI descriptor type and allocation stability across boots
remain unverified. Firmware allocates the NVS
block below 4 GiB with `AllocateMaxAddress`. The returned address depends
on the boot-time memory map. A matching capture establishes the values for
that boot. An explicit full-profile selection requires evidence that the
NVS allocation and layout are stable across the intended boots and that
the firmware settings match. Use SSDT-only when that evidence is missing,
and re-check the native values after changes to UEFI settings or boot
configuration.

On a native DSDT, the kernel respects the DVFS and clock child statuses
when `SCMS` is present. Enable **ACPI SCMI** in UEFI if those protocols are
required when using the SSDT-only profile. The legacy kernel quirk still
handles zero-status children on firmware without that policy object.

## Using pre-built Debian or Ubuntu packages

The GitHub workflow selects the full profile for O6 firmware 1.2 and 1.3
and O6N firmware 1.2. O6N firmware 1.3 uses SSDT-only. The selection applies
to both supported kernel lines and page sizes. The workflow embeds the
selected AML files in the kernel image through
`CONFIG_INITRAMFS_SOURCE`. Installing the matching `linux-image` package is
therefore sufficient; do not copy AML files into the distribution initramfs or
run the [ACPICA `iasl` compiler](https://github.com/acpica/acpica) separately.

Package names encode the board, ACPI interface, firmware family, page-size
flavour, and kernel. Choose `o6` or `o6n` for the physical board, `fw1.2` or
`fw1.3` for the installed Radxa firmware family, and `arm64` unless a 64 KiB
page kernel (`arm64-64k`) is explicitly required. For example,
`linux-image-6.18.62-cix-o6-acpi-fw1.2-arm64_6.18.62-1_arm64.deb` contains the
O6 firmware-1.2 full profile. These images require an ACPI-configured board.
The 1.2 packages include both IORT transformations, and the Linux 7.2
full 1.2 profiles include MPAM. Identify CI artifacts by workflow run and
source commit, since the same package name and version can recur in
different builds.

Keep the distribution kernel installed and extract the assembled
`cix-kernel-debs` artifact. Install only the selected image, for example:

```sh
sudo apt install ./linux-image-6.18.62-cix-o6-acpi-fw1.2-arm64_6.18.62-1_arm64.deb
```

If external-module headers are needed, install the matching flavour package
and its common headers package together:

```sh
sudo apt install ./linux-headers-6.18.62-cix-common_6.18.62-1_arm64.deb \
  ./linux-headers-6.18.62-cix-o6-acpi-fw1.2-arm64_6.18.62-1_arm64.deb
```

The assembled artifact contains all variants; avoid broad installation
wildcards. It also contains one verified `linux-libc-dev` package per kernel,
shared across boards, page sizes, and firmware families.

Do not install the artifact's `linux-libc-dev` merely to test the kernel; that
would replace the system-wide userspace headers. Confirm that the bootloader
still offers the known-good distribution kernel before selecting the CIX image.

The image package also installs `/usr/local/bin/kconfig_update.py` for users
who later configure a kernel source tree. It is not needed merely to boot the
pre-built kernel.

If the firmware does not retain the supported stock ACPI layout, make the
first boot with `acpi_table_upgrade=off`. A matching board name alone is not
proof that an alternative firmware publishes compatible ACPI namespaces and
resources.

## Using the Gentoo package

The relevant USE flags are:

| USE flag | Effect |
| --- | --- |
| `acpi-table-upgrade` | Compiles and installs every SSDT-only board/firmware profile. |
| `acpi-table-upgrade-dsdt` | Also builds every supported full profile. Requires `acpi-table-upgrade`. |
| `acpi-table-upgrade-iort-httu` | Adds HTTU attributes to IORT in firmware-1.2 full profiles. |
| `acpi-table-upgrade-iort-msi` | Adds or validates ITS mappings in IORT in firmware-1.2 full profiles. |

All four flags are enabled by default. The two IORT flags have no effect on an
SSDT-only profile or a firmware-1.3 profile.

Compile only the SSDT-only payload profiles with:

```sh
USE="acpi-table-upgrade -acpi-table-upgrade-dsdt" \
  emerge sys-kernel/cix-sources
```

Build the full set of supported profiles with:

```sh
USE="acpi-table-upgrade acpi-table-upgrade-dsdt" \
  emerge sys-kernel/cix-sources
```

The ebuild always installs the complete ACPI source taxonomy for inspection and
future builds. The USE flags control which payload profiles and generated
source lists are compiled and installed beneath:

```text
/usr/src/linux-<version>-cix[-rN]/cix-acpi-table-upgrade/
```

Installing those files does not activate a profile. Kernel configuration must
select one source list:

| Board/firmware | SSDT-only list | Full-profile list |
| --- | --- | --- |
| O6 1.2 | `/usr/src/linux/cix-acpi-table-upgrade/o6/1.2/initramfs.list` | `/usr/src/linux/cix-acpi-table-upgrade/o6/1.2/initramfs-dsdt.list` |
| O6 1.3 | `/usr/src/linux/cix-acpi-table-upgrade/o6/1.3/initramfs.list` | `/usr/src/linux/cix-acpi-table-upgrade/o6/1.3/initramfs-dsdt.list` |
| O6N 1.2 | `/usr/src/linux/cix-acpi-table-upgrade/o6n/1.2/initramfs.list` | `/usr/src/linux/cix-acpi-table-upgrade/o6n/1.2/initramfs-dsdt.list` |
| O6N 1.3 | `/usr/src/linux/cix-acpi-table-upgrade/o6n/1.3/initramfs.list` | Not available |

Compatibility aliases beneath `o6/` and `o6n/` select the corresponding
firmware-1.2 lists; the top-level `initramfs.list` and
`initramfs-dsdt.list` aliases select O6 firmware 1.2. New configurations
should use the explicit board/firmware paths above so the selection remains
clear when another profile is added.

Keep `/usr/src/linux` pointing at the source tree being built. This stable path
also works for out-of-tree builds using `O=...`.

## Kernel configuration

The required kernel options are:

```text
CONFIG_BLK_DEV_INITRD=y
CONFIG_ACPI_TABLE_UPGRADE=y
CONFIG_ACPI_TABLE_OVERRIDE_VIA_BUILTIN_INITRD=y
CONFIG_INITRAMFS_COMPRESSION_NONE=y
CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/<board>/<firmware>/<profile>.list"
```

`kconfig_update.py` can produce a fragment or update an existing `.config`.
Specify the firmware family explicitly when cross-building. The default
`--firmware auto` infers the family for either upgrade profile from local
DMI/sysfs data and falls back to 1.2 with a warning if detection fails.
Check the installed point release, board and firmware settings before using
a full profile.

The standalone `create-patched-kernel.sh` helper defaults to the full DSDT
profile when compiling ACPI tables. Use `--acpi-table-profile ssdt` to
request SSDT-only output, including for O6N firmware 1.3. To configure the
full profile on stock O6 firmware 1.2.4:

```sh
python3 /path/to/gentoo-ebuilds/sys-kernel/cix-sources/files/kconfig_update.py \
  --mode update \
  --kernel-tree /usr/src/linux \
  --board-profile o6-acpi \
  --hardware-profile full \
  --with-npu \
  --firmware 1.2 \
  --cix-patches yes \
  --acpi-table-upgrade dsdt \
  --apply \
  /path/to/.config
```

Use `o6n-acpi` for O6N. The full profile is available for O6 and for
O6N firmware 1.2. `--hardware-profile` controls kernel driver
breadth independently of the ACPI payload: use `server`, `desktop`, or `full`.
`--graphics-profile` can override its graphics/media breadth, while
`--audio-profile` chooses analog HDA, display audio, both, or neither. The
default audio mode follows the resolved display selection and an explicit
display-audio request enables its display pipeline. The NPU is selected
separately with `--with-npu`; internal eDP panel and touchscreen support use
`--with-edp` and `--with-touchscreen` respectively.
The touchscreen choice currently prepares the upstream
[Goodix driver](https://github.com/torvalds/linux/blob/v7.1/drivers/input/touchscreen/goodix.c)
only. The documented O6 panel is a GT911 on firmware-selectable I2C2, but no
retained table-upgrade profile creates that child and O6N has no equivalent
board wiring; selecting the option therefore does not by itself make a
touchscreen appear.

The dedicated O6 touchscreen connector shares its I2C2 data and clock nets
with header pins 27/28. They are not independent GPIOs while I2C2 is active.
The table upgrades do not invent missing electrical PinGroup data for header
functions such as I2C4; those lines are excluded from the conservative GPIO
Aggregator profile until their complete producer contract can be sourced and
qualified.

To expose DSU cache partitioning on Linux 7.2, select the normal
firmware-1.2 `dsdt` profile, then enable `CONFIG_ARM64_MPAM=y` and
`CONFIG_RESCTRL_FS=y` in the kernel configuration. `olddefconfig` should derive
`CONFIG_ARM64_MPAM_RESCTRL_FS=y`. Leaving `CONFIG_ARM64_MPAM` disabled keeps
the included `MPAM.aml` table inert.

## Boot-time controls

To disable all initramfs ACPI table upgrades for one boot, add:

```text
acpi_table_upgrade=off
```

This leaves the AML embedded in the image but prevents Linux from loading it.
The kernel logs that table-upgrade processing was disabled.

With [GNU GRUB](https://www.gnu.org/software/grub/manual/grub/html_node/Menu-entry-editor.html),
highlight the CIX entry, press `e`, append the parameter to the line beginning
with `linux`, and press `Ctrl-x` or `F10`. This changes only that boot. Use the
equivalent temporary command-line edit in another bootloader, or select the
previously working kernel if recovery is required.

To leave the profile enabled while excluding one or more payloads, add a
comma-separated list:

```text
acpi_table_upgrade.exclude=O6TZSNS.aml
acpi_table_upgrade.exclude=O6ECTZ.aml,O6TZSNS.aml
```

An entry may be an AML basename or its initramfs path, with or without a
leading slash. Linux logs every excluded file. `O6TZSNS.aml` contains the
supplemental O6 SoC/board sensors; `O6ECTZ.aml` contains the separate EC
critical trip, so the two thermal changes can be isolated independently.

## Validation after boot

Check that Linux discovered and installed the intended payloads:

```sh
sudo dmesg | grep -Ei \
  'Table Upgrade|ACPI:.*(upgrade|override)|O6(BPERF|DSUP|ECTZ|GCRT|RTS|RBRR|SCMI|TZSNS)|O6N(BPERF|DSUP|RBRR|SCMI)'
```

For a full profile, also look for whole-table replacements:

```sh
sudo dmesg | grep -Ei \
  'Table Upgrade: override.*(DSDT|IORT|PPTT|ORIONO6)|ACPI:.*(DSDT|IORT|PPTT)'
```

For a kernel built with arm64 MPAM enabled, first confirm that the table,
controller and resctrl interface agree before creating any resource group.
Use an ordinary mount for cache allocation alone, or add `-o mbw_prop` before
creating groups when proportional bandwidth is also required:

```sh
sudo dmesg | grep -Ei 'ACPI:.*MPAM|mpam|resctrl'
mountpoint -q /sys/fs/resctrl ||
  sudo mount -t resctrl resctrl /sys/fs/resctrl
cat /sys/fs/resctrl/info/L3/cbm_mask
```

To opt in to proportional bandwidth on an otherwise unmounted filesystem:

```sh
sudo mount -t resctrl -o mbw_prop resctrl /sys/fs/resctrl
cat /sys/fs/resctrl/info/MB_PROP/{min_bandwidth,max_bandwidth,bandwidth_gran}
```

The expected `MB_PROP` values are `0`, `63`, and `1`. The schema value is the
raw hardware stride-minus-one field: zero selects stride one; higher values
give that group a lower relative share only while bandwidth is contended.
This is not an absolute bandwidth limit. A first non-zero setting emits a
one-time kernel warning to draw attention to its workload-dependent performance
effect. Measure the target workload before retaining a non-zero policy.

The expected cache mask is `3f`: six available portions. Do not continue with
partitioning if the mask, cache level, CPU affinity, or controller count
differs. When changing a policy, use bounded workloads, restore every task to
the root group, remove temporary groups, and confirm the root mask is `3f`
before ordinary use.

If `dmesg` access is restricted, use `sudo journalctl -k -b`. Record complete
boot output before drawing conclusions from one missing device: an earlier AML
load or dependency failure often explains a later probe error.

## Compatibility and limitations

- Stock 1.2.4 and 1.3.2 already supply the corrected CPPC reference-performance
  values. The old `O6CPPC.aml` and `O6NCPPC.aml` fixups are no longer installed.
  The firmware-1.2 full DSDTs retain the corrected PRC1 bus range.
- O6N firmware 1.3 has no supported DSDT replacement. It is SSDT-only.
- Stock firmware 1.3.2 does not describe the PCIe SMMU in IORT. The 1.3
  profiles leave IORT unchanged and do not restore PCIe DMA isolation.
- The full 1.2 DSDTs retain the vendor's five 16 GiB PCIe MMIO windows. The
  alternative 32 GiB apertures are not included.
- Native and full replacement tables report the PCI ECAM windows through
  PNP0C02 so they remain represented in the ACPI namespace. Kernel patch
  `40046` only demotes the corresponding duplicate-ownership message when the
  CIX table identity, PNP0C02 UID, complete five-window or exact
  combined-window resource form, and conflicting `PCI ECAM` owner all match;
  every other reservation failure remains visible. It does not inspect a
  firmware version. Stock 1.3.2 uses the combined-window form; both full O6
  profiles use the five exact windows.
- Native tables which omit PCI root I/O apertures and the O6 EC thermal
  zone's valid trip remain firmware defects. The matching full profile supplies
  the root-bridge resources and `O6ECTZ.aml` supplies the critical trip. The
  kernel deliberately does not invent either board description when table
  upgrades are disabled.
- The replacement PPTT models the A520 private L1 caches, A720 private L1/L2
  caches, and shared 12 MiB system cache. It does not add the disproved extra
  2 MiB A520 L2.
- The Linux 7.2 MPAM table describes only the DSU-local shared cache. It is
  inert unless arm64 MPAM is enabled. The exposed controller has no monitoring
  resources, and CI-700 partitioning is unavailable. Device-DMA/fabric
  partitioning, cache-occupancy monitoring, and bandwidth monitoring are
  therefore not exposed. Linux 7.2 expose the DSU's proportional-bandwidth
  mode only on an explicit `mbw_prop` resctrl mount.
- Linux respects the GPU `_CCA` value supplied by the active firmware tables.
  This supports both older shipped non-coherent declarations and newer
  coherent declarations without importing board policy into the kernel. No
  kernel override or supplemental GPU SSDT is used.
- Stock O6 firmware 1.2.4, 1.3.0 and 1.3.1 mark both RTS5453H port
  interrupts `Exclusive`. `O6RTS.aml` makes them `Shared` on GPI4 pin 8.
  Stock 1.3.2 and the corrected O6 1.3 replacement already provide the
  same effective resources. The supplemental table can be excluded with
  `acpi_table_upgrade.exclude=O6RTS.aml` when one of those tables supplies
  both descriptors. Keep it when using the older stock board SSDTs or
  the O6 1.2 full profile. O6N has only one port function on this pin.
- Older O6 board tables combine each USB over-current input and VBUS-drive
  pad in one `pinctrl_usb*` group while the regulator references a missing
  `usb_drive_vbus*` group. The full O6 profiles and stock 1.3.2
  separate those groups. The full profiles use GPIO ownership for the
  regulator outputs and omit their duplicate pin-group consumers.
- I2S5--I2S9 are the internal DisplayPort codec interfaces. Their `_dbg`
  pin groups are optional external routes, not prerequisites for normal
  DisplayPort audio. The O6 firmware-1.3 full profile therefore omits the
  external I2S5--I2S8 consumer resources; I2S9 already had none. Native stock
  firmware may still log missing `_dbg` groups. Source analysis and Radxa's
  firmware description identify these as external routes rather than
  prerequisites for the internal codec path.
- Standard ACPI `_PSV` trips remain visible to Linux. The private firmware
  `SWIT` values are not exposed as a second passive trip: doing so caused severe
  premature throttling with the normal `step_wise` governor.
- Firmware which exposes only the vendor-specific `CIXH2020` PCIe device model
  remains a compatibility gap. The maintained path expects the generic
  `PNP0A08` model used by the supported Radxa profiles.
- A full `DSDT.aml` replacement does not replace APIC or renumber CPUs. PPTT
  and IORT are separate payloads and are included only where the profile table
  above says so.

## Public references and development information

The profile comparisons include the public Radxa package releases
[`1.2.1` (`dadc5b14`)](https://github.com/radxa-pkg/edk2-cix/commit/dadc5b14b141b9132017cda23abfe6ea82ebaeaa),
[`1.2.2` (`2e70744d`)](https://github.com/radxa-pkg/edk2-cix/commit/2e70744d095f7146602f0a8c112e8758f78fe675),
[`1.2.3` (`3b60488d`)](https://github.com/radxa-pkg/edk2-cix/commit/3b60488dc1bb1b3f83c47ec0462f90d3f0e35ad2),
[`1.2.4` (`e4e8f1cb`)](https://github.com/radxa-pkg/edk2-cix/commit/e4e8f1cbe08f708ba6babed1de02ca553473c981),
[`1.3.0` (`39bc6f94`)](https://github.com/radxa-pkg/edk2-cix/commit/39bc6f94a9f503a0b8a92426a5b0f756fadb9917),
[`1.3.1` (`d70d68cc`)](https://github.com/radxa-pkg/edk2-cix/commit/d70d68cce58b53907ce6d43c1ff3fb77a5986a6c),
and [`1.3.2` (`37113548`)](https://github.com/radxa-pkg/edk2-cix/commit/37113548ff022b1ee4be7fdb054a59caef2fdcf8).
Additional comparison points include the public
[Radxa platform source at `f8409b5e`](https://github.com/radxa/edk2-platforms/commit/f8409b5e6c665f9a8ec1207953f0f511cc8e6732),
[CIX platform source at `1a48c652`](https://github.com/cixtech/edk2-platforms/commit/1a48c6523a3225f3ef01b1c91eb3e3dc0dd1857f), and
[Neol00 alternative firmware at `97b7374f`](https://github.com/Neol00/edk2-cix-unlocked/commit/97b7374f9eb24a80c9dbd41673b0cc9c909c5026).

The later Radxa corrections and maintainer explanations used to re-evaluate
these profiles are:

- [issue 27](https://github.com/radxa/edk2-platforms/issues/27) and
  [commit `cdf9d2a5`](https://github.com/radxa/edk2-platforms/commit/cdf9d2a5fa88788c50f2e0997a177895418a4e0c),
  which split the USB over-current and VBUS-drive pin groups;
- [issue 28 and its maintainer response](https://github.com/radxa/edk2-platforms/issues/28#issuecomment-4998385505),
  which identify I2S5--I2S9 as internal DisplayPort codecs and the `_dbg`
  groups as optional external routes; and
- [issue 29](https://github.com/radxa/edk2-platforms/issues/29) and
  [commit `267cde60`](https://github.com/radxa/edk2-platforms/commit/267cde60bbaf94840f709b63e7f118aa7bb40dfb),
  which confirm the shared RTS5453H interrupt model.
