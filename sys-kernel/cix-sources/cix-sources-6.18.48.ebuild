# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="55"
#K_BASE_VER="${PV}"

K_SECURITY_UNSUPPORTED=1

##EXTRAVERSION="-${PN}/-*"
#K_NODRYRUN=1  # Fail early rather than trying -p0 to -p5, seems to fix unipatch()!
#K_NOSETEXTRAVERSION=1
#K_NOUSENAME=1
K_NOUSEPR=1

#K_EXP_GENPATCHES_NOUSE=1
K_DEBLOB_AVAILABLE=0

H_SUPPORTEDARCH="arm arm64"
#K_FROM_GIT=1

inherit kernel-2
detect_version
detect_arch

#ECLASS_DEBUG_OUTPUT="on"

EGIT_CIX_COMMIT="bc078a383042a6c14b05c56e12390e422f893088"

DESCRIPTION="CIX sources including the Gentoo, CIX and audited overlay patchsets for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
HOMEPAGE="https://github.com/cixtech/cix-linux-main/
	https://dev.gentoo.org/~alicef/genpatches"
SRC_URI="https://github.com/cixtech/cix-linux-main/archive/${EGIT_CIX_COMMIT}.tar.gz -> ${PN}-cix-${EGIT_CIX_COMMIT:0:7}.tar.gz
	${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}"
KEYWORDS="arm arm64"
IUSE="+acpi-table-upgrade +acpi-table-upgrade-dsdt +acpi-table-upgrade-iort-httu +acpi-table-upgrade-iort-msi experimental +radxa-menu"
REQUIRED_USE="
	acpi-table-upgrade-dsdt? ( acpi-table-upgrade )
	acpi-table-upgrade-iort-httu? ( acpi-table-upgrade )
	acpi-table-upgrade-iort-msi? ( acpi-table-upgrade )
"

COMMON_DEPEND="
	sys-libs/binutils-libs
	|| (
		~sys-kernel/cix-headers-${KV_MAJOR}.${KV_MINOR}
		~sys-kernel/linux-headers-${KV_MAJOR}.${KV_MINOR}
	)
"

BDEPEND="
	acpi-table-upgrade? (
		=dev-lang/python-3*
		>=sys-power/iasl-20241212
	)
"

PATCHES=(
	"${FILESDIR}"/linux-6.18-clk-composite-export-devm-pdata-helper.patch
	"${FILESDIR}"/linux-6.18-cifs-fix-softdep-declarations.patch
	"${FILESDIR}"/linux-6.18-rtc-efi-restore-verified-wakeup-alarm.patch
)

# Applied explicitly between vendor replacements and the post-vendor series.
# Do not use kernel-2's PATCHES variable, which would apply them a second time.
CIX_CORE_PATCHES=(
	"${FILESDIR}"/6.18.x/10000-arm64-stub-fdt.patch
	"${FILESDIR}"/10010-arm64-stub-fdt-enable-kexec-file.patch
	"${FILESDIR}"/10020-lld-timer-of-table-end-warning.patch
	"${FILESDIR}"/6.18.x/10050-bpf-gate-struct-ops-on-kallsyms.patch
	"${FILESDIR}"/10070-kconfig-separate-expert-and-debug-policy.patch
)

pkg_setup() {
	ewarn
	ewarn "${CATEGORY}/${PN} is *not* supported by the Gentoo Kernel Project in"
	ewarn "any way."
	ewarn "If you need support, please contact the Radxa/CIX developers"
	ewarn "directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn

	kernel-2_pkg_setup
}

src_prepare() {
	local pf=''
	local -a post_vendor_patches=()
	local cix_patch_dir="${WORKDIR}/cix-linux-main-${EGIT_CIX_COMMIT}/patches-6.18"

	(
		set -e

		cd "${WORKDIR}"
		unpack "${PN}-cix-${EGIT_CIX_COMMIT:0:7}.tar.gz"
	) || die

	cix_apply_patch() {
		local pf=$1

		case "${pf##*/}" in
			0001-mailbox-add-acpi-support-to-cix-mailbox-driver.patch)
				# Retain both firmware property encodings, propagate transfer
				# errors, balance module lifetime and avoid the SCMI shmem prefix.
				eapply "${FILESDIR}"/6.18.x/0001-mailbox-cix-add-audited-acpi-support.patch || die
				return
				;;
			0034-mailbox-cix-set-IRQF_NO_SUSPEND-for-STR.patch)
				# Forward-ported by the audited 0001 replacement.
				return
				;;
			0003-firmware-arm_scmi-add-acpi-support-to-SCMI.patch)
				# Replace the vendor SCMI fwnode conversion with balanced
				# mailbox, protocol-child, transport and shared-memory ownership.
				eapply "${FILESDIR}"/6.18.x/0003-firmware-arm-scmi-add-audited-acpi-support.patch || die
				return
				;;
			0002-acpi-Add-a-property-reference-count-interface.patch)
				# Resolve only deployed CIX graph tuples after the canonical ACPI
				# graph parser fails; do not alter generic reference parsing.
				eapply "${FILESDIR}"/6.18.x/0002-acpi-cix-resolve-legacy-graph-references.patch || die
				return
				;;
			0004-clk-clk-scmi-register-clkdev-for-acpi.patch)
				# Publish complete CIX ACPI SCMI clock maps with supplier lifetime
				# and CIX-scoped unused-clock handling.
				eapply "${FILESDIR}"/6.18.x/0004-clk-scmi-add-audited-acpi-publication.patch || die
				return
				;;
			0005-clk-add-cix-clk-driver.patch)
				# Consolidate CLKT/CLKA, AUDSS and the shared ACPI syscon provider
				# with failure-atomic publication, PM and ownership handling.
				eapply "${FILESDIR}"/6.18.x/0005-clk-cix-add-audited-sky1-support.patch || die
				return
				;;
			0006-reset-add-cix-reset-driver.patch)
				# Share overlapping system/AUDSS regmaps and validate every reset
				# operation, provider lifetime and ACPI/DT applicability path.
				eapply "${FILESDIR}"/6.18.x/0006-reset-cix-add-audited-sky1-support.patch || die
				return
				;;
			0007-soc-add-cix-acpi-resource-lookup-driver.patch)
				# Preserve the CIX firmware bridge with validated AML parsing,
				# balanced references and persistent namespace ownership. Resolve
				# named ACPI IRQs through the same lazy path as indexed lookups.
				eapply "${FILESDIR}"/6.18.x/0007-soc-cix-harden-acpi-resource-lookup-driver.patch || die
				return
				;;
			0008-pmdomain-add-acpi-support-to-cix-soc.patch)
				# Attach ACPI SCMI performance domains through an owned, exact
				# provider fwnode without leaking OF-only or early-init policy.
				eapply "${FILESDIR}"/6.18.x/0008-pmdomain-add-audited-acpi-scmi-support.patch || die
				return
				;;
			0041-pmdomain-fix-dev_pm_domain_attach_by_name-for-sky1-m.patch)
				# The audited 0008 replacement contains the scoped extra-domain
				# attachment model; the vendor name-based fix is superseded.
				return
				;;
			0015-mfd-syscon-add-acpi-support-for-cix-soc.patch|\
			0023-syscon-add-device_syscon_regmap_lookup_by_property.patch)
				# The audited provider and lookup helper are ordered and absorbed
				# into logical clock identity 0005.
				return
				;;
			0018-clk-clkdev-increase-clkdev-MAX_CON_ID-from-16-to-32.patch)
				# Preserve firmware connection names up to the validated 32-byte
				# CLKT/CLKA bound without changing the device-ID field.
				eapply "${FILESDIR}"/6.18.x/0018-clk-clkdev-increase-clkdev-MAX_CON_ID-from-16-to-32.patch || die
				return
				;;
			0025-usb-add-usb-cdns3-driver-for-cix-soc.patch)
				# Preserve the Sky1 wrapper and CDNSP platform path with per-device
				# state, balanced PHY/reset/clock ownership and retryable PM.
				eapply "${FILESDIR}"/6.18.x/0025-usb-cdns3-add-audited-sky1-platform-support.patch || die
				return
				;;
			0026-typec-add-rts5453-driver.patch)
				# Keep RTS5453 functionality behind public Type-C providers,
				# transactional routing and per-client shared IRQ ownership.
				eapply "${FILESDIR}"/6.18.x/0026-usb-typec-rts5453-add-audited-driver.patch || die
				return
				;;
			0027-soc-add-cix-acpi-usb-scan-handler.patch)
				# Prefer the generic PNP0D10 controller when firmware exposes
				# duplicate models, while preserving the non-overlapping role
				# companion and vendor-only firmware descriptions.
				eapply "${FILESDIR}"/6.18.x/0027-soc-cix-arbitrate-acpi-usb-models.patch || die
				return
				;;
			0029-usb-cdns3-fix-spin-lock-issue-in-suspend-resume.patch)
				# Keep sleepable resume outside the spinlock, propagate every role
				# and platform PM error, and leave failed recovery retryable.
				eapply "${FILESDIR}"/6.18.x/0029-usb-cdns3-propagate-role-pm-errors.patch || die
				return
				;;
			0054-usb-cdns3-fix-TypeC-hotplug-enumerati-on-failure.patch|\
			0061-DPTSW-24991-usb-fix-SError-during-poweroff-by-releas.patch|\
			0062-DPTSW-25423-usb-cdns3-sky1-disabled-IRQ-before-disab.patch|\
			0065-usb-cdns3-fix-cdnsp-timeout-at-resume.patch|\
			0068-DPTSW-26453-usb-cdns3-sky1-add-phy-dep-check-at-prob.patch)
				# Unsafe reset/unbind/IRQ workarounds are removed. The valid posted
				# write, restore and exact PHY-readiness concepts are in 0025.
				return
				;;
			00131-ALSA-hda-core-add-addr_offset-field-for-bus-address-.patch)
				# Consolidate the accepted HDA backports and CIX controller,
				# prefer standard firmware DMA ranges, and harden PM/ownership.
				eapply "${FILESDIR}"/6.18.x/0013-sound-hda-cix-add-audited-sky1-support.patch || die
				return
				;;
			00132-ALSA-hda-add-CIX-IPBLOQ-HDA-controller-support.patch|\
			00133-ALSA-hda-cix-ipbloq-Use-modern-PM-ops.patch|\
			00134-ALSA-hda-Remove-unnecessary-print-function-dev_err.patch|\
			00135-DPTSW-26459-sound-hda-rework-cix-ipbloq-based-on-mai.patch|\
			0014-kernel-dma-Export-dma_declare_coherent_memory-for-mo.patch)
				# Absorbed by 0013; the unreserved RSVL pool and its private
				# coherent-memory export are deliberately not retained.
				return
				;;
			0009-remoteproc-add-cix-dsp-remoteproc-driver.patch)
				# Replace the vendor fixed-memory transport with the audited
				# ACPI/DT owner adapted from the O6-qualified Linux 7.1 XAF path.
				eapply "${FILESDIR}"/6.18.x/0009-remoteproc-cix-sky1-add-audited-hifi5-support.patch || die
				return
				;;
			0020-firmware-add-cix-dsp-ipc-driver.patch|\
			0021-sound-soc-add-cix-sof-driver.patch)
				# The private IPC helper duplicates the standard RPMsg path. The
				# vendor SOF owner is DT-only and depends on that unsafe helper;
				# the separate ACPI HDMI/DP ASoC path remains supported.
				return
				;;
			0016-dma-arm-dma350-add-acpi-support-for-cix-soc.patch)
				# Replace the vendor driver with bounded command construction,
				# DMA-API-correct addressing and fail-safe channel ownership.
				eapply "${FILESDIR}"/6.18.x/0016-dma-arm-dma350-add-audited-cix-support.patch || die
				return
				;;
			0017-gpio-add-acpi-support-to-cadence-driver.patch)
				# Preserve generic Cadence behavior while bounding Sky1 banks,
				# serialising wake masks and making PM/SMC failures transactional.
				eapply "${FILESDIR}"/6.18.x/0017-gpio-cadence-add-audited-cix-sky1-support.patch || die
				return
				;;
			0019-i2c-add-acpi-support-for-cadence-driver.patch)
				# Retain CIX ACPI enumeration with firmware-neutral properties,
				# bounded clock/FIFO metadata and scoped clock-provider deferral.
				eapply "${FILESDIR}"/6.18.x/0019-i2c-cadence-add-audited-acpi-support.patch || die
				return
				;;
			0011-drm-panthor-add-acpi-support-for-cix-p1.patch)
				# Replace the vendor import at its stable logical position.
				eapply "${FILESDIR}"/6.18.x/0011-drm-panthor-add-sky1-acpi-support.patch || die
				return
				;;
			0038-gpu-panthor-fix-suspend-resume-for-sky1.patch|\
			0040-panthor-set-DPM_FLAG_NO_DIRECT_COMPLETE-for-STR-on-s.patch)
				# Absorbed into the audited 0011 and 70200 Panthor series.
				return
				;;
			0012-irqchip-add-cix-sky1-pdc-driver.patch)
				# Keep the firmware-backed wake domain, but bound it to the
				# TF-A SPI contract and remove the unused MMIO/global lifetime
				# model from the vendor implementation.
				eapply "${FILESDIR}"/6.18.x/0012-irqchip-cix-sky1-pdc-add-audited-wake-domain.patch || die
				return
				;;
			0024-phy-add-cix-phy-driver.patch)
				# Retain only the audited CIXH2033 USB/DisplayPort combo PHY.
				# The unrelated PCIe, USB2 and USB3 vendor PHYs remain deferred.
				eapply "${FILESDIR}"/6.18.x/0024-phy-cix-add-audited-usbdp-combo-phy.patch || die
				return
				;;
			0033-regulator-add-acpi-support.patch)
				# Quarantined as a family: the generic fwnode rewrite contains
				# null dereferences, reference leaks, unchecked allocations and
				# unsafe coupling/index handling.  Firmware retains rail state.
				return
				;;
			00485-pinctrl-sky1-add-acpi-support.patch)
				# Add bounded firmware group parsing and module-safe pin-group
				# publication without suppressing conflicting configurations.
				eapply "${FILESDIR}"/6.18.x/0048-pinctrl-sky1-add-audited-acpi-support.patch || die
				return
				;;
			0044-pwm-sky1-check-pwm-state-before-enable-disable-clk-i.patch)
				# Balance clock ownership independently from PWM output state and
				# validate every hardware-programming conversion and bound.
				eapply "${FILESDIR}"/6.18.x/0044-pwm-sky1-harden-lifecycle-and-state-validation.patch || die
				return
				;;
			0067-PROJ031-2-backlight-pwm-backlight-add-acpi-support-f.patch)
				# Keep firmware-node backlight parsing without raw ACPI notify
				# lifetime hazards or hard-coded brightness policy.
				eapply "${FILESDIR}"/6.18.x/0067-backlight-pwm-add-safe-firmware-node-support.patch || die
				return
				;;
			0060-ACPI-thermal-bind-devfreq-cooling-devices-via-devfre.patch)
				# Preserve ACPI devfreq cooling discovery without exposing or
				# guessing the private devfreq-cooling implementation layout.
				eapply "${FILESDIR}"/6.18.x/0060-acpi-thermal-bind-devfreq-cooling-devices-safely.patch || die
				return
				;;
			00306-disable-acpi-pcie-devices.patch)
				# Skip the duplicate disable policy, then retain the upstream
				# ECAM cleanup at its lexical 00307 queue position.
				eapply "${FILESDIR}"/6.18.x/00307-pci-sky1-fix-ecam-cleanup-on-probe-failure.patch || die
				return
				;;
			0030-disable-acpi-pcie-devices.patch|\
			0031-add-cix-vendor-pci-driver.patch|\
			0032-pci-cadence-sky1-cix-fix-sky1-cix-vendor-pcie-driver.patch|\
			0035-pci-cadence-sky1-fix-clk-under-ACPI.patch|\
			0037-arm-smmu-v3-add-suspend-resume-support.patch|\
			0039-pci-cadence-add-PCI_SKY1_HOST_CIX-for-bsp-driver.patch|\
			0045-clocksource-add-sky1-gpt-timer-driver.patch|\
			0046-tty-amba-pl011-use-driver-from-cix-bsp.patch|\
			0047-drm-cix-fix-hdmi-str.patch|\
			0049-add-hym8563-rx8900-rtc-driver.patch|\
			0050-arm64-add-model-name-for-Cix-Sky1-Soc.patch|\
			0051-add-cix-thermal-ipa-driver.patch|\
			0052-add-thermal-IPA-support.patch|\
			0053-DPTSW-25537-drm-cix-dptx-HPD-fast-replug-link-train-.patch|\
			0055-watchdog-sbsa-Update-the-value-of-the-refresh-regist.patch|\
			0057-dptx-check-null-pointer-in-trilin_dp_panel_hw_cfg.patch|\
			0059-optee-check-system_state-when-probing-at-shutdown.patch|\
			0063-DPTSW-16421-thermal-Register-the-GPU-Energy-Model-us.patch|\
			0064-thermal-ipa-enhance-ipa.patch|\
			0066-add-cix_dst-driver.patch|\
			0070-DPTSW-26437-iommu-arm-smmu-v3-fix-IRQ-setup-on-resum.patch)
				# Retain the upstream Sky1 host and exclude unsafe vendor-only
				# PCIe/DST/thermal code, global SMMU suspend and CPU-info
				# rewrites, unsupported DP-to-HDMI glue, the unsafe GPT
				# clocksource, wholesale PL011 rollback and RX8900 RTC import,
				# the system-wide OP-TEE
				# shutdown probe guard, and the unused SCMI EM helper.
				return
				;;
		esac

		eapply "${pf}" || die
	}

	for pf in "${cix_patch_dir}"/*.patch; do
		cix_apply_patch "${pf}"
	done
	rm -r "${WORKDIR}/cix-linux-main-${EGIT_CIX_COMMIT}" || die

	# Apply the local architecture/core series after direct replacements so
	# local logical numbers remain monotonic. These patches have no vendor
	# preimage dependency; 10010 deliberately follows its 10000 base.
	for pf in "${CIX_CORE_PATCHES[@]}"; do
		eapply "${pf}" || die
	done

	# The post-vendor overlay series is authoritative and numerically ordered.
	post_vendor_patches=(
		"${FILESDIR}"/20050-topology-has-missing-cpufreq-ref.patch
		"${FILESDIR}"/20060-acpi-processor-clarify-ignore-ppc-module-parameter.patch
		"${FILESDIR}"/6.18.x/20065-cacheinfo-share-global-firmware-ids-across-levels.patch
		"${FILESDIR}"/30030-scmi-demote-unsupported-fastchannel-fallback.patch
		"${FILESDIR}"/30090-scmi-hwmon-do-not-use-of-thermal-zones-on-acpi.patch
		"${FILESDIR}"/30125-acpi-table-upgrade-add-disable-and-exclude-options.patch
		"${FILESDIR}"/6.18.x/30127-acpi-thermal-filter-orion-o6-ectz-zero-readings.patch
		"${FILESDIR}"/6.18.x/30128-acpi-thermal-retain-downstream-improvements.patch
		"${FILESDIR}"/6.18.x/30129-thermal-cix-add-safe-ipa-support.patch
		"${FILESDIR}"/30130-acpi-scope-cix-scmi-sta-quirk.patch
		"${FILESDIR}"/30195-firmware-arm-scmi-use-rational-perf-frequency-conversion.patch
		"${FILESDIR}"/30196-power-opp-accept-acpi-only-configurations.patch
		"${FILESDIR}"/6.18.x/30200-pmdomain-read-provider-performance-state.patch
		"${FILESDIR}"/6.18.x/40042-platform-acpi-resolve-named-irq-resources.patch
		# CIX-QUESTIONED-PATCH: stock-firmware log demotion; upgraded DSDTs remove the duplicate.
		"${FILESDIR}"/6.18.x/40046-acpi-demote-cix-sky1-ecam-duplicate-reservations.patch
		"${FILESDIR}"/6.18.x/40052-pinctrl-sky1-validate-o6-camera-mclk-duplication.patch
		"${FILESDIR}"/40055-gpio-pinctrl-enforce-sky1-pad-ownership.patch
		"${FILESDIR}"/40056-soc-cix-add-safe-bus-performance-domain-driver.patch
		"${FILESDIR}"/6.18.x/40070-soc-cix-arbitrate-acpi-pcie-models.patch
		"${FILESDIR}"/40093-pci-cix-enable-root-port-io-window-assignment.patch
		"${FILESDIR}"/50030-net-bridge-warn-for-missing-netfilter-on-first-device.patch
		"${FILESDIR}"/6.18.x/50060-watchdog-sbsa-gwdt-use-cix-sky1-refresh-value.patch
		"${FILESDIR}"/6.18.x/50130-spi-cadence-add-audited-cix-acpi-support.patch
		"${FILESDIR}"/6.18.x/60010-usb-cdns3-sky1-declare-phy-dependency.patch
		"${FILESDIR}"/6.18.x/70020-drm-cix-gate-virtual-encoder-build.patch
		# CIX-QUESTIONED-PATCH: optional extra DPTX stream-clock policy.
		"${FILESDIR}"/70030-drm-cix-dptx-make-extra-stream-clocks-optional.patch
		"${FILESDIR}"/70080-drm-cix-remove-unused-dptx-cadence-phy-kconfig.patch
		"${FILESDIR}"/70105-drm-cix-linlon-dp-tighten-private-include-flags.patch
		"${FILESDIR}"/70120-drm-cix-demote-internal-tbu-noop-logs.patch
		"${FILESDIR}"/6.18.x/70130-drm-cix-retain-safe-display-improvements.patch
		"${FILESDIR}"/6.18.x/70135-drm-cix-remove-unsafe-engineering-interfaces.patch
		"${FILESDIR}"/6.18.x/70140-drm-cix-fix-gcc15-clang21-w1-findings.patch
		"${FILESDIR}"/6.18.x/70150-drm-support-up-to-64-planes.patch
		"${FILESDIR}"/70160-drm-cix-dptx-fix-audio-eld-and-shutdown.patch
		"${FILESDIR}"/70170-drm-cix-linlon-propagate-aclk-errors.patch
		"${FILESDIR}"/70180-drm-cix-dptx-propagate-reset-lookup-errors.patch
		"${FILESDIR}"/70190-drm-cix-dptx-fix-aux-retry-accounting.patch
		"${FILESDIR}"/70195-drm-cix-dptx-fix-mst-lock-leaks.patch
		"${FILESDIR}"/6.18.x/70200-drm-panthor-declare-scmi-perf-softdep.patch
		"${FILESDIR}"/6.18.x/70990-media-cix-import-and-integrate-mvx-vpu-driver.patch
		"${FILESDIR}"/71050-cix-mvx-enable-jpeg-mjpeg-devices.patch
		"${FILESDIR}"/71060-cix-mvx-port-sky1p-reset-sequencing.patch
		"${FILESDIR}"/71070-cix-mvx-set-scmi-perf-state-for-devfreq.patch
		"${FILESDIR}"/6.18.x/71110-cix-mvx-fix-source-quality.patch
		"${FILESDIR}"/6.18.x/71120-cix-mvx-harden-dma-firmware-lifetime-and-devfreq.patch
		"${FILESDIR}"/6.18.x/71130-cix-mvx-remove-unsafe-kernel-buffer-dump.patch
		"${FILESDIR}"/6.18.x/71150-cix-mvx-fix-single-planar-dmabuf-capture.patch
		"${FILESDIR}"/6.18.x/71160-cix-mvx-harden-fault-and-lifecycle-recovery.patch
		"${FILESDIR}"/6.18.x/71500-misc-armchina-npu-import-sky1-driver.patch
		"${FILESDIR}"/6.18.x/71510-misc-armchina-npu-harden-raw-register-io.patch
		"${FILESDIR}"/71520-misc-armchina-npu-restrict-to-cix-sky1-v3.patch
		"${FILESDIR}"/6.18.x/71530-misc-armchina-npu-harden-ownership-and-domains.patch
		"${FILESDIR}"/6.18.x/71540-misc-armchina-npu-add-scmi-opp-devfreq.patch
		"${FILESDIR}"/6.18.x/71550-misc-armchina-npu-balance-runtime-pm.patch
		"${FILESDIR}"/6.18.x/71560-misc-armchina-npu-harden-userspace-abi-and-dma.patch
		"${FILESDIR}"/6.18.x/71570-misc-armchina-npu-harden-fault-teardown-and-source-quality.patch
		"${FILESDIR}"/6.18.x/71580-misc-armchina-npu-link-devfreq-providers.patch
		"${FILESDIR}"/71590-misc-armchina-npu-use-scmi-performance-states.patch
		"${FILESDIR}"/71600-misc-armchina-npu-add-version-matched-r2p0-backend.patch
		"${FILESDIR}"/71610-misc-armchina-npu-harden-descriptor-and-global-controls.patch
		"${FILESDIR}"/71620-misc-armchina-npu-fix-noncoherent-acpi-dma.patch
		"${FILESDIR}"/71630-misc-armchina-npu-limit-support-to-sky1-v3.patch
		"${FILESDIR}"/71640-misc-armchina-npu-restore-v3-iova-arenas.patch
		"${FILESDIR}"/71650-misc-armchina-npu-bind-owned-dma-bufs.patch
		"${FILESDIR}"/71660-misc-armchina-npu-bound-v3-coredump-lifecycle.patch
		"${FILESDIR}"/71670-misc-armchina-npu-bind-page-backed-dma-bufs.patch
		"${FILESDIR}"/71680-misc-armchina-npu-import-fragmented-dma-bufs.patch
		"${FILESDIR}"/71690-misc-armchina-npu-share-client-lifetime.patch
		"${FILESDIR}"/6.18.x/72000-media-cix-import-armcb-isp-driver.patch
		"${FILESDIR}"/6.18.x/72010-media-cix-harden-armcb-isp-platform-subdevices.patch
		"${FILESDIR}"/6.18.x/72015-media-cix-harden-armcb-isp-v4l2-streaming.patch
		"${FILESDIR}"/6.18.x/72020-media-cix-harden-armcb-isp-dma-legacy-abi.patch
		"${FILESDIR}"/6.18.x/72025-media-cix-coordinate-ddr-low-power-with-isp.patch
		"${FILESDIR}"/6.18.x/73050-sound-soc-cix-harden-audio-paths.patch
		"${FILESDIR}"/6.18.x/73060-sound-cix-declare-runtime-provider-dependencies.patch
		"${FILESDIR}"/80000-pci-rtl8126-disable-unreadable-vpd-quietly.patch
		"${FILESDIR}"/80010-rtw89-disable-hw-rfkill-polling-on-orion-o6.patch
		"${FILESDIR}"/6.18.x/80015-bluetooth-btrtl-return-register-read-error.patch
		"${FILESDIR}"/6.18.x/80020-rtw89-check-acpi-dsm-before-evaluating.patch
		"${FILESDIR}"/6.18.x/80025-cadence-macb-add-sky1-firmware-matches.patch
		"${FILESDIR}"/6.18.x/80030-net-realtek-import-r8126-driver.patch
		# CIX-QUESTIONED-PATCH: comment this entry to omit the CPU-affinity policy.
		"${FILESDIR}"/80031-net-realtek-r8126-prefer-performance-core-irqs.patch
		"${FILESDIR}"/80032-net-realtek-r8126-remove-vendor-engineering-interfaces.patch
		"${FILESDIR}"/80033-net-realtek-r8126-remove-unused-tail-pointer-reader.patch
		"${FILESDIR}"/80035-net-realtek-r8126-demote-routine-reset-message.patch
		"${FILESDIR}"/6.18.x/80070-pci-disable-aspm-for-sky1-smmu-faulting-endpoints.patch
		"${FILESDIR}"/6.18.x/90040-hwmon-cix-add-safe-acpi-fan-control.patch
		"${FILESDIR}"/6.18.x/90045-cix-close-platform-driver-dependencies.patch
	)
	rm -f "${T}/cix-dptx-extra-stream-clock-policy" || die
	for pf in "${post_vendor_patches[@]}"; do
		eapply "${pf}" || die
		case ${pf##*/} in
			70030-*) : > "${T}/cix-dptx-extra-stream-clock-policy" || die ;;
		esac
	done
	if use radxa-menu; then
		eapply "${FILESDIR}"/6.18.x/90050-arm64-cix-add-radxa-orion-board-profiles.patch || die
		eapply "${FILESDIR}"/6.18.x/90060-arm64-cix-model-orion-acpi-infrastructure.patch || die
	fi
	eapply \
		"${FILESDIR}"/90096-soc-cix-add-firmware-scratch-diagnostics.patch \
		"${FILESDIR}"/6.18.x/90098-pstore-ramoops-parse-firmware-node-properties.patch || die

	kernel-2_src_prepare
}

_src_compile_asl() {
	local file="${1:-}"
	local dest="${2:-}"
	local prefix=''

	[[ -s "${file:-}" ]] ||
		die "_src_compile_asl() called on unreadable/empty file '${file:-}'"

	[[ -n "${dest:-}" ]] ||
		die "_src_compile_asl() called without destination directory"

	[[ -e "${dest}" && ! -d "${dest}" ]] &&
		die "_src_compile_asl() called invalid destination directory '${dest}'"

	case "$( basename "${file}" | sed 's/\.asl//' )" in
		'sky1-audio-dma-clock-name')
			prefix='S1DMACLK'
			;;
		'sky1-audio-dma-api')
			prefix='S1AUD'
			;;
		'sky1-audss-dma-range')
			prefix='S1DMAR'
			;;
		'orion-o6-cppc-reference-performance')
			prefix='O6CPPC'
			;;
		'orion-o6-dsu-pmu')
			prefix='O6DSUP'
			;;
		'orion-o6-busperf')
			prefix='O6BPERF'
			;;
		'orion-o6-rts5453-shared-irq')
			prefix='O6RTS'
			;;
		'orion-o6-scmi-mailbox-window')
			prefix='O6SCMI'
			;;
		'orion-o6-ectz-critical-trip')
			prefix='O6ECTZ'
			;;
		'orion-o6-gpu-average-critical-trip')
			prefix='O6GCRT'
			;;
		'orion-o6-reboot-reason')
			prefix='O6RBRR'
			;;
		'orion-o6-thermal-sensors')
			prefix='O6TZSNS'
			;;
		'orion-o6n-cppc-reference-performance')
			prefix='O6NCPPC'
			;;
		'orion-o6n-dsu-pmu')
			prefix='O6NDSUP'
			;;
		'orion-o6n-busperf')
			prefix='O6NBPERF'
			;;
		'orion-o6n-reboot-reason')
			prefix='O6NRBRR'
			;;
		'orion-o6n-scmi-mailbox-window')
			prefix='O6NSCMI'
			;;
		'PPTT')
			prefix='PPTT'
			;;
		'DSDT')
			prefix='DSDT'
			;;
		'ORIONO6')
			prefix='ORIONO6'
			;;
		*)
			die "_src_compile_asl() called with unknown file '${file:-}'"
			;;
	esac

	[[ ! -e "${dest}/${prefix}.aml" ]] ||
		die "duplicate ACPI output '${prefix}.aml' while compiling '${file}'"

	(
		set -e

		mkdir -p "${dest}" && cd "${dest}"

		iasl -p "${prefix}" -tc "${file}"
	) || die "'iasl' failed to compile '${file}' (${prefix}): ${?}"
}

_src_compile_iort() {
	local src="${1:-}"
	local dest="${2:-}"
	local -a args=()

	[[ -s "${src}/iort/IORT.dat" ]] ||
		die "_src_compile_iort() called without source IORT.dat"

	use acpi-table-upgrade-iort-httu && args+=( '--httu' )
	use acpi-table-upgrade-iort-msi && args+=( '--msi' )
	[[ ${#args[@]} -gt 0 ]] || return 0
	[[ ! -e "${dest}/IORT.aml" ]] ||
		die "duplicate ACPI output 'IORT.aml' while compiling '${src}'"

	mkdir -p "${dest}" || die
	python3 "${src}/iort/build_iort_upgrade.py" "${args[@]}" \
		"${src}/iort/IORT.dat" "${dest}/IORT.aml" ||
		die "failed to build IORT table-upgrade payload"
}

_cix_acpi_has_dsdt_profile() {
	local board="${1:-}"
	local firmware="${2:-}"

	[[ -d "${FILESDIR}/acpi-table-upgrade/${board}/${firmware}/dsdt" ]]
}

_cix_acpi_write_initramfs_list() {
	local profile_root="${1:-}"
	local list_file="${2:-}"
	local installed_root="${3:-}"
	local file='' rel=''

	[[ -d "${profile_root}/kernel/firmware/acpi" ]] ||
		die "missing ACPI table-upgrade profile directory '${profile_root}'"

	mkdir -p "$( dirname "${list_file}" )" || die
	{
		echo 'dir /dev 0755 0 0'
		echo 'nod /dev/console 0600 0 0 c 5 1'
		echo 'dir /root 0700 0 0'
		echo 'dir /kernel 0755 0 0'
		echo 'dir /kernel/firmware 0755 0 0'
		echo 'dir /kernel/firmware/acpi 0755 0 0'

		for file in "${profile_root}"/kernel/firmware/acpi/*.aml; do
			[[ -e "${file:-}" ]] ||
				die "no AML files found in" \
					"'${profile_root}/kernel/firmware/acpi/'"

			rel="${file#"${profile_root}/"}"

			printf 'file /kernel/firmware/acpi/%s %s/%s 0644 0 0\n' \
				"$( basename "${file}" )" \
				"${installed_root%/}" \
				"${rel}"
		done
	} > "${list_file}" ||
		die "failed to create '${list_file}': ${?}"
}

src_compile() {
	if use acpi-table-upgrade; then
		local acpi_src="${FILESDIR}/acpi-table-upgrade"
		local dst="${T}/cix-acpi-table-upgrade"
		local kernel_dir="/usr/src/linux-${CKV}-cix"
		local board='' board_dst='' file='' firmware='' profile='' scope='' source_type=''
		local -a boards=( 'o6' 'o6n' )
		local -a firmware_profiles=( '1.2' '1.3' )
		local -a profiles=()
		local -a source_dirs=()

		if [[ "${PR:-"r0"}" != 'r0' ]]; then
			kernel_dir="${kernel_dir}-${PR}"
		fi

		for board in "${boards[@]}"; do
			for firmware in "${firmware_profiles[@]}"; do
				board_dst="${dst}/${board}/${firmware}"
				profiles=( 'initramfs' )
				source_dirs=(
					"${acpi_src}/shared/shared"
					"${acpi_src}/shared/${firmware}"
					"${acpi_src}/${board}/shared"
					"${acpi_src}/${board}/${firmware}"
				)

				# Compose shared-to-specific SSDT overlays for this board/profile.
				for scope in "${source_dirs[@]}"; do
					[[ -d "${scope}/ssdt" ]] || continue
					for file in "${scope}"/ssdt/*.asl; do
						[[ -e "${file:-}" ]] || continue
						_src_compile_asl "${file}" \
							"${board_dst}/initramfs/kernel/firmware/acpi"
					done
				done

				if use acpi-table-upgrade-dsdt && _cix_acpi_has_dsdt_profile "${board}" "${firmware}"; then
					mkdir -p "${board_dst}/initramfs-dsdt/kernel/firmware/acpi" || die
					cp "${board_dst}"/initramfs/kernel/firmware/acpi/*.aml \
						"${board_dst}"/initramfs-dsdt/kernel/firmware/acpi

					# Whole-table replacements remain opt-in with the full profile.
					for scope in "${source_dirs[@]}"; do
						for source_type in pptt dsdt ssdt-replacement; do
							[[ -d "${scope}/${source_type}" ]] || continue
							for file in "${scope}/${source_type}"/*.asl; do
								[[ -e "${file:-}" ]] || continue
								_src_compile_asl "${file}" \
									"${board_dst}/initramfs-dsdt/kernel/firmware/acpi"
							done
						done

						if [[ -d "${scope}/iort" ]]; then
							_src_compile_iort "${scope}" \
								"${board_dst}/initramfs-dsdt/kernel/firmware/acpi"
						fi
					done
					profiles+=( 'initramfs-dsdt' )
				fi

				for profile in "${profiles[@]}"; do
					_cix_acpi_write_initramfs_list \
						"${board_dst}/${profile}" \
						"${dst}/${board}/${firmware}/${profile}.list" \
						"${kernel_dir%/}/cix-acpi-table-upgrade/${board}/${firmware}/${profile}"
				done
			done
		done

		# Compatibility aliases: historical board profile paths select firmware 1.2.
		profiles=( 'initramfs' )
		if use acpi-table-upgrade-dsdt; then
			profiles+=( 'initramfs-dsdt' )
		fi
		for board in "${boards[@]}"; do
			for profile in "${profiles[@]}"; do
				cp -a "${dst}/${board}/1.2/${profile}" "${dst}/${board}/${profile}" || die
				_cix_acpi_write_initramfs_list \
					"${dst}/${board}/${profile}" \
					"${dst}/${board}/${profile}.list" \
					"${kernel_dir%/}/cix-acpi-table-upgrade/${board}/${profile}"
			done
		done

		# Compatibility aliases: the historical top-level profile paths select O6 firmware 1.2.
		for profile in "${profiles[@]}"; do
			cp -a "${dst}/o6/1.2/${profile}" "${dst}/${profile}" || die
			_cix_acpi_write_initramfs_list \
				"${dst}/${profile}" \
				"${dst}/${profile}.list" \
				"${kernel_dir%/}/cix-acpi-table-upgrade/${profile}"
		done
	fi
}

src_install() {
	local acpi_src="${FILESDIR}/acpi-table-upgrade"
	local kernel_dir="/usr/src/linux-${CKV}-cix"
	local board='' firmware='' policy_marker='' profile=''
	local -a boards=( 'o6' 'o6n' )
	local -a firmware_profiles=( '1.2' '1.3' )
	local -a profiles=( 'initramfs' )

	kernel-2_src_install

	# e.g. linux-7.0.9 -> linux-7.0.9-cix-r1
	if [[ "${PR:-"r0"}" != 'r0' ]]; then
		kernel_dir="${kernel_dir}-${PR}"
	fi
	mv "${ED}/usr/src/linux-${CKV}" "${ED%"/"}/${kernel_dir#"/"}" || die

	# Preserve the applied questioned-policy selection in source and binpkgs.
	insinto "${kernel_dir}/cix-patch-policy"
	for policy_marker in cix-dptx-extra-stream-clock-policy; do
		if [[ -e ${T}/${policy_marker} ]]; then
			doins "${T}/${policy_marker}"
		fi
	done

	if use acpi-table-upgrade; then
		insinto "${kernel_dir}/cix-acpi-table-upgrade"
		doins "${FILESDIR}/ACPI_TABLE_UPGRADE.md"

		# Install the source taxonomy exactly as compiled: shared/shared,
		# shared/firmware, board/shared, and board/firmware scopes.
		insinto "${kernel_dir}/cix-acpi-table-upgrade/source"
		doins -r "${acpi_src}"/*

		for board in "${boards[@]}"; do
			for firmware in "${firmware_profiles[@]}"; do
				profiles=( 'initramfs' )
				if use acpi-table-upgrade-dsdt && _cix_acpi_has_dsdt_profile "${board}" "${firmware}"; then
					profiles+=( 'initramfs-dsdt' )
				fi

				for profile in "${profiles[@]}"; do
					insinto "${kernel_dir}/cix-acpi-table-upgrade/${board}/${firmware}"
					doins "${T}/cix-acpi-table-upgrade/${board}/${firmware}/${profile}.list"

					insinto "${kernel_dir}/cix-acpi-table-upgrade/${board}/${firmware}/${profile}/kernel/firmware/acpi"
					doins "${T}/cix-acpi-table-upgrade/${board}/${firmware}/${profile}/kernel/firmware/acpi"/*.aml
				done
			done
		done

		profiles=( 'initramfs' )
		if use acpi-table-upgrade-dsdt; then
			profiles+=( 'initramfs-dsdt' )
		fi
		for board in "${boards[@]}"; do
			for profile in "${profiles[@]}"; do
				insinto "${kernel_dir}/cix-acpi-table-upgrade/${board}"
				doins "${T}/cix-acpi-table-upgrade/${board}/${profile}.list"

				insinto "${kernel_dir}/cix-acpi-table-upgrade/${board}/${profile}/kernel/firmware/acpi"
				doins "${T}/cix-acpi-table-upgrade/${board}/${profile}/kernel/firmware/acpi"/*.aml
			done
		done

		# Compatibility aliases: the historical top-level profile paths select O6 firmware 1.2.
		for profile in "${profiles[@]}"; do
			insinto "${kernel_dir}/cix-acpi-table-upgrade"
			doins "${T}/cix-acpi-table-upgrade/${profile}.list"

			insinto "${kernel_dir}/cix-acpi-table-upgrade/${profile}/kernel/firmware/acpi"
			doins "${T}/cix-acpi-table-upgrade/${profile}/kernel/firmware/acpi"/*.aml
		done
	fi
}

pkg_postinst() {
	kernel-2_pkg_postinst

	elog "The ArmChina NPU has separate R2P1 (armchina_npu) and R2P0"
	elog "(armchina_npu_r2p0) modules. Stop users and unload one before"
	elog "loading the other; both expose /dev/aipu. R2P2 is unsupported."
	elog "Maintained board profiles enable only the Sky1 Zhouyi V3 NPU and"
	elog "CIX ISP operation. Unsupported NPU architecture and SoC sources"
	elog "are not carried; R2P1 user-directed fixed-IOVA and BIND/REBIND remain"
	elog "rejected. Accelerator workloads still need"
	elog "qualification on the intended hardware and userspace stack."

	if use acpi-table-upgrade; then
		local linux_dir="linux-${PV%_p*}-cix"
		local selected_profile='initramfs'

		if [[ "${PR:-"r0"}" != 'r0' ]]; then
			linux_dir="linux-${PV%_p*}-cix-${PR}"
		fi
		if use acpi-table-upgrade-dsdt; then
			selected_profile='initramfs-dsdt'
		fi

		elog
		elog "ACPI table-upgrade sources and compiled AML profiles were"
		elog "installed under /usr/src/${linux_dir}/cix-acpi-table-upgrade."
		elog
		elog "Firmware-specific board initramfs source lists are installed at:"
		elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/o6/1.2/${selected_profile}.list"
		elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/o6n/1.2/${selected_profile}.list"
		elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/o6/1.3/${selected_profile}.list"
		elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/o6n/1.3/initramfs.list"
		elog
		if use acpi-table-upgrade-dsdt; then
			elog "The O6 1.3 firmware profile includes an O6 DSDT list;"
			elog "O6N 1.3 remains SSDT-only until an O6N 1.3 DSDT"
			elog "is qualified."
			elog
		fi
		elog "The unversioned board-specific list paths are retained as"
		elog "firmware 1.2 aliases."
		elog "The historical top-level list paths are retained as O6"
		elog "firmware 1.2 aliases."
		elog
		elog "To build them into the kernel, enable the built-in initramfs"
		elog "ACPI override options and set CONFIG_INITRAMFS_SOURCE to one"
		elog "of the firmware-specific board lists, for example:"
		elog "  /usr/src/linux/cix-acpi-table-upgrade/o6/1.2/${selected_profile}.list"
		elog "  /usr/src/linux/cix-acpi-table-upgrade/o6/1.3/${selected_profile}.list"
		elog "Keep /usr/src/linux pointing at this source tree before building."
	fi

	if use symlink; then
		if [[ "${PR:-"r0"}" != 'r0' ]]; then
			ln -snf "linux-${PV%_p*}-cix-${PR}" "${EROOT}"/usr/src/linux || die
		else
			ln -snf "linux-${PV%_p*}-cix" "${EROOT}"/usr/src/linux || die
		fi
	fi
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
