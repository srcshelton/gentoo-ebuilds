# CIX kernels for Radxa Orion O6 and O6N

`sys-kernel/cix-sources` provides downstream Linux kernels for the CIX Sky1
SoC used by the [Radxa Orion O6](https://docs.radxa.com/en/orion/o6) and
[O6N](https://docs.radxa.com/en/orion/o6n). Each kernel combines an upstream
Linux release, a pinned [Gentoo genpatches](https://dev.gentoo.org/~alicef/genpatches/)
set, selected CIX changes, and maintained board-support patches from this
repository.

The package is intended for users and developers who want a current Linux
kernel with integrated O6/O6N platform support. It is not an official Gentoo,
Debian, Ubuntu, Radxa, or CIX kernel.

> **Warning:** Select the package matching the board and firmware family, and
> keep a known-good kernel installed and available in the boot menu.

## Supported kernels

| Kernel | Gentoo package | Gentoo patch set | CIX source |
| --- | --- | --- | --- |
| [Linux 6.18.44](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tag/?h=v6.18.44) | `cix-sources-6.18.44` | `6.18-51` base, extras, and experimental | [`cix-linux-main` at `bc078a3`](https://github.com/cixtech/cix-linux-main/commit/bc078a383042a6c14b05c56e12390e422f893088) |
| [Linux 7.0.14](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tag/?h=v7.0.14) | `cix-sources-7.0.14-r1` | `7.0-23` base, extras, and experimental | same CIX source |
| [Linux 7.1.8](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tag/?h=v7.1.8) | `cix-sources-7.1.8` | `7.1-11` base and extras | same CIX source |

Each ebuild is the authority for its exact patch order. The Linux 6.18-only
PCIe and pinctrl files listed below backport support already present in Linux
7.x; their absence from a 7.x stack does not mean that the feature was removed.

## Choosing a pre-built package

The [CIX kernel Debian package workflow](../../../.github/workflows/cix-kernel-debs.yml)
builds ACPI kernels for every maintained line. An artifact name has the form:

```text
cix-kernel-debs-<kernel>-<board>-acpi-<configuration>-<firmware>
```

Per-run Actions artifacts are retained for seven days. A maintainer may also
publish selected outputs through the repository's
[Releases page](https://github.com/srcshelton/gentoo-ebuilds/releases).

Choose every component deliberately:

| Component | Choices | Meaning |
| --- | --- | --- |
| Board | `o6`, `o6n` | Must match the physical board. |
| Firmware | `1.2`, `1.3` | Must match the installed Radxa firmware family. Supported profiles cover Radxa 1.2.1 and later 1.2.x releases, plus 1.3.0. Later 1.3.x releases are not assumed to be table-compatible. Check `/sys/class/dmi/id/bios_version` if unsure. |
| Configuration | `generic`, `generic-64k` | Ubuntu-derived arm64 configuration with 4 KiB or 64 KiB pages. Use `generic` unless a 64 KiB kernel is specifically required. |
| Kernel | `6.18.44`, `7.0.14-r1`, `7.1.8` | The maintained Linux version. |

The kernel image already contains the corresponding ACPI table-upgrade
profile. O6 and O6N firmware 1.2 packages use the full profile, as does O6
firmware 1.3; O6N firmware 1.3 uses the SSDT-only profile. See
[`ACPI_TABLE_UPGRADE.md`](ACPI_TABLE_UPGRADE.md) before selecting a package.

These packages are ACPI-only: the packaging step removes board DTBs. They also
do not contain accelerator userspace, model, tuning, or firmware files. The
workflow does not sign the kernel, so firmware enforcing image signatures may
refuse to boot it.

### Installing on Debian or Ubuntu

Download one artifact for one board, firmware family, page-size configuration,
and kernel version. From the extracted artifact directory, install the matching
image and, if needed for external modules, headers:

```sh
sudo apt install ./linux-image-*.deb ./linux-headers-*.deb
```

Do not install a `linux-libc-dev` package from the artifact merely to test the
kernel; it changes the system-wide userspace headers. Keep the distribution
kernel installed, confirm that the bootloader has entries for both kernels,
and select the CIX kernel for the first boot.

After booting, confirm the selected image and ACPI payload:

```sh
uname -a
cat /proc/cmdline
sudo dmesg | grep -Ei 'CIX|Orion|Table Upgrade|ACPI:.*(upgrade|override)'
```

## Building on Gentoo

The package installs a patched kernel source tree; it does not build or select
a kernel automatically. The default USE flags build all supported ACPI
payloads and make the O6/O6N configuration menus available:

```sh
emerge --ask sys-kernel/cix-sources
eselect kernel list
eselect kernel set <number>
```

With `/usr/src/linux` pointing at the selected source tree, configure and build
the kernel using the normal
[Gentoo process](https://wiki.gentoo.org/wiki/Handbook:ARM64/Installation/Kernel).
For an ACPI board, select the exact O6 or O6N profile and firmware family. The
helper in this repository can update an existing configuration, for example:

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
  /usr/src/linux/.config
```

The hardware profiles are cumulative: `server` selects the core headless
platform, storage, network, USB, power and thermal support; `desktop` adds the
GPU/display and supported audio paths; and `full` also adds the VPU and
ISP/camera stack. The NPU remains an explicit `--with-npu` choice. An internal
eDP panel is separately enabled with `--with-edp`; `--with-touchscreen` adds
that eDP support and the upstream
[Goodix I2C driver](https://github.com/torvalds/linux/blob/v7.1/drivers/input/touchscreen/goodix.c).
The current ACPI profiles do not
enumerate the O6 touch controller, and O6N does not expose the same panel
wiring, so this option prepares driver support rather than creating a missing
firmware device. The XAF HiFi5 transport remains an
explicit choice through `--enable-hifi5-xaf` on every retained
kernel line. Linux 7.1 also offers the mutually exclusive
`--enable-hifi5-sof` codec-free SOF path; it requires the full DSDT table
upgrade and firmware installed with the `sof` USE flag.

Use `o6n-acpi` for O6N. O6N firmware 1.3 supports only
`--acpi-table-upgrade ssdt`. The ACPI guide explains the associated USE flags,
kernel options, installed source lists, and recovery controls.

The helper does not force `CONFIG_MEDIA_SUPPORT_FILTER`. That symbol controls
which media categories Kconfig shows; it does not itself select a driver, but
upstream defaults it on when `EXPERT` is disabled and in turn defaults
`MEDIA_SUBDRV_AUTOSELECT` on. The latter may select ancillary sensor, tuner,
I2C, SPI, or frontend drivers for enabled media devices. The `full` O6/O6N
hardware profile instead selects the CIX media-controller, ISP, camera, and
MVX options it actually requires, while preserving an explicit user choice
for the filter.
It also leaves distribution and userspace policy such as `CONFIG_CGROUPS` and
`CONFIG_MEMCG` to the kernel builder; neither option is a hardware requirement.

## Diagnostic builds

To add lightweight PM, thermal, cpufreq, IOMMU debugfs, event-tracing, and SOF
suspend-safe debugfs-cache facilities for troubleshooting, pass
`--enable-runtime-qualification` to `kconfig_update.py`. This is independent
of the much heavier `--enable-kernel-memory-debug` profile. Without
`--enable-runtime-qualification`, the helper explicitly disables the same
debug and instrumentation symbols to produce a performance-oriented production
configuration; omitting the option is therefore not a preserve-existing-state
operation. Within SOF, the profile enables only the suspend-safe debugfs cache
and firmware trace; verbose IPC, retained DSP context, stress and injection
facilities remain disabled. The SOF diagnostics are effective only when SOF is
selected; the profile opens their upstream developer/debug Kconfig gates but
preserves an end-user's independent `CONFIG_EXPERT` choice when the profile is
later disabled.
`--enable-fault-injection` separately enables the kernel's page- and
slab-allocation failure controls. It does not inject a failure by itself; a
maintainer must arm the debugfs controls for a bounded test. Do not use it in a
normal end-user build. `--enable-kernel-memory-debug` follows the same switch
behavior for its larger memory-corruption profile. When diagnostic profiles
are combined, shared requirements remain enabled until every profile that
needs them is omitted.

## Included changes

The table below names every non-Gentoo patch identity included by the default
maintained configurations. “All” means Linux 6.18.44, 7.0.14-r1, and 7.1.8.
Some CIX queue files are taken directly from the pinned CIX archive and
therefore do not also exist as standalone files in this directory.

The pinned Gentoo inputs add stable point updates and distribution-wide
security, build, and configuration fixes. Every integer in an inclusive point
patch range below is present. These are listed separately because they are not
CIX-specific:

| Line | Stable point-update files | Other Gentoo patch files | Effect |
| --- | --- | --- | --- |
| 6.18.44 | `1000_linux-6.18.1.patch` through `1043_linux-6.18.44.patch` | `1510_fs-enable-link-security-restrictions-by-default.patch`<br>`1700_sparc-address-warray-bound-warnings.patch`<br>`1730_parisc-Disable-prctl.patch`<br>`2000_BT-Check-key-sizes-only-if-Secure-Simple-Pairing-enabled.patch`<br>`2901_permit-menuconfig-sorting.patch`<br>`2920_sign-file-patch-for-libressl.patch`<br>`2990_libbpf-v2-workaround-Wmaybe-uninitialized-false-pos.patch`<br>`2991_libbpf_add_WERROR_option.patch`<br>`3000_Support-printing-firmware-info.patch`<br>`4567_distro-Gentoo-Kconfig.patch` | Updates Linux 6.18.0 to 6.18.44 and applies the pinned Gentoo defaults and compatibility fixes. A narrow local build-compatibility patch removes a recursive ARM64 Kconfig dependency introduced by this genpatches revision without otherwise selecting or disabling hardening policy. |
| 7.0.14 | `1000_linux-7.0.1.patch` through `1013_linux-7.0.14.patch` | `1500_ipv6-frag-escape-mitigation.patch`<br>`1502_ipv4-frag-escape-mitigation.patch`<br>`1510_fs-enable-link-security-restrictions-by-default.patch`<br>`1555_can-bcm-defer-rx-op-dealloca.patch`<br>`1605_crypto-nx-fix-nx-crypto-ctx-exit-arg.patch`<br>`1700_sparc-address-warray-bound-warnings.patch`<br>`1710_x86-tools-vdso2c.patch`<br>`1730_parisc-Disable-prctl.patch`<br>`2000_BT-Check-key-sizes-only-if-Secure-Simple-Pairing-enabled.patch`<br>`2901_permit-menuconfig-sorting.patch`<br>`2902_Replace-CONST-CAST-with-const-cast.patch`<br>`2990_libbpf-v2-workaround-Wmaybe-uninitialized-false-pos.patch`<br>`2991_libbpf_add_WERROR_option.patch`<br>`3000_Support-printing-firmware-info.patch`<br>`4567_distro-Gentoo-Kconfig.patch` | Updates Linux 7.0.0 to 7.0.14 and applies the pinned Gentoo security, build, and configuration fixes. |
| 7.1.8 | `1001_linux-7.1.1.patch`, `1001_linux-7.1.2.patch`, and `1002_linux-7.1.3.patch` through `1007_linux-7.1.8.patch` | `1510_fs-enable-link-security-restrictions-by-default.patch`<br>`1700_sparc-address-warray-bound-warnings.patch`<br>`1710_x86-tools-vdso2c.patch`<br>`1730_parisc-Disable-prctl.patch`<br>`2000_BT-Check-key-sizes-only-if-Secure-Simple-Pairing-enabled.patch`<br>`2901_permit-menuconfig-sorting.patch`<br>`2902_Replace-CONST-CAST-with-const-cast.patch`<br>`2990_libbpf-v2-workaround-Wmaybe-uninitialized-false-pos.patch`<br>`2991_libbpf_add_WERROR_option.patch`<br>`3000_Support-printing-firmware-info.patch`<br>`4567_distro-Gentoo-Kconfig.patch` | Updates Linux 7.1.0 to 7.1.8 and applies the pinned Gentoo security, build, and configuration fixes. Stable CPPC, schedutil, and Panthor corrections remain intact alongside the CIX adaptations. |

| Subsystem | Patch files | Lines | What this provides |
| --- | --- | --- | --- |
| ACPI mailbox and SCMI | `0001-mailbox-cix-add-audited-acpi-support.patch`<br>`0002-acpi-cix-resolve-legacy-graph-references.patch`<br>`0003-firmware-arm-scmi-add-audited-acpi-support.patch`<br>`0058-firmware-arm_scmi-mailbox-set-max_rx_timeout_ms-to-3.patch`<br>`2003-firmware-arm_scmi-add-backward-complibility-to-old-f.patch`<br>`2004-acpi-add-backward-complibility-to-old-firmware-with-.patch`<br>`30030-scmi-demote-unsupported-fastchannel-fallback.patch`<br>`30130-acpi-scope-cix-scmi-sta-quirk.patch`<br>`30195-firmware-arm-scmi-use-rational-perf-frequency-conversion.patch` | All | Makes firmware-managed clocks, sensors, performance domains, and media graph links work through ACPI; confines compatibility for released CIX graph tuples to the ACPI graph path; fixes ownership and errors; retains narrow old-firmware compatibility; and preserves accurate performance/frequency conversion. |
| Clocks and resets | `0004-clk-scmi-add-audited-acpi-publication.patch`<br>`0005-clk-cix-add-audited-sky1-support.patch`<br>`0006-reset-cix-add-audited-sky1-support.patch`<br>`0018-clk-clkdev-increase-clkdev-MAX_CON_ID-from-16-to-32.patch` | All | Publishes SCMI clocks to ACPI consumers and supplies the Sky1 clock and reset controllers, including longer firmware clock names. Retryable clock-provider deferral is handled without a false invalid-CLKT error, and overlapping reset/syscon resources are matched by exact CIX provider identity rather than address alone. |
| ACPI resources and power domains | `0007-soc-cix-harden-acpi-resource-lookup-driver.patch`<br>`0008-pmdomain-add-audited-acpi-scmi-support.patch`<br>`30196-power-opp-accept-acpi-only-configurations.patch`<br>`30200-pmdomain-read-provider-performance-state.patch`<br>`40042-platform-acpi-resolve-named-irq-resources.patch` | All | Lets ACPI devices resolve clock/reset dependencies, named interrupts, and SCMI power/performance domains safely. An attached consumer now holds the modular SCMI performance provider until it detaches, so unloading the provider cannot invalidate live NPU, GPU, VPU, or bus-domain callbacks. ACPI-only OPP consumers no longer report the expected absence of Device Tree interconnect paths as an error; DT-enabled kernels still report real lookup failures. The GPU's current frequency is derived from the performance level actually reported by SCMI firmware and its advertised OPP table, rather than a clock cache which is not updated by performance-domain requests. |
| Bus performance domains | `30200-pmdomain-read-provider-performance-state.patch`<br>`40056-soc-cix-add-safe-bus-performance-domain-driver.patch` | All | Exposes the CI-700 and multimedia-fabric SCMI performance domains supplied by the matching ACPI table-upgrade profile. The driver validates every advertised frequency/SCMI-level pair and provides a standard devfreq interface. Its default userspace governor preserves the firmware-selected state until a frequency is requested; configured performance or powersave governors can select the validated maximum or minimum. The first policy request captures the actual provider state, each asynchronous firmware transition is read back with a bounded wait, and module removal restores the captured state. Automatic load scaling is unavailable because these domains do not expose a utilization counter. |
| ACPI table-upgrade controls | `30125-acpi-table-upgrade-add-disable-and-exclude-options.patch` | All | Adds recovery and diagnostic options to disable all table upgrades or skip individual AML files, and logs ACPI header identities without cosmetic left-padding. |
| ACPI-only arm64 boot | `10000-arm64-stub-fdt.patch`<br>`10010-arm64-stub-fdt-enable-kexec-file.patch` | All | Supports ACPI boot with the minimal EFI flattened-tree handoff while retaining file-based kexec. |
| Build compatibility | `10020-lld-timer-of-table-end-warning.patch`<br>`10040-bpf-guard-session-return-btf-id.patch`<br>`10050-bpf-gate-struct-ops-on-kallsyms.patch`<br>`10060-distro-gentoo-avoid-arm64-kspp-kconfig-cycle.patch` | `10020`, `10050`: all; `10040`: 7.0 only; `10060`: 6.18 only | Removes an ACPI-only linker warning, fixes configuration-dependent BPF build failures, and exposes BPF struct-ops providers only when their BTF and kallsyms requirements are present. `10060` repairs the recursive dependency in Gentoo genpatches 6.18-51 while leaving hardening choices to the builder. Ordinary BPF and non-struct-ops networking remain available without kallsyms. |
| Bridge-netfilter advisory | `50030-net-bridge-warn-for-missing-netfilter-on-first-device.patch` | All | Defers the modular bridge-netfilter advisory until the first bridge netdevice is registered and emits it once only when `br_netfilter` has not registered its hook. Loading `br_netfilter` no longer produces a warning while its required `bridge` dependency is inserted first. |
| CPU frequency and topology | `20050-topology-has-missing-cpufreq-ref.patch`<br>`20060-acpi-processor-clarify-ignore-ppc-module-parameter.patch`<br>`20065-cacheinfo-share-global-firmware-ids-across-levels.patch` | All | Gives the scheduler a valid ACPI/CPPC frequency reference and clarifies the `_PPC` override control. `20065` lets Linux recognise one physical cache from its globally unique ACPI PPTT Cache ID even when heterogeneous CPUs reach it at different relative levels; on Sky1 this makes the 12 MiB Hayden/DSU cache's system-wide sharing visible instead of splitting the A720 and A520 CPU maps. Linux 7.1 also assigns that cache a deterministic highest relative level so the MPAM table can reference it without depending on CPU enumeration order. The sharing correction changes cache reporting rather than cache allocation or scheduling policy; allocation changes only when the end user enables arm64 MPAM. |
| MPAM resource control | `20070-resctrl-mpam-expose-proportional-bandwidth.patch` | 7.1 | Adds an explicit `mbw_prop` mount option to Linux's [arm64 MPAM](https://docs.kernel.org/arch/arm64/mpam.html) [resctrl interface](https://docs.kernel.org/filesystems/resctrl.html) for the DSU-120's work-conserving proportional-bandwidth control. The `MB_PROP` schema exposes the hardware's raw stride-minus-one values from 0 to 63; an ordinary resctrl mount remains unchanged. Non-zero values lower a group's relative bandwidth share under contention and produce a one-time warning because their performance effect is workload-dependent. |
| Thermal and cooling | `0042-thermal-set-thermal_zone-type-from-firmware-in-acpi_.patch`<br>`0060-acpi-thermal-bind-devfreq-cooling-devices-safely.patch`<br>`30090-scmi-hwmon-do-not-use-of-thermal-zones-on-acpi.patch`<br>`30127-acpi-thermal-filter-orion-o6-ectz-zero-readings.patch`<br>`30128-acpi-thermal-retain-downstream-improvements.patch`<br>`30129-thermal-cix-add-safe-ipa-support.patch` | All | Names thermal zones, retains SCMI sensors, rejects bogus EC readings, binds devfreq cooling safely, and supplies corrected CIX power allocation with a bounded standard-ACPI fallback. Missing optional CIX power metadata is reported at informational level; malformed metadata remains a warning. |
| Wake interrupts, DMA, and GPIO | `0012-irqchip-cix-sky1-pdc-add-audited-wake-domain.patch`<br>`0016-dma-arm-dma350-add-audited-cix-support.patch`<br>`0017-gpio-cadence-add-audited-cix-sky1-support.patch` | All | Adds the Sky1 wake controller, DMA350 operation, and ACPI-aware Cadence GPIO needed by board peripherals and suspend/resume. DMA1 accepts the native-firmware compatibility map or the standard table-upgrade `_DMA` range and fails safely rather than transferring through an unspecified address window. |
| Pinctrl | `00481-pinctrl-cix-Add-pin-controller-support-for-sky1.patch`<br>`00482-pinctrl-cix-sky1-Provide-pin-control-dummy-states.patch`<br>`00483-pinctrl-cix-Fix-obscure-dependency.patch`<br>`00484-pinctrl-cix-sky1-Unexport-sky1_pinctrl_pm_ops.patch`<br>`0048-pinctrl-sky1-add-audited-acpi-support.patch`<br>`40052-pinctrl-sky1-validate-o6-camera-mclk-duplication.patch` | `00481`-`00484`: 6.18 only; remainder: all | Provides Sky1 pin multiplexing and ACPI integration, including compatibility with the USB VBUS group names in released stock Radxa tables. Corrected table-upgrade profiles publish dedicated VBUS GPIO groups instead. A narrow compatibility patch removes pin 65 from the second camera group only when both groups contain the exact known O6/O6N MCLK tuple; unexpected firmware still fails visibly. The four 6.18 files backport prerequisites already present in 7.x. |
| I2C and SPI | `0019-i2c-cadence-add-audited-acpi-support.patch`<br>`50130-spi-cadence-add-audited-cix-acpi-support.patch` | All | Enables the Cadence I2C and classic SPI controllers from ACPI with validated firmware limits and correct clock/reset deferral. Linux 6.18.44 also exposes its new Sky1 16- and 32-bit classic-SPI transfers to the ACPI-described controller rather than only to the DT compatible. |
| USB and Type-C | `0024-phy-cix-add-audited-usbdp-combo-phy.patch`<br>`0025-usb-cdns3-add-audited-sky1-platform-support.patch`<br>`0026-usb-typec-rts5453-add-audited-driver.patch`<br>`0027-soc-cix-arbitrate-acpi-usb-models.patch`<br>`0029-usb-cdns3-propagate-role-pm-errors.patch` | All | Adds the CIXH2033 USB/DisplayPort combo PHY, Sky1 Cadence USB wrapper, and RTS5453 Type-C controller; gives each of the two O6 port functions of one RTS5453H its own handler on their shared interrupt line; selects safely between duplicate firmware models; and reports role/PM failures. RTS5453 cable orientation is passed through the Type-C switch to the CIXH2033 PHY; the fixed-host exception only avoids requiring an unused OTG role switch. The unrelated vendor PCIe, USB2, and USB3 PHY implementations remain excluded. Reorientation while the PHY is active is rejected; disconnect and reconnect the cable to change orientation. |
| PWM and backlight | `0028-pwm-add-pwm-support-for-CIX-SoC.patch`<br>`0044-pwm-sky1-harden-lifecycle-and-state-validation.patch`<br>`0067-backlight-pwm-add-safe-firmware-node-support.patch` | All | Supplies the CIX PWM controller and firmware-described display backlight with corrected clock lifetime and state validation. |
| PCIe and IOMMU | `00301-PCI-cadence-Add-module-support-for-platform-controll.patch`<br>`00302-PCI-cadence-Split-PCIe-controller-header-file.patch`<br>`00303-PCI-cadence-Move-PCIe-RP-common-functions-to-a-separ.patch`<br>`00304-PCI-cadence-Add-support-for-High-Perf-Architecture-H.patch`<br>`00305-PCI-sky1-Add-PCIe-host-support-for-CIX-Sky1.patch`<br>`00307-pci-sky1-fix-ecam-cleanup-on-probe-failure.patch`<br>`40046-acpi-demote-cix-sky1-ecam-duplicate-reservations.patch`<br>`40070-soc-cix-arbitrate-acpi-pcie-models.patch`<br>`40093-pci-cix-enable-root-port-io-window-assignment.patch`<br>`80070-pci-disable-aspm-for-sky1-smmu-faulting-endpoints.patch` | Listed `00301`-`00305` and `00307`: 6.18 only; remainder: all | Provides the Sky1 PCIe host where it is not yet upstream, avoids duplicate ACPI roots, enables endpoint I/O windows, and applies narrow endpoint ASPM compatibility where required. `40046` demotes only the exact CIX PNP0C02 ranges after verifying that their conflict is the already-owned PCI ECAM resource; native and replacement DSDTs retain those reservations so the windows remain represented in the ACPI namespace. |
| Linlon display and DisplayPort | `00100-drm-add-cix-linlon-dp-driver.patch`<br>`00101-drm-linlondp-merge-updates-from-26q2.patch`<br>`0043-DPTSW-19618-linlon-dp-Set-AFBC-32x8-to-the-highest-p.patch`<br>`1001-linlondp-fix-build-of-debugfs.patch`<br>`1002-linlondp-add-missing-headers.patch`<br>`1003-linlondp-add-api-fix-up-to-6.18.patch`<br>`1004-linlondp-disable-enable_render-by-default.patch`<br>`1005-linlondp-set-DRM_FBDEV_DMA_DRIVER_OPS-for-linlondp-kms-driver.patch`<br>`1006-drm-panel-add-fwnode_drm_find_panel.patch`<br>`1007-fix-26q2-linlondp-for-mainline.patch`<br>`1008-linlondp-add-api-fix-up-to-v7.1.patch`<br>`1009-linlondp-fix-WERROR.patch`<br>`70020-drm-cix-gate-virtual-encoder-build.patch`<br>`70030-drm-cix-dptx-make-extra-stream-clocks-optional.patch`<br>`70080-drm-cix-remove-unused-dptx-cadence-phy-kconfig.patch`<br>`70105-drm-cix-linlon-dp-tighten-private-include-flags.patch`<br>`70120-drm-cix-demote-internal-tbu-noop-logs.patch`<br>`70130-drm-cix-retain-safe-display-improvements.patch`<br>`70135-drm-cix-remove-unsafe-engineering-interfaces.patch`<br>`70140-drm-cix-fix-gcc15-clang21-w1-findings.patch`<br>`70150-drm-support-up-to-64-planes.patch`<br>`70160-drm-cix-dptx-fix-audio-eld-and-shutdown.patch` | All except `1008` and `70140`, which are 7.1 only | Adds the CIX Linlon display and DP stack, AFBC, panel and fbdev support; adapts it to current kernels and firmware; removes unsafe engineering interfaces; and completes the CIX 64-plane mask conversion. DPTX supplies the sink's ELD to ALSA so channel constraints reflect the connected display, and shutdown always disables its audio block even after unplug. Nested ACPI port/endpoint references are resolved by shared patch `0002`, and Linlon fails probe safely if firmware describes no pipeline component. When both the Trilin display and PWM backlight are modular, the display module asks the module loader to load `pwm_bl` first; device links and probe deferral remain the correctness mechanism. |
| Mali/Panthor GPU | `0011-drm-panthor-add-sky1-acpi-support.patch`<br>`70200-drm-panthor-declare-scmi-perf-softdep.patch` | All | Enables the Mali GPU from ACPI, powers it through the firmware-described `mali-supply`/`power-supply` ACPI PowerResource, and asks module loaders to load its SCMI performance provider first. This avoids a board-specific call to an unrelated PMMX domain. Linux respects each firmware table's `_CCA` coherency declaration instead of overriding it. |
| HDA and ASoC audio | `0013-sound-hda-cix-add-audited-sky1-support.patch`<br>`0022-sound-soc-add-cix-soc-support.patch`<br>`0071-DPTSW-26459-ALSA-hda-realtek-suppress-auto-mic-on-CI.patch`<br>`73050-sound-soc-cix-harden-audio-paths.patch` | All | Provides the Sky1 HDA controller and CIX ASoC/HDMI-DP paths, applies the board microphone quirk, and hardens DMA, PM, probe, and teardown. |
| HiFi5 XAF transport | `0009-remoteproc-cix-sky1-add-audited-hifi5-support.patch` | All | Adds an ACPI/DT remoteproc driver for `CIXH6000`, the guarded fixed 16 MiB `/dev/dma_heap/dsp` XAF heap, initialized DSP working memory, and mailbox-backed RPMsg notifications. The firmware ebuild installs CIX's [official XAF firmware package](https://archive.cixtech.com/debian/pool/main/c/cix-audio-dsp/cix-audio-dsp_2.0.0_arm64.deb). Loading the driver registers the remote processor but does not start it. The driver refuses to probe while any part of its fixed 34 MiB aperture remains System RAM. The built-in ownership hook automatically removes the complete aperture from allocatable RAM when necessary and is an informational no-op when firmware already reserves it; `cix_hifi5_legacy_reserve=0` disables this compatibility correction for diagnosis. On 64 KiB-page builds the general O6/O6N profile retains usable CMA capacity by selecting 128 MiB unless the user already chose a larger value. AP mappings follow CIX's write-combined contract, malformed firmware kicks are deferred safely from interrupt context, and fixed carveouts are recreated for every start. The transport does not itself provide an ALSA/SOF audio device. |
| HiFi5 SOF processing path | `0021-sound-soc-cix-sky1-add-audited-sof-support.patch`<br>`0023-sound-sof-clean-up-debugfs-lifetime.patch` | 7.1 only | Provides a separate ACPI-native SOF IPC3 owner with transactional clocks, resets, mailbox channels, SRAM, and fixed coherent-pool ownership. The ALSA, SOF core, codec-free machine and CIX platform components may all be modules; only the small early-reservation and coherent-pool broker remains built in. XAF and SOF remain compile-time alternatives because both target `CIXH6000` and the same DSP aperture; packaging the selected stack as modules does not make runtime switching safe. The firmware ebuild's `sof` USE flag installs CIX's [official SOF image and passthrough topology](https://archive.cixtech.com/debian/pool/main/c/cix-audio-sof/cix-audio-sof_2.0.0_arm64.deb) and derives a codec-free topology using the matching [SOF 2.11.2 topology sources](https://github.com/thesofproject/sof/tree/v2.11.2/tools/topology/topology1). It also builds a duplex `HiFi5 Loopback` PCM which sends host playback through a SOF volume component and returns the processed samples through host capture without depending on the unwired ALC1019/ALC5682 codecs. The kernel support includes the CIX I2SSC/I2SMC topology ABI, the vendor-selected compressed-offload surface, the protocol's fixed 4 KiB host-page encoding on large-page kernels, and safe SOF debugfs lifetime. Physical codec routing and system suspend are separate boundaries. Full DSDT table-upgrade metadata is mandatory, and stock or SSDT-only firmware profiles refuse the SOF selection cleanly. |
| MVX VPU | `70990-media-cix-import-and-integrate-mvx-vpu-driver.patch`<br>`71050-cix-mvx-enable-jpeg-mjpeg-devices.patch`<br>`71060-cix-mvx-port-sky1p-reset-sequencing.patch`<br>`71070-cix-mvx-set-scmi-perf-state-for-devfreq.patch`<br>`71080-cix-mvx-uplift-selected-2026q2-fixes.patch`<br>`71090-cix-mvx-uplift-p1-7.0-v1.0.2-core-fixes.patch`<br>`71100-cix-mvx-uplift-p1-7.0-v1.0.2-session-api.patch`<br>`71110-cix-mvx-fix-source-quality.patch`<br>`71120-cix-mvx-harden-dma-firmware-lifetime-and-devfreq.patch`<br>`71130-cix-mvx-remove-unsafe-kernel-buffer-dump.patch`<br>`71150-cix-mvx-fix-single-planar-dmabuf-capture.patch`<br>`71160-cix-mvx-harden-fault-and-lifecycle-recovery.patch` | Core, JPEG/reset, `71070`, and hardening files: all; `71080`, `71090`, and `71100`: 7.1 only | Provides video encode/decode and JPEG/MJPEG nodes, reset and devfreq integration, [newer public CIX fixes](https://github.com/cixtech/cix_opensource__vpu_driver/tree/p1_7.0_v1.0.2), and DMA, firmware, PM, and lifetime hardening. Devfreq changes the VPU SCMI performance domain and reports the provider-confirmed state instead of the runtime-gated APB clock. Policy selected while the VPU is runtime-suspended is queued through genpd and applied before the device resumes. A modular VPU requests its modular SCMI performance provider first, while provider-owned attachment references make unload ordering safe. Clock/reset probe deferral is preserved and reported at the appropriate level rather than as a permanent device error. `71150` preserves the descriptor and compacts firmware output that starts at a non-zero offset so the single-planar DMA-BUF encoder ABI can return a usable bitstream. `71160` rejects malformed host and firmware buffer ranges and guarantees cleanup of partial streams, asynchronous firmware failures and failed MMU allocations. The retained `71140` RRC-DQP artifact is not applied because the matched [official CIX Multimedia SDK](https://developer.cixtech.com/) exposes no consumer for its private ABI. |
| ArmChina NPU | `71500-misc-armchina-npu-import-sky1-driver.patch`<br>`71510-misc-armchina-npu-harden-raw-register-io.patch`<br>`71520-misc-armchina-npu-restrict-to-cix-sky1-v3.patch`<br>`71530-misc-armchina-npu-harden-ownership-and-domains.patch`<br>`71540-misc-armchina-npu-add-scmi-opp-devfreq.patch`<br>`71550-misc-armchina-npu-balance-runtime-pm.patch`<br>`71560-misc-armchina-npu-harden-userspace-abi-and-dma.patch`<br>`71570-misc-armchina-npu-harden-fault-teardown-and-source-quality.patch`<br>`71580-misc-armchina-npu-link-devfreq-providers.patch`<br>`71590-misc-armchina-npu-use-scmi-performance-states.patch`<br>`71600-misc-armchina-npu-add-version-matched-r2p0-backend.patch`<br>`71610-misc-armchina-npu-harden-descriptor-and-global-controls.patch`<br>`71620-misc-armchina-npu-fix-noncoherent-acpi-dma.patch`<br>`71630-misc-armchina-npu-limit-support-to-sky1-v3.patch`<br>`71640-misc-armchina-npu-restore-v3-iova-arenas.patch`<br>`71650-misc-armchina-npu-bind-owned-dma-bufs.patch`<br>`71660-misc-armchina-npu-bound-v3-coredump-lifecycle.patch`<br>`71670-misc-armchina-npu-bind-page-backed-dma-bufs.patch`<br>`71680-misc-armchina-npu-import-fragmented-dma-bufs.patch`<br>`71690-misc-armchina-npu-share-client-lifetime.patch` | All | Provides two separately selectable modules for the O6/O6N Sky1 V3 NPU, based on CIX's public [R2P1/P1](https://github.com/cixtech/cix_opensource__npu_driver/tree/p1_v2.0.0) and [R2P0](https://github.com/cixtech/cix_opensource__npu_driver/commit/3423c0463886d32bf3e0c55bf8528adcc9589c96) sources: the default R2P1 backend (`armchina_npu`) and an explicit-load, version-matched R2P0 backend (`armchina_npu_r2p0`). Both expose `/dev/aipu`, so unload one before loading the other. The series adds devfreq plus ownership, DMA, PM, fault and teardown hardening; validates the documented V3 descriptor envelope; and supports manager-5/V3 allocation modes 1--3, transactional REBIND, BIND for driver-owned and page-backed System-RAM exporters, fragmented imported DMA-BUFs through an owned device-visible IOVA, and bounded coredump recovery. DMA-only and peer-to-peer exporters remain unsupported for BIND. The retired numeric mode 4 has no O6/O6N consumer and is not implemented. The four-ASID allocator remains opt-in; ordinary inference uses the default allocation policy. |
| DDR low-power platform policy, ISP, and camera | `72000-media-cix-import-armcb-isp-driver.patch`<br>`72010-media-cix-harden-armcb-isp-platform-subdevices.patch`<br>`72015-media-cix-harden-armcb-isp-v4l2-streaming.patch`<br>`72020-media-cix-harden-armcb-isp-dma-legacy-abi.patch`<br>`72025-media-cix-coordinate-ddr-low-power-with-isp.patch` | All | `72025` provides a general Sky1 DDR low-power policy service, independently of whether the ISP is enabled. It exposes `firmware` and `performance` policies through `/sys/firmware/cix/ddr_low_power/policy`; the read-only `effective_policy` shows when a platform consumer temporarily requires performance. The board configuration helper selects the service as an O6/O6N platform driver and follows the requested built-in or module preference. The remaining files import the [public CIX ISP/camera driver](https://github.com/cixtech/cix_opensource__isp_driver/tree/p1_v2.0.0) and add platform, sensor/actuator, streaming, DMA, compatibility, PM, ownership, and teardown corrections. The V4L2 configuration device waits for the ISP-Mem resource provider instead of registering a partial camera interface while its clocks, resets, or reserved memory are unavailable. Concurrent camera streams hold balanced performance inhibitors, and the final stream restores the selected DDR policy. Merely loading either driver does not change DDR state, and firmware without the optional SiP service retains the camera path. |
| Wi-Fi, Bluetooth, and Ethernet | `80000-pci-rtl8126-disable-unreadable-vpd-quietly.patch`<br>`80010-rtw89-disable-hw-rfkill-polling-on-orion-o6.patch`<br>`80015-bluetooth-btrtl-return-register-read-error.patch`<br>`80020-rtw89-check-acpi-dsm-before-evaluating.patch`<br>`80025-cadence-macb-add-sky1-firmware-matches.patch`<br>`80030-net-realtek-import-r8126-driver.patch`<br>`80031-net-realtek-r8126-prefer-performance-core-irqs.patch`<br>`80032-net-realtek-r8126-remove-vendor-engineering-interfaces.patch`<br>`80035-net-realtek-r8126-demote-routine-reset-message.patch` | All | Retains the Realtek RTL8126 5GbE driver used on O6, based on Realtek 10.016.00 ([OpenWrt source mirror](https://github.com/openwrt/rtl8126/tree/10.016.00)), with shutdown, S0 magic-packet Wake-on-LAN, RSS, missing-object, DMA-mapping, and compiler-warning corrections. R8126 and r8169 are mutually exclusive because both claim the RTL8126 PCI ID. `80032` removes raw register, PCI, PHY and writable-EEPROM controls together with the procfs/sysfs test and cable-test implementation; ordinary networking, RSS, Wake-on-LAN, ethtool, and EEPROM identification/read support remain. `80035` treats the reset worker scheduled during every normal resume as debug output while retaining error-level reporting at the actual transmit-timeout call site. `80031` optionally prefers higher-capacity online CPUs for IRQ affinity and can be omitted without removing the driver. The remaining files suppress unreadable optional RTL8126 VPD only on exact O6/O6N system matches, avoid erroneous O6 Wi-Fi rfkill polling, validate Realtek ACPI calls, preserve Bluetooth errors, and enable Cadence MACB from firmware. O6N uses the in-tree r8169 profile. |
| Fan, watchdog, board profiles, and crash diagnostics | `50060-watchdog-sbsa-gwdt-use-cix-sky1-refresh-value.patch`<br>`90040-hwmon-cix-add-safe-acpi-fan-control.patch`<br>`90050-arm64-cix-add-radxa-orion-board-profiles.patch`<br>`90096-soc-cix-add-firmware-scratch-diagnostics.patch`<br>`90098-pstore-ramoops-parse-firmware-node-properties.patch` | All; `90050` requires the default `radxa-menu` USE flag | Corrects the watchdog period, exposes standard hwmon fan control, supplies O6/O6N configuration profiles, provides opt-in raw firmware diagnostics with explicitly provisional `assumed-*` reset labels, and enables ACPI-described ramoops crash logs. The ACPI profile keeps the Sky1 pinctrl provider built in so a built-in PL011 console does not defer until module loading. |

## Known limitations

- The NPU source is intentionally limited to the Sky1 Zhouyi V3 hardware used
  by O6/O6N. Matching R2P0 or R2P1 (CIX P1) userspace is still required. The
  later R2P2 schedule and buffer commands collide numerically with R2P1/P1
  despite having incompatible layouts, so R2P2 cannot be detected reliably and
  is not a supported userspace interface.
- CIX's public archive provides a version-matched 4.0.0
  [`cix-noe-umd`](https://archive.cixtech.com/debian/pool/main/c/cix-noe-umd/cix-noe-umd_4.0.0_arm64.deb)
  and
  [`cix-npu-umd`](https://archive.cixtech.com/debian/pool/main/c/cix-npu-umd/cix-npu-umd_4.0.0_arm64.deb)
  pair for R2P1, containing `/usr/share/cix/lib/libaipudrv.so.6.0.0`. Radxa's
  [`cix-npu-onnxruntime 1.2.0`](https://github.com/radxa-pkg/cix-prebuilt/releases/download/26Q2-2607/cix-npu-onnxruntime_1.2.0_arm64.deb)
  package contains an alternative `libaipu_driver.so`, but that object cannot
  be loaded by a 64 KiB-page kernel. Use the matched CIX packages for that
  configuration. R2P0 requires the matching 2.0.2 userspace from Radxa's
  [CIX NPU SDK bundle](https://docs.radxa.com/en/orion/o6n/app-development/artificial-intelligence/env-setup)
  and its `NOE_Engine` 2.0.0 Python wrapper.
  The `/usr/share/cix/lib` pathname identifies the file in CIX's package; it is
  not compiled into the kernel. NOE can load an installation elsewhere by
  setting `AIPU_LIB_PATH` to the exact object, or can find an unversioned
  `libaipudrv.so` through the normal dynamic-loader search path.
- The VPU and ISP/camera paths require matching firmware and userspace from the
  [CIX Multimedia SDK](https://developer.cixtech.com/); these are not bundled.
  Camera operation also requires suitable sensors, calibration, tuning, and
  board data.
- The pre-built packages contain kernel drivers, not the proprietary or
  open-source userspace needed to operate every accelerator.
- Radxa firmware 1.3 does not expose the firmware-1.2 PCIe SMMU topology. A
  kernel option cannot create a missing firmware IORT node.
- Alternative firmware may expose a different ACPI device model. Boot once
  with `acpi_table_upgrade=off` if its compatibility is not already known.
- On Linux 7.1, the O6/O6N firmware-1.2 full DSDT profile contains an MPAM
  table for DSU cache partitioning. The table is inert
  unless the end user enables `CONFIG_ARM64_MPAM` and `CONFIG_RESCTRL_FS`.
  The default resctrl mount exposes six cache portions. Mounting with
  `-o mbw_prop` additionally exposes the DSU's raw proportional-bandwidth
  stride control. Neither mode provides cache/bandwidth monitoring or
  CI-700/device-DMA partitioning. See the ACPI guide before enabling it.

## Recovering and reporting a problem

For an ACPI-related failure, first try a one-off boot with:

```text
acpi_table_upgrade=off
```

With [GNU GRUB](https://www.gnu.org/software/grub/manual/grub/html_node/Menu-entry-editor.html),
highlight the CIX kernel entry, press `e`, append the parameter to the line
beginning with `linux`, then press `Ctrl-x` or `F10` to boot without saving the
edit. Other bootloaders provide an equivalent temporary command-line edit. If
the system still fails, select the previously working kernel instead.

Individual AML files can also be excluded; see the ACPI guide. If the problem
persists without table upgrades, boot the known-good kernel and report:

- board model and RAM size;
- firmware vendor and exact version;
- full kernel package/artifact name;
- `generic` or `generic-64k` configuration;
- `uname -a`, `/proc/cmdline`, and the kernel configuration;
- complete `dmesg` from boot through the failure; and
- the device-specific state, such as `lspci -nnk`, media topology, thermal
  zones, or accelerator device nodes.

Do not reduce a report to the last error line: probe ordering and earlier
firmware messages are often the evidence needed to identify the real cause.

## Patch number ranges

The stable number identifies the same logical change across kernel lines even
when the source context differs.

| Range | Area |
| --- | --- |
| `0000`-`0999` | replacements at the corresponding CIX/vendor queue position |
| `10000`-`19999` | architecture, boot, and core diagnostics |
| `20000`-`29999` | CPU, Kconfig, compiler, and section lifetime |
| `30000`-`39999` | ACPI, firmware, SCMI, clocks, reset, and power policy |
| `40000`-`49999` | enumeration, resources, pinctrl, and firmware-model arbitration |
| `50000`-`59999` | focused driver integration and runtime corrections |
| `60000`-`69999` | USB, Type-C, and PHY integration |
| `70000`-`70989` | DRM, GPU, and display |
| `70990`-`71499` | CIX MVX VPU |
| `71500`-`71999` | ArmChina NPU |
| `72000`-`72999` | ISP and camera |
| `73000`-`73999` | HDA and ASoC audio |
| `80000`-`89999` | networking and PCIe policy |
| `90000`-`98999` | CIX SoC, board profiles, diagnostics, and platform hwmon |
| `99000`-`99999` | temporary or explicitly experimental; none are currently retained |

## Further information

- [`ACPI_TABLE_UPGRADE.md`](ACPI_TABLE_UPGRADE.md) explains the firmware table
  profiles, every AML payload, activation, and recovery controls.
