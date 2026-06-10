# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KV_MINOR=11
EGIT_CIX_COMMIT="3aad82491a599648d87ba1c47cec7968862fa165"
EGIT_SKY1_COMMIT="57e018a398248d7e5e4d798610df79a557c0629f"

ETYPE="headers"
H_SUPPORTEDARCH="arm arm64"
inherit kernel-2
detect_version
detect_arch

#ECLASS_DEBUG_OUTPUT="on"

PATCH_PV=${PV} # to ease testing new versions against not existing patches
#PATCH_VER="1"
PATCH_DEV="sam"
SRC_URI="
	${KERNEL_URI}
	https://github.com/cixtech/cix-linux-main/archive/${EGIT_CIX_COMMIT}.tar.gz -> cix-sources-cix-${EGIT_CIX_COMMIT:0:7}.tar.gz
	https://github.com/Sky1-Linux/linux-sky1/archive/${EGIT_SKY1_COMMIT}.tar.gz -> cix-sources-sky1-${EGIT_SKY1_COMMIT:0:7}.tar.gz
	${PATCH_VER:+https://dev.gentoo.org/~${PATCH_DEV}/distfiles/sys-kernel/linux-headers/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}
"
S="${WORKDIR}/linux-${PV}"

KEYWORDS="~arm ~arm64"

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl
"
RDEPEND="
	!sys-kernel/linux-headers
"

src_unpack() {
	# Avoid kernel-2_src_unpack
	default
}

src_prepare() {
	local pf=''
	local cix_patch_dir="${WORKDIR}/cix-linux-main-${EGIT_CIX_COMMIT}/patches-7.0"
	local sky1_patch_dir="${WORKDIR}/linux-sky1-${EGIT_SKY1_COMMIT}/patches-rc"
	local -a PATCHES=()

	[[ -n "${PATCH_VER}" ]] && PATCHES+=( "${WORKDIR}/${PATCH_PV}" )

	# TODO: May need forward porting to newer versions
	use elibc_musl && PATCHES+=(
		"${FILESDIR}"/5.15-remove-inclusion-sysinfo.h.patch
	)

	#PATCHES+=(
	#	"${FILESDIR}"/7.0.x/10000-7.0.9-arm64-stub-fdt.patch
	#	"${FILESDIR}"/10010-arm64-stub-fdt-enable-kexec-file.patch
	#	"${FILESDIR}"/10020-lld-timer-of-table-end-warning.patch
	#	"${FILESDIR}"/80000-rtl8126-disable-vpd.patch
	#	"${FILESDIR}"/80070-pci-disable-aspm-for-sky1-smmu-faulting-endpoints.patch
	#)

	#(
	#	set -e

	#	cd "${WORKDIR}"
	#	unpack "cix-sources-cix-${EGIT_CIX_COMMIT:0:7}.tar.gz"
	#	unpack "cix-sources-sky1-${EGIT_SKY1_COMMIT:0:7}.tar.gz"
	#) || die

	#for pf in "${PATCHES[@]}"; do
	#	eapply "${pf}" || die
	#done

	#for pf in "${cix_patch_dir}"/*.patch; do
	#	eapply "${pf}" || die
	#done

	## These Sky1 patches are additive on top of CIX's native 7.0 queue.
	#eapply "${sky1_patch_dir}"/0007-pinctrl-cix-Update-Sky1-pin-controller.patch || die
	#eapply "${sky1_patch_dir}"/0013-net-Add-CIX-Sky1-networking-drivers.patch || die
	#eapply "${FILESDIR}"/80060-realtek-r8125-r8126-use-kernel-dma-mapping-error.patch || die
	#eapply "${sky1_patch_dir}"/0015-media-cix-Add-Sky1-video-codec-VPU-driver.patch || die
	#eapply "${sky1_patch_dir}"/0016-misc-armchina-npu-Add-Zhouyi-NPU-driver-for-CIX-Sky1.patch || die
	#eapply "${FILESDIR}"/7.0.x/50000-7.0-iommu-arm-smmu-v3-add-acpi-boot-active-bypass-stes-for-cix-sky1-pcie.patch || die
	#eapply "${FILESDIR}"/7.0.x/70000-7.0-drm-add-sky1-drm-render-node-bridge-for-cix-sky1-soc.patch || die
	#eapply "${sky1_patch_dir}"/0024-drm-sky1-switch-from-faux_device-to-platform_device.patch || die
	#eapply "${sky1_patch_dir}"/0025-mm-add-Mali-GPU-movable_ops-page-type-support.patch || die

	#rm -r "${WORKDIR}/cix-linux-main-${EGIT_CIX_COMMIT}" || die
	#rm -r "${WORKDIR}/linux-sky1-${EGIT_SKY1_COMMIT}" || die

	#eapply "${FILESDIR}"/7.0.x/20010-7.0-cix-fix-deps-section-mismatch-and-clang-uninit-build-fail.patch || die
	#eapply "${FILESDIR}"/70010-drm-cix-dptx-fix-clang-werror-in-component-bypass-builds.patch || die
	#eapply "${FILESDIR}"/72000-armchina-npu-zhouyi-fix-missing-prototype-under-werror.patch || die
	#eapply "${FILESDIR}"/72010-armchina-npu-fix-acpi-match-and-user-visible-text.patch || die
	#eapply "${FILESDIR}"/72020-armchina-npu-fix-runtime-pm-put-build.patch || die
	#eapply "${FILESDIR}"/7.0.x/72025-7.0-armchina-npu-defer-until-perf-domain-ready.patch || die
	#eapply "${FILESDIR}"/7.0.x/30000-7.0-pmdomain-fix-acpi-scmi-perf-domain-wiring.patch || die
	#eapply "${FILESDIR}"/7.0.x/30015-7.0-pmdomain-export-genpd-dev-pm-attach-by-name.patch || die
	#eapply "${FILESDIR}"/30030-scmi-demote-unsupported-fastchannel-fallback.patch || die
	#eapply "${FILESDIR}"/30070-opp-tolerate-unsupported-interconnect-paths.patch || die
	#eapply "${FILESDIR}"/30080-opp-suppress-unsupported-interconnect-warning.patch || die
	#eapply "${FILESDIR}"/7.0.x/72030-7.0-armchina-npu-clean-up-acpi-core-runtime-pm-on-defer.patch || die
	#eapply "${FILESDIR}"/7.0.x/72040-7.0-armchina-npu-guard-missing-iova-cookie.patch || die
	#eapply "${FILESDIR}"/7.0.x/72050-7.0-armchina-npu-prefer-dma-api-on-acpi.patch || die
	#eapply "${FILESDIR}"/7.0.x/72055-7.0-armchina-npu-clarify-acpi-dma-api-memory-management-log.patch || die
	#eapply "${FILESDIR}"/7.0.x/72060-7.0-armchina-npu-drop-invalid-oneshot-irq-flag.patch || die
	#eapply "${FILESDIR}"/72070-armchina-npu-add-acpi-resume-complete-hook.patch || die
	#eapply "${FILESDIR}"/72080-armchina-npu-harden-probe-and-runtime-pm-error-handling.patch || die
	#eapply "${FILESDIR}"/72090-armchina-npu-clean-up-dmabuf-sg-mappings.patch || die
	#eapply "${FILESDIR}"/72095-armchina-npu-defer-dmabuf-backing-free-to-release.patch || die
	#eapply "${FILESDIR}"/20030-gpio-cadence-fix-pm-ops-when-pm-sleep-is-disabled.patch || die
	#eapply "${FILESDIR}"/20040-cpufreq-fall-back-to-policy-max-for-fast-switch-sca.patch || die
	#eapply "${FILESDIR}"/20050-topology-has-missing-cpufreq-ref.patch || die
	#eapply "${FILESDIR}"/30090-scmi-hwmon-do-not-use-of-thermal-zones-on-acpi.patch || die
	#eapply "${FILESDIR}"/30125-acpi-table-upgrade-add-disable-and-exclude-options.patch || die
	#eapply "${FILESDIR}"/30127-acpi-thermal-filter-orion-o6-ectz-zero-readings.patch || die
	#eapply "${FILESDIR}"/80010-rtw89-disable-hw-rfkill-polling-on-orion-o6.patch || die
	#eapply "${FILESDIR}"/7.0.x/80020-7.0-rtw89-check-acpi-dsm-before-evaluating.patch || die
	#eapply "${FILESDIR}"/60000-cix-usb-phy-fail-cleanly-on-missing-resources.patch || die
	#eapply "${FILESDIR}"/10030-build-modpost-report-all-unresolved-symbols.patch || die
	#eapply "${FILESDIR}"/7.0.x/10040-7.0-bpf-guard-session-return-btf-id.patch || die
	#eapply "${FILESDIR}"/71000-cix-mvx-build-and-api-fixes.patch || die
	#eapply "${FILESDIR}"/7.0.x/71010-7.0-cix-mvx-declare-v4l2-vb2-dependencies.patch || die
	#eapply "${FILESDIR}"/7.0.x/71020-7.0-cix-mvx-fix-nested-comment-warning.patch || die
	#eapply "${FILESDIR}"/71030-cix-mvx-respect-in-tree-kconfig.patch || die
	#eapply "${FILESDIR}"/71040-cix-mvx-fix-user-visible-names.patch || die
	#eapply "${FILESDIR}"/71050-cix-mvx-enable-jpeg-mjpeg-devices.patch || die
	#eapply "${FILESDIR}"/71060-cix-mvx-port-sky1p-reset-sequencing.patch || die
	#eapply "${FILESDIR}"/70020-cix-display-and-backlight-build-fixes.patch || die
	#eapply "${FILESDIR}"/70030-drm-cix-dptx-make-extra-stream-clocks-optional.patch || die
	#eapply "${FILESDIR}"/7.0.x/70040-7.0-drm-panthor-drop-unused-gem-device-variable.patch || die
	#eapply "${FILESDIR}"/70050-drm-cix-enable-acpi-stub-fdt-display.patch || die
	#eapply "${FILESDIR}"/70060-drm-add-fwnode-panel-bridge-helpers.patch || die
	#eapply "${FILESDIR}"/70070-drm-cix-use-fwnode-display-links.patch || die
	#eapply "${FILESDIR}"/70080-drm-cix-remove-unused-dptx-cadence-phy-kconfig.patch || die
	#eapply "${FILESDIR}"/70090-drm-cix-remove-unused-display-kconfig-prompts.patch || die
	#eapply "${FILESDIR}"/7.0.x/70100-7.0-drm-cix-linlon-dp-fix-clang-warnings.patch || die
	#eapply "${FILESDIR}"/7.0.x/70110-7.0-drm-cix-demote-display-info-logs.patch || die
	#eapply "${FILESDIR}"/70120-drm-cix-demote-internal-tbu-noop-logs.patch || die
	#eapply "${FILESDIR}"/80030-cadence-macb-restore-pc302gem-config-scope.patch || die
	#eapply "${FILESDIR}"/80040-cadence-macb-use-sky1-acpi-aclk-as-hclk.patch || die
	#eapply "${FILESDIR}"/40045-pnp-system-demote-pci-ecam-duplicate-reservations.patch || die
	#eapply "${FILESDIR}"/7.0.x/40046-7.0-acpi-scan-demote-pci-ecam-duplicate-reservations.patch || die
	#eapply "${FILESDIR}"/40093-pci-cix-enable-root-port-io-window-assignment.patch || die
	#eapply "${FILESDIR}"/7.0.x/40050-7.0-soc-cix-arbitrate-acpi-usb-models.patch || die
	#eapply "${FILESDIR}"/7.0.x/40060-7.0-soc-cix-add-gpu-cca-scan-quirk.patch || die
	#eapply "${FILESDIR}"/7.0.x/40070-7.0-soc-cix-arbitrate-acpi-pcie-models.patch || die
	#eapply "${FILESDIR}"/7.0.x/40080-7.0-soc-cix-ignore-disabled-acpi-models.patch || die
	#eapply "${FILESDIR}"/60095-soc-cix-keep-usbdp-phy-with-pnp0d10.patch || die
	#eapply "${FILESDIR}"/7.0.x/90000-7.0-soc-cix-add-acpi-bus-perf-driver.patch || die
	#eapply "${FILESDIR}"/7.0.x/90010-7.0-cix-sky1-acpi-socinfo-nvmem-ddrlp-ipa.patch || die
	#eapply "${FILESDIR}"/7.0.x/90020-7.0-cix-fix-module-modpost-exports.patch || die
	#eapply "${FILESDIR}"/7.0.x/90030-7.0-cix-cpu-ipa-use-dtb-register-size.patch || die
	#eapply "${FILESDIR}"/7.0.x/90040-7.0-soc-cix-expose-raw-sky1-socinfo-fields.patch || die
	#eapply "${FILESDIR}"/90045-soc-cix-align-sky1-socinfo-opn-decode-with-bsp.patch || die
	#eapply "${FILESDIR}"/7.0.x/90092-7.0-hwmon-cix-add-acpi-fan-driver.patch || die
	#eapply "${FILESDIR}"/90096-soc-cix-add-sky1-reboot-reason-driver.patch || die
	#eapply "${FILESDIR}"/7.0.x/90098-7.0-pstore-ramoops-parse-firmware-node-properties.patch || die
	#eapply "${FILESDIR}"/7.0.x/60010-7.0-usb-cdnsp-sky1-fix-acpi-fwnode-and-pm-paths.patch || die
	#eapply "${FILESDIR}"/7.0.x/60020-7.0-usb-typec-rts5453-include-irq-header.patch || die
	#eapply "${FILESDIR}"/7.0.x/60030-7.0-usb-typec-rts5453-fix-pm-sleep-disabled-build.patch || die
	#eapply "${FILESDIR}"/7.0.x/60040-7.0-phy-cix-enable-acpi-stub-fdt.patch || die
	#eapply "${FILESDIR}"/7.0.x/60050-7.0-usb-typec-rts5453-select-sky1-gpio-irq-provider.patch || die
	#eapply "${FILESDIR}"/7.0.x/60060-7.0-usb-typec-rts5453-stop-permanent-defer.patch || die
	#eapply "${FILESDIR}"/60070-usb-typec-add-provider-fwnode-control-lookups.patch || die
	#eapply "${FILESDIR}"/60120-usb-typec-rts5453-clean-up-acpi-usbdp-integration.patch || die
	#eapply "${FILESDIR}"/7.0.x/30110-7.0.9-cix-acpi-ids-and-clkt-consumer-fixes.patch || die
	#eapply "${FILESDIR}"/30130-acpi-scope-cix-scmi-sta-quirk.patch || die
	#eapply "${FILESDIR}"/30140-clk-sky1-acpi-fail-incomplete-clkt-maps.patch || die
	#eapply "${FILESDIR}"/30150-firmware-arm-scmi-balance-acpi-shmem-fwnode.patch || die
	#eapply "${FILESDIR}"/7.0.x/30160-7.0-scmi-handle-acpi-debugfs-fallbacks.patch || die
	#eapply "${FILESDIR}"/7.0.x/30170-7.0-clk-sky1-acpi-select-cix-mailbox-for-scmi.patch || die
	#eapply "${FILESDIR}"/30180-mailbox-cix-avoid-sky1-scmi-shmem-overlap.patch || die
	#eapply "${FILESDIR}"/30190-clk-scmi-keep-acpi-clocks-enabled.patch || die
	#eapply "${FILESDIR}"/30195-firmware-arm-scmi-use-rational-perf-frequency-conversion.patch || die
	#eapply "${FILESDIR}"/7.0.x/73000-7.0-cix-hda-require-cadence-gpio-on-acpi-systems.patch || die
	#eapply "${FILESDIR}"/7.0.x/73010-7.0-cix-hda-prefer-acpi-dma-ranges-and-harden-probe.patch || die
	#eapply "${FILESDIR}"/7.0.x/50010-7.0-gpio-cadence-restore-match-data-and-skip-init.patch || die
	#eapply "${FILESDIR}"/7.0.x/50020-7.0-irqchip-sky1-pdc-fix-acpi-ioremap-error-path.patch || die
	#eapply "${FILESDIR}"/7.0.x/50030-7.0-mfd-syscon-fix-fwnode-property-lookup-lifetime.patch || die
	#eapply "${FILESDIR}"/50040-pwm-sky1-fix-kconfig-entry.patch || die
	#eapply "${FILESDIR}"/7.0.x/50045-7.0-soc-cix-require-dev-id-for-reset-lookups.patch || die
	#eapply "${FILESDIR}"/7.0.x/50050-7.0-edac-a72-skip-of-cpu-scan-under-acpi.patch || die
	#eapply "${FILESDIR}"/80050-pci-rtl8126-disable-vpd-quietly.patch || die
	#eapply "${FILESDIR}"/7.0.x/50060-7.0-watchdog-sbsa-gwdt-use-control-frame-ping-on-cix-sky1.patch || die
	#eapply "${FILESDIR}"/7.0.x/50070-7.0-dma-arm-dma350-skip-of-reserved-memory-under-acpi.patch || die
	#eapply "${FILESDIR}"/7.0.x/50080-7.0-dma-arm-dma350-skip-unsafe-remote-acpi-probe.patch || die
	#eapply "${FILESDIR}"/50090-dma-coherent-keep-declared-memory-write-combined.patch || die
	#eapply "${FILESDIR}"/80075-pci-strengthen-sky1-aspm-disable-for-faulting-endpoints.patch || die
	#eapply "${FILESDIR}"/80080-cix-sky1-declare-module-softdeps.patch || die

	# Avoid kernel-2_src_prepare
	default
}

src_install() {
	kernel-2_src_install

	find "${ED}" \( -name '.install' -o -name '*.cmd' \) -delete || die
	# Delete empty directories
	find "${ED}" -empty -type d -delete || die
}
