# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="5"
K_NO_VERSION_CHECK="True"
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

EGIT_CIX_COMMIT="759efc09237e7728e2881b3f6083fd80b3106ae3"
EGIT_SKY1_COMMIT="57e018a398248d7e5e4d798610df79a557c0629f"
VENDOR_FIRMWARE_O6="orion-o6-radxa-1.2.1"
VENDOR_FIRMWARE_O6N="orion-o6n-radxa-1.2.1"

DESCRIPTION="CIX sources including the Gentoo, CIX, Entropi and custom patchsets for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
HOMEPAGE="https://github.com/cixtech/cix-linux-main/
	https://github.com/Sky1-Linux/linux-sky1/
	https://dev.gentoo.org/~alicef/genpatches"
SRC_URI="https://github.com/cixtech/cix-linux-main/archive/${EGIT_CIX_COMMIT}.tar.gz -> ${PN}-cix-${EGIT_CIX_COMMIT:0:7}.tar.gz
	https://github.com/Sky1-Linux/linux-sky1/archive/${EGIT_SKY1_COMMIT}.tar.gz -> ${PN}-sky1-${EGIT_SKY1_COMMIT:0:7}.tar.gz
	${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}"
KEYWORDS="arm arm64"
IUSE="+acpi-table-upgrade +acpi-table-upgrade-dsdt +acpi-table-upgrade-iort-httu +acpi-table-upgrade-iort-msi experimental +radxa-menu"
REQUIRED_USE="
	acpi-table-upgrade-dsdt? ( acpi-table-upgrade )
	acpi-table-upgrade-iort-httu? ( acpi-table-upgrade )
	acpi-table-upgrade-iort-msi? ( acpi-table-upgrade )
"
RESTRICT="binchecks"

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
	"${FILESDIR}"/7.1.x/10000-arm64-stub-fdt.patch
	"${FILESDIR}"/10010-arm64-stub-fdt-enable-kexec-file.patch
	"${FILESDIR}"/10020-lld-timer-of-table-end-warning.patch
	"${FILESDIR}"/80000-rtl8126-disable-vpd.patch
	"${FILESDIR}"/80070-pci-disable-aspm-for-sky1-smmu-faulting-endpoints.patch
)

QA_PREBUILT="usr/src/linux-*/tools/testing/selftests/tc-testing/action-ebpf"

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
	local cix_patch_dir="${WORKDIR}/cix-linux-main-${EGIT_CIX_COMMIT}/patches-7.0"
	local sky1_patch_dir="${WORKDIR}/linux-sky1-${EGIT_SKY1_COMMIT}/patches-rc"

	(
		set -e

		cd "${WORKDIR}"
		unpack "${PN}-cix-${EGIT_CIX_COMMIT:0:7}.tar.gz"
		unpack "${PN}-sky1-${EGIT_SKY1_COMMIT:0:7}.tar.gz"
	) || die

	for pf in "${PATCHES[@]}"; do
		eapply "${pf}" || die
	done

	for pf in "${cix_patch_dir}"/*.patch; do
		case "$( basename "${pf}" )" in
			'0005-clk-add-cix-clk-driver.patch')
				eapply "${FILESDIR}"/7.1.x/0005-cix-clk-add-cix-clk-driver.patch || die
				;;
			'0006-reset-add-cix-reset-driver.patch')
				eapply "${FILESDIR}"/7.1.x/0006-cix-reset-add-cix-reset-driver.patch || die
				eapply "${FILESDIR}"/7.1.x/0007-reset-core-drop-unused-optional-local.patch || die
				;;
			'0008-pmdomain-add-acpi-support-to-cix-soc.patch')
				eapply "${FILESDIR}"/7.1.x/0008-cix-pmdomain-add-acpi-support-to-cix-soc.patch || die
				;;
			'0011-drm-panthor-add-acpi-support-for-cix-p1.patch')
				eapply "${FILESDIR}"/7.1.x/0011-cix-drm-panthor-add-acpi-support-for-cix-p1.patch || die
				;;
			'0024-phy-add-cix-phy-driver.patch')
				eapply "${FILESDIR}"/7.1.x/0024-cix-phy-add-cix-phy-driver.patch || die
				;;
			'0033-regulator-add-acpi-support.patch')
				eapply "${FILESDIR}"/7.1.x/0033-cix-regulator-add-acpi-support.patch || die
				eapply "${FILESDIR}"/7.1.x/0034-regulator-fwnode-fix-coupled-count-error-check.patch || die
				eapply "${FILESDIR}"/7.1.x/0035-regulator-core-brace-acpi-coupling-check.patch || die
				eapply "${FILESDIR}"/7.1.x/0036-regulator-fwnode-drop-unused-supply-helper.patch || die
				;;
			'0034-mailbox-cix-set-IRQF_NO_SUSPEND-for-STR.patch')
				# Already present in the 7.1 CIX mailbox source after the preceding queue.
				;;
			'0046-tty-amba-pl011-use-driver-from-cix-bsp.patch')
				eapply "${FILESDIR}"/7.1.x/0046-cix-tty-amba-pl011-use-driver-from-cix-bsp.patch || die
				;;
			'0048-pinctrl-sky1-add-acpi-support.patch')
				eapply "${FILESDIR}"/7.1.x/0048-cix-pinctrl-sky1-add-acpi-support.patch || die
				;;
			*)
				eapply "${pf}" || die
				;;
		esac
	done

	eapply "${FILESDIR}"/7.1.x/0047-tty-amba-pl011-drop-stale-console-line-ended-write.patch || die

	# These Sky1 patches are additive on top of CIX's native 7.0 queue.
	# Sky1 0007 is superseded by CIX 0048 on the updated CIX 759efc0 base.
	eapply "${sky1_patch_dir}"/0013-net-Add-CIX-Sky1-networking-drivers.patch || die
	eapply "${FILESDIR}"/80060-realtek-r8125-r8126-use-kernel-dma-mapping-error.patch || die
	eapply "${sky1_patch_dir}"/0015-media-cix-Add-Sky1-video-codec-VPU-driver.patch || die
	eapply "${sky1_patch_dir}"/0016-misc-armchina-npu-Add-Zhouyi-NPU-driver-for-CIX-Sky1.patch || die
	eapply "${FILESDIR}"/7.0.x/71990-armchina-npu-update-to-cix-opensource-driver-abi.patch || die
	eapply "${FILESDIR}"/71992-armchina-npu-use-gpio-consumer-prototypes.patch || die
	eapply "${FILESDIR}"/71995-armchina-npu-restore-local-acpi-dma-lifetime-fixes.patch || die
	eapply "${FILESDIR}"/71996-armchina-npu-define-kmd-version.patch || die
	eapply "${FILESDIR}"/71997-armchina-npu-link-sky1-soc-glue.patch || die
	eapply "${FILESDIR}"/71998-armchina-npu-use-mainline-scmi-opp-devfreq.patch || die
	eapply "${FILESDIR}"/71998-armchina-npu-balance-acpi-core-runtime-pm.patch || die
	eapply "${FILESDIR}"/71999-armchina-npu-add-sky1-priv-init-prototype.patch || die
	eapply "${FILESDIR}"/7.0.x/50000-iommu-arm-smmu-v3-add-acpi-boot-active-bypass-stes-for-cix-sky1-pcie.patch || die
	eapply "${FILESDIR}"/7.0.x/70000-drm-add-sky1-drm-render-node-bridge-for-cix-sky1-soc.patch || die
	# Sky1 0024 targets an older faux_device display bridge path absent after the updated 7.1 CIX stack.
	eapply "${sky1_patch_dir}"/0025-mm-add-Mali-GPU-movable_ops-page-type-support.patch || die

	rm -r "${WORKDIR}/cix-linux-main-${EGIT_CIX_COMMIT}" || die
	rm -r "${WORKDIR}/linux-sky1-${EGIT_SKY1_COMMIT}" || die

	eapply "${FILESDIR}"/7.0.x/20010-cix-fix-deps-section-mismatch-and-clang-uninit-build-fail.patch || die
	eapply "${FILESDIR}"/7.0.x/70010-cix-759efc0-drm-cix-dptx-fix-clang-werror-in-component-bypass-builds.patch || die
	eapply "${FILESDIR}"/7.1.x/70011-drm-cix-dptx-drop-unused-match-data-local.patch || die
	eapply "${FILESDIR}"/7.0.x/30000-cix-759efc0-pmdomain-fix-acpi-scmi-perf-domain-wiring.patch || die
	eapply "${FILESDIR}"/7.0.x/30015-cix-759efc0-pmdomain-export-genpd-dev-pm-attach-by-name.patch || die
	eapply "${FILESDIR}"/30030-scmi-demote-unsupported-fastchannel-fallback.patch || die
	eapply "${FILESDIR}"/30070-opp-tolerate-unsupported-interconnect-paths.patch || die
	eapply "${FILESDIR}"/30080-opp-suppress-unsupported-interconnect-warning.patch || die
	eapply "${FILESDIR}"/20030-gpio-cadence-fix-pm-ops-when-pm-sleep-is-disabled.patch || die
	eapply "${FILESDIR}"/20040-cpufreq-fall-back-to-policy-max-for-fast-switch-sca.patch || die
	eapply "${FILESDIR}"/20050-topology-has-missing-cpufreq-ref.patch || die
	eapply "${FILESDIR}"/20060-acpi-processor-clarify-ignore-ppc-module-parameter.patch || die
	eapply "${FILESDIR}"/30090-scmi-hwmon-do-not-use-of-thermal-zones-on-acpi.patch || die
	eapply "${FILESDIR}"/30125-acpi-table-upgrade-add-disable-and-exclude-options.patch || die
	eapply "${FILESDIR}"/7.1.x/30127-acpi-thermal-filter-orion-o6-ectz-zero-readings.patch || die
	eapply "${FILESDIR}"/80010-rtw89-disable-hw-rfkill-polling-on-orion-o6.patch || die
	eapply "${FILESDIR}"/7.0.x/80020-rtw89-check-acpi-dsm-before-evaluating.patch || die
	eapply "${FILESDIR}"/60000-cix-usb-phy-fail-cleanly-on-missing-resources.patch || die
	eapply "${FILESDIR}"/10030-build-modpost-report-all-unresolved-symbols.patch || die
	# 7.1 no longer has the bpf_session_is_return BTF ID target guarded by the 7.0 patch.
	eapply "${FILESDIR}"/71000-cix-mvx-build-and-api-fixes.patch || die
	eapply "${FILESDIR}"/7.0.x/71010-cix-mvx-declare-v4l2-vb2-dependencies.patch || die
	eapply "${FILESDIR}"/7.0.x/71020-cix-mvx-fix-nested-comment-warning.patch || die
	eapply "${FILESDIR}"/71030-cix-mvx-respect-in-tree-kconfig.patch || die
	eapply "${FILESDIR}"/71040-cix-mvx-fix-user-visible-names.patch || die
	eapply "${FILESDIR}"/71050-cix-mvx-enable-jpeg-mjpeg-devices.patch || die
	eapply "${FILESDIR}"/71060-cix-mvx-port-sky1p-reset-sequencing.patch || die
	eapply "${FILESDIR}"/7.1.x/71070-cix-mvx-set-scmi-perf-state-for-devfreq.patch || die
	eapply "${FILESDIR}"/7.1.x/71080-cix-mvx-uplift-selected-2026q2-fixes.patch || die
	eapply "${FILESDIR}"/7.1.x/72000-media-cix-add-armcb-isp-acpi-driver.patch || die
	eapply "${FILESDIR}"/7.1.x/72010-media-cix-armcb-isp-drop-obsolete-of-gpio-include.patch || die
	eapply "${FILESDIR}"/7.1.x/72020-media-cix-armcb-isp-fix-module-namespace-and-actuator-define.patch || die
	eapply "${FILESDIR}"/7.1.x/72030-media-cix-armcb-isp-port-v4l2-api.patch || die
	eapply "${FILESDIR}"/7.1.x/72040-media-cix-armcb-isp-clean-up-acpi-probe-warnings.patch || die
	eapply "${FILESDIR}"/7.1.x/72050-media-cix-armcb-isp-defer-camera-regulators.patch || die
	eapply "${FILESDIR}"/7.1.x/72060-media-cix-armcb-isp-defer-pinctrl-and-gpios.patch || die
	eapply "${FILESDIR}"/7.1.x/72070-media-cix-armcb-isp-defer-camera-mclk.patch || die
	eapply "${FILESDIR}"/7.1.x/72080-media-cix-armcb-isp-fix-vi-hw-csidma-and-irqs.patch || die
	eapply "${FILESDIR}"/7.1.x/72090-media-cix-armcb-isp-fix-async-fwnode-lifetime.patch || die
	eapply "${FILESDIR}"/7.1.x/72095-media-cix-armcb-isp-stabilise-async-fwnodes.patch || die
	eapply "${FILESDIR}"/7.1.x/72096-media-cix-armcb-isp-diagnose-async-fwnodes.patch || die
	eapply "${FILESDIR}"/7.1.x/72097-media-cix-armcb-isp-repair-ordered-subdev-list.patch || die
	eapply "${FILESDIR}"/7.1.x/72098-media-cix-armcb-isp-deep-safe-diagnostics.patch || die
	eapply "${FILESDIR}"/7.1.x/72099-media-cix-armcb-isp-unwind-sensor-probe-registration.patch || die
	eapply "${FILESDIR}"/7.1.x/72100-media-cix-armcb-isp-uplift-selected-2026q2-fixes.patch || die
	eapply "${FILESDIR}"/7.0.x/70020-cix-759efc0-cix-display-and-backlight-build-fixes.patch || die
	eapply "${FILESDIR}"/70030-drm-cix-dptx-make-extra-stream-clocks-optional.patch || die
	eapply "${FILESDIR}"/7.0.x/70040-drm-panthor-drop-unused-gem-device-variable.patch || die
	eapply "${FILESDIR}"/7.0.x/70050-cix-759efc0-drm-cix-enable-acpi-stub-fdt-display.patch || die
	eapply "${FILESDIR}"/7.0.x/70070-cix-759efc0-drm-cix-use-fwnode-display-links.patch || die
	eapply "${FILESDIR}"/70080-drm-cix-remove-unused-dptx-cadence-phy-kconfig.patch || die
	eapply "${FILESDIR}"/70090-drm-cix-remove-unused-display-kconfig-prompts.patch || die
	eapply "${FILESDIR}"/7.0.x/70100-cix-759efc0-drm-cix-linlon-dp-fix-clang-warnings.patch || die
	eapply "${FILESDIR}"/7.1.x/70102-drm-cix-linlon-dp-use-output-color-format-bitmasks.patch || die
	eapply "${FILESDIR}"/7.1.x/70103-drm-cix-linlon-dp-port-private-objects-to-state-create.patch || die
	eapply "${FILESDIR}"/7.1.x/70104-drm-cix-linlon-dp-fix-werror-warnings.patch || die
	eapply "${FILESDIR}"/7.1.x/70106-drm-cix-dptx-use-output-color-format-bitmasks.patch || die
	eapply "${FILESDIR}"/7.1.x/70107-drm-cix-dptx-mark-encoder-atomic-check-static.patch || die
	eapply "${FILESDIR}"/7.1.x/70108-drm-cix-dptx-fix-werror-warnings.patch || die
	eapply "${FILESDIR}"/7.0.x/70110-cix-759efc0-drm-cix-demote-display-info-logs.patch || die
	eapply "${FILESDIR}"/70120-drm-cix-demote-internal-tbu-noop-logs.patch || die
	eapply "${FILESDIR}"/7.1.x/80030-cadence-macb-restore-pc302gem-config-scope.patch || die
	eapply "${FILESDIR}"/7.1.x/80031-cadence-macb-match-pc302gem-callbacks.patch || die
	eapply "${FILESDIR}"/80040-cadence-macb-use-sky1-acpi-aclk-as-hclk.patch || die
	eapply "${FILESDIR}"/40045-pnp-system-demote-pci-ecam-duplicate-reservations.patch || die
	eapply "${FILESDIR}"/7.0.x/40046-acpi-scan-demote-pci-ecam-duplicate-reservations.patch || die
	eapply "${FILESDIR}"/40044-pinctrl-acpi-export-pin-groups-helper.patch || die
	eapply "${FILESDIR}"/40049-pinctrl-sky1-drop-unused-debug-show-data.patch || die
	eapply "${FILESDIR}"/7.1.x/40052-pinctrl-sky1-ignore-conflicting-acpi-pin-groups.patch || die
	eapply "${FILESDIR}"/40093-pci-cix-enable-root-port-io-window-assignment.patch || die
	eapply "${FILESDIR}"/7.0.x/40050-cix-759efc0-soc-cix-arbitrate-acpi-usb-models.patch || die
	eapply "${FILESDIR}"/7.0.x/40060-cix-759efc0-soc-cix-add-gpu-cca-scan-quirk.patch || die
	eapply "${FILESDIR}"/7.1.x/40070-soc-cix-arbitrate-acpi-pcie-models.patch || die
	eapply "${FILESDIR}"/7.1.x/80092-pci-cadence-declare-sky1-config-read-helpers.patch || die
	eapply "${FILESDIR}"/40076-soc-cix-hide-dst-engineering-menu.patch || die
	eapply "${FILESDIR}"/7.0.x/40080-soc-cix-ignore-disabled-acpi-models.patch || die
	eapply "${FILESDIR}"/60095-soc-cix-keep-usbdp-phy-with-pnp0d10.patch || die
	eapply "${FILESDIR}"/7.0.x/90000-cix-759efc0-soc-cix-add-acpi-bus-perf-driver.patch || die
	eapply "${FILESDIR}"/7.0.x/90010-cix-759efc0-cix-sky1-acpi-socinfo-nvmem-ddrlp-ipa.patch || die
	eapply "${FILESDIR}"/7.0.x/90020-cix-759efc0-cix-fix-module-modpost-exports.patch || die
	eapply "${FILESDIR}"/70105-drm-cix-linlon-dp-tighten-private-include-flags.patch || die
	eapply "${FILESDIR}"/7.0.x/90040-soc-cix-expose-raw-sky1-socinfo-fields.patch || die
	eapply "${FILESDIR}"/90045-soc-cix-align-sky1-socinfo-opn-decode-with-bsp.patch || die
	eapply "${FILESDIR}"/90046-arm64-cix-guard-dmi-cpu-name-reference.patch || die
	eapply "${FILESDIR}"/7.1.x/90092-hwmon-cix-add-acpi-fan-driver.patch || die
	eapply "${FILESDIR}"/7.0.x/90093-hwmon-cix-fan-scale-ec-pwm-duty.patch || die
	eapply "${FILESDIR}"/7.1.x/90096-soc-cix-add-sky1-reboot-reason-driver.patch || die
	eapply "${FILESDIR}"/7.0.x/90098-pstore-ramoops-parse-firmware-node-properties.patch || die
	eapply "${FILESDIR}"/7.0.x/60010-usb-cdnsp-sky1-fix-acpi-fwnode-and-pm-paths.patch || die
	eapply "${FILESDIR}"/7.0.x/60015-cix-759efc0-usb-cdnsp-sky1-tear-down-host-on-shutdown.patch || die
	eapply "${FILESDIR}"/7.0.x/60020-usb-typec-rts5453-include-irq-header.patch || die
	eapply "${FILESDIR}"/7.0.x/60030-usb-typec-rts5453-fix-pm-sleep-disabled-build.patch || die
	eapply "${FILESDIR}"/7.0.x/60040-phy-cix-enable-acpi-stub-fdt.patch || die
	eapply "${FILESDIR}"/7.0.x/60050-usb-typec-rts5453-select-sky1-gpio-irq-provider.patch || die
	eapply "${FILESDIR}"/7.0.x/60060-usb-typec-rts5453-stop-permanent-defer.patch || die
	eapply "${FILESDIR}"/60070-usb-typec-add-provider-fwnode-control-lookups.patch || die
	eapply "${FILESDIR}"/60120-usb-typec-rts5453-clean-up-acpi-usbdp-integration.patch || die
	eapply "${FILESDIR}"/7.0.x/30110-7.0.9-cix-acpi-ids-and-clkt-consumer-fixes.patch || die
	eapply "${FILESDIR}"/30130-acpi-scope-cix-scmi-sta-quirk.patch || die
	eapply "${FILESDIR}"/30140-clk-sky1-acpi-fail-incomplete-clkt-maps.patch || die
	eapply "${FILESDIR}"/30150-firmware-arm-scmi-balance-acpi-shmem-fwnode.patch || die
	eapply "${FILESDIR}"/30155-firmware-arm-scmi-match-only-scmi-bus-devices.patch || die
	eapply "${FILESDIR}"/7.0.x/30160-scmi-handle-acpi-debugfs-fallbacks.patch || die
	eapply "${FILESDIR}"/7.0.x/30170-clk-sky1-acpi-select-cix-mailbox-for-scmi.patch || die
	eapply "${FILESDIR}"/30180-mailbox-cix-avoid-sky1-scmi-shmem-overlap.patch || die
	eapply "${FILESDIR}"/30190-clk-scmi-keep-acpi-clocks-enabled.patch || die
	eapply "${FILESDIR}"/30195-firmware-arm-scmi-use-rational-perf-frequency-conversion.patch || die
	eapply "${FILESDIR}"/7.1.x/30105-clk-sky1-audss-use-determine-rate.patch || die
	eapply "${FILESDIR}"/7.1.x/30106-clk-reset-sky1-audss-add-acpi-noc-reset-lookup-and-safe-probe-unwind.patch || die
	eapply "${FILESDIR}"/7.1.x/30107-reset-core-fall-back-to-cix-acpi-lookup.patch || die
	eapply "${FILESDIR}"/7.1.x/30128-acpi-thermal-expose-zone-str-as-hwmon-label.patch || die
	eapply "${FILESDIR}"/7.1.x/73000-cix-hda-require-cadence-gpio-on-acpi-systems.patch || die
	eapply "${FILESDIR}"/7.0.x/73010-cix-hda-prefer-acpi-dma-ranges-and-harden-probe.patch || die
	eapply "${FILESDIR}"/7.0.x/50010-gpio-cadence-restore-match-data-and-skip-init.patch || die
	eapply "${FILESDIR}"/7.0.x/50020-irqchip-sky1-pdc-fix-acpi-ioremap-error-path.patch || die
	eapply "${FILESDIR}"/7.0.x/50030-mfd-syscon-fix-fwnode-property-lookup-lifetime.patch || die
	eapply "${FILESDIR}"/50040-pwm-sky1-fix-kconfig-entry.patch || die
	eapply "${FILESDIR}"/7.0.x/50045-soc-cix-require-dev-id-for-reset-lookups.patch || die
	eapply "${FILESDIR}"/7.0.x/50050-edac-a72-skip-of-cpu-scan-under-acpi.patch || die
	eapply "${FILESDIR}"/80050-pci-rtl8126-disable-vpd-quietly.patch || die
	eapply "${FILESDIR}"/7.0.x/50060-watchdog-sbsa-gwdt-use-control-frame-ping-on-cix-sky1.patch || die
	eapply "${FILESDIR}"/7.0.x/50070-dma-arm-dma350-skip-of-reserved-memory-under-acpi.patch || die
	eapply "${FILESDIR}"/7.0.x/50080-dma-arm-dma350-skip-unsafe-remote-acpi-probe.patch || die
	eapply "${FILESDIR}"/7.0.x/50085-dma-arm-dma350-keep-fch-acpi-dma-optional-clocks-optional.patch || die
	eapply "${FILESDIR}"/50090-dma-coherent-keep-declared-memory-write-combined.patch || die
	eapply "${FILESDIR}"/80075-pci-strengthen-sky1-aspm-disable-for-faulting-endpoints.patch || die
	eapply "${FILESDIR}"/80080-cix-sky1-declare-module-softdeps.patch || die
	if use radxa-menu; then
		eapply "${FILESDIR}"/7.1.x/90050-arm64-cix-add-radxa-orion-board-profiles.patch || die
	fi

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
		'orion-o6-audio-dtb-metadata')
			prefix='O6AUD'
			;;
		'orion-o6-busperf')
			prefix='O6BPF'
			;;
		'orion-o6-cppc-reference-performance')
			prefix='O6CPPC'
			;;
		'orion-o6-dsu-pmu')
			prefix='O6DSUP'
			;;
		'orion-o6-gpu-noncoherent')
			prefix='O6GPU'
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
		'orion-o6-reboot-reason')
			prefix='O6RBRR'
			;;
		'orion-o6-thermal-sensors')
			prefix='O6TZSNS'
			;;
		'orion-o6n-busperf')
			prefix='O6NBPF'
			;;
		'orion-o6n-cppc-reference-performance')
			prefix='O6NCPPC'
			;;
		'orion-o6n-dsu-pmu')
			prefix='O6NDSUP'
			;;
		'orion-o6n-gpu-noncoherent')
			prefix='O6NGPU'
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
		*)
			die "_src_compile_asl() called with unknown file '${file:-}'"
			;;
	esac

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

	mkdir -p "${dest}" || die
	python3 "${src}/iort/build_iort_upgrade.py" "${args[@]}" \
		"${src}/iort/IORT.dat" "${dest}/IORT.aml" ||
		die "failed to build IORT table-upgrade payload"
}

_cix_acpi_vendor_firmware() {
	case "${1:-}" in
		'o6')
			printf '%s\n' "${VENDOR_FIRMWARE_O6}"
			;;
		'o6n')
			printf '%s\n' "${VENDOR_FIRMWARE_O6N}"
			;;
		*)
			die "unknown ACPI table-upgrade board '${1:-}'"
			;;
	esac
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
		local dst="${T}/cix-acpi-table-upgrade"
		local kernel_dir="/usr/src/linux-${CKV}-cix"
		local board='' board_dst='' file='' profile='' src='' vendor=''
		local -a boards=( 'o6' 'o6n' )
		local -a profiles=()

		if [[ "${PR:-"r0"}" != 'r0' ]]; then
			kernel_dir="${kernel_dir}-${PR}"
		fi

		for board in "${boards[@]}"; do
			vendor="$( _cix_acpi_vendor_firmware "${board}" )"
			src="${FILESDIR}/acpi-table-upgrade/${vendor}"
			board_dst="${dst}/${board}"
			profiles=( 'initramfs' )

			# Compile SSDT overlays, used by both profiles.
			for file in "${src}"/ssdt/*.asl; do
				_src_compile_asl "${file}" \
					"${board_dst}/initramfs/kernel/firmware/acpi"
			done

			if use acpi-table-upgrade-dsdt; then
				mkdir -p "${board_dst}/initramfs-dsdt/kernel/firmware/acpi" || die
				cp "${board_dst}"/initramfs/kernel/firmware/acpi/*.aml \
					"${board_dst}"/initramfs-dsdt/kernel/firmware/acpi

				# Compile whole-table replacements for the full profile only.
				for file in "${src}"/pptt/*.asl; do
					[[ -e "${file:-}" ]] || continue
					_src_compile_asl "${file}" \
						"${board_dst}/initramfs-dsdt/kernel/firmware/acpi"
				done

				_src_compile_iort "${src}" \
					"${board_dst}/initramfs-dsdt/kernel/firmware/acpi"

				for file in "${src}"/dsdt/*.asl; do
					_src_compile_asl "${file}" \
						"${board_dst}/initramfs-dsdt/kernel/firmware/acpi"
				done
				profiles+=( 'initramfs-dsdt' )
			fi

			for profile in "${profiles[@]}"; do
				_cix_acpi_write_initramfs_list \
					"${board_dst}/${profile}" \
					"${dst}/${board}/${profile}.list" \
					"${kernel_dir%/}/cix-acpi-table-upgrade/${board}/${profile}"
			done
		done

		# Compatibility aliases: the historical top-level profile paths select O6.
		profiles=( 'initramfs' )
		if use acpi-table-upgrade-dsdt; then
			profiles+=( 'initramfs-dsdt' )
		fi
		for profile in "${profiles[@]}"; do
			cp -a "${dst}/o6/${profile}" "${dst}/${profile}" || die
			_cix_acpi_write_initramfs_list \
				"${dst}/${profile}" \
				"${dst}/${profile}.list" \
				"${kernel_dir%/}/cix-acpi-table-upgrade/${profile}"
		done
	fi
}

src_install() {
	local kernel_dir="/usr/src/linux-${CKV}-cix"
	local board='' file='' profile='' src='' vendor=''
	local -a boards=( 'o6' 'o6n' )
	local -a profiles=( 'initramfs' )

	kernel-2_src_install

	# e.g. linux-7.0.9 -> linux-7.0.9-cix-r1
	if [[ "${PR:-"r0"}" != 'r0' ]]; then
		kernel_dir="${kernel_dir}-${PR}"
	fi
	mv "${ED}/usr/src/linux-${CKV}" "${ED%"/"}/${kernel_dir#"/"}" || die

	if use acpi-table-upgrade; then
		insinto "${kernel_dir}/cix-acpi-table-upgrade"
		doins "${FILESDIR}/ACPI_TABLE_UPGRADE.md"

		for board in "${boards[@]}"; do
			vendor="$( _cix_acpi_vendor_firmware "${board}" )"
			src="${FILESDIR}/acpi-table-upgrade/${vendor}"

			insinto "${kernel_dir}/cix-acpi-table-upgrade/source/${board}/${vendor}/ssdt"
			doins "${src}"/ssdt/*.asl

			insinto "${kernel_dir}/cix-acpi-table-upgrade/source/${board}/${vendor}/pptt"
			doins "${src}"/pptt/*.asl

			insinto "${kernel_dir}/cix-acpi-table-upgrade/source/${board}/${vendor}/iort"
			doins "${src}"/iort/*

			insinto "${kernel_dir}/cix-acpi-table-upgrade/source/${board}/${vendor}/dsdt"
			doins "${src}"/dsdt/*.asl
		done

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

		# Compatibility aliases: the historical top-level profile paths select O6.
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

	elog "CIX Sky1 PCIe SMMU ACPI workarounds are available as opt-in"
	elog "kernel command-line parameters for firmware that needs them:"
	elog "  arm-smmu-v3.cix_sky1_pcie_boot_bypass=1"
	elog "    installs Sky1 PCIe boot-active bypass STEs."
	elog "  arm-smmu-v3.cix_sky1_pcie_ats_override=1"
	elog "    enables the Sky1 PCIe ATS override."
	elog "  arm-smmu-v3.cix_sky1_pcie_quirks=1"
	elog "    enables both workarounds."
	elog "Matching parameters are also available on the arm_smmu_v3"
	elog "driver/module and override these kernel command-line defaults"
	elog "when explicitly supplied."
	elog "All options remain gated by Sky1 PCIe SMMU hardware detection."

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
		elog "Board-specific initramfs source lists are installed at:"
		elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/o6/initramfs.list"
		elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/o6n/initramfs.list"
		if use acpi-table-upgrade-dsdt; then
			elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/o6/initramfs-dsdt.list"
			elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/o6n/initramfs-dsdt.list"
		fi
		elog "The historical top-level list paths are retained as O6 aliases."
		elog "To build them into the kernel, enable the built-in initramfs"
		elog "ACPI override options and set CONFIG_INITRAMFS_SOURCE to one"
		elog "of the board-specific lists, for example:"
		elog "  /usr/src/linux/cix-acpi-table-upgrade/o6/${selected_profile}.list"
		elog "  /usr/src/linux/cix-acpi-table-upgrade/o6n/${selected_profile}.list"
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
