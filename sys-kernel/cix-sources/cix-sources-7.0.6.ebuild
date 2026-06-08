# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="7"
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

EGIT_CIX_COMMIT="3aad82491a599648d87ba1c47cec7968862fa165"
EGIT_SKY1_COMMIT="57e018a398248d7e5e4d798610df79a557c0629f"
VENDOR_FIRMWARE="orion-o6-radxa-1.2.1"

DESCRIPTION="CIX sources including the Gentoo, CIX & Entropi patchsets for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
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
	"${FILESDIR}"/7.0.x/10000-7.0-arm64-stub-fdt.patch
	"${FILESDIR}"/10010-arm64-stub-fdt-enable-kexec-file.patch
	"${FILESDIR}"/10020-lld-timer-of-table-end-warning.patch
	"${FILESDIR}"/80000-rtl8126-disable-vpd.patch
)

pkg_setup() {
	ewarn
	ewarn "${PN} is *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the Radxa/CIX developers"
	ewarn "directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn

	kernel-2_pkg_setup
}

cix_acpi_aml_stem() {
	case "$1" in
		orion-o6-audio-dtb-metadata)
			printf 'O6AUD\n'
			;;
		orion-o6-busperf)
			printf 'O6BPF\n'
			;;
		orion-o6-cppc-reference-performance)
			printf 'O6CPPC\n'
			;;
		orion-o6-gpu-noncoherent)
			printf 'O6GPU\n'
			;;
		orion-o6-rts5453-shared-irq)
			printf 'O6RTS\n'
			;;
		orion-o6-scmi-mailbox-window)
			printf 'O6SCMI\n'
			;;
		orion-o6-ectz-critical-trip)
			printf 'O6ECTZ\n'
			;;
		orion-o6-reboot-reason)
			printf 'O6RBRR\n'
			;;
		orion-o6-thermal-sensors)
			printf 'O6TZSNS\n'
			;;
		*)
			printf '%s\n' "$1"
			;;
	esac
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
		eapply "${pf}" || die
	done

	# These Sky1 patches are additive on top of CIX's native 7.0 queue.
	eapply "${sky1_patch_dir}"/0007-pinctrl-cix-Update-Sky1-pin-controller.patch || die
	eapply "${sky1_patch_dir}"/0013-net-Add-CIX-Sky1-networking-drivers.patch || die
	eapply "${FILESDIR}"/80060-realtek-r8125-r8126-use-kernel-dma-mapping-error.patch || die
	eapply "${sky1_patch_dir}"/0015-media-cix-Add-Sky1-video-codec-VPU-driver.patch || die
	eapply "${sky1_patch_dir}"/0016-misc-armchina-npu-Add-Zhouyi-NPU-driver-for-CIX-Sky1.patch || die
	eapply "${FILESDIR}"/7.0.x/50000-7.0-iommu-arm-smmu-v3-add-acpi-boot-active-bypass-stes-for-cix-sky1-pcie.patch || die
	eapply "${FILESDIR}"/7.0.x/70000-7.0-drm-add-sky1-drm-render-node-bridge-for-cix-sky1-soc.patch || die
	eapply "${sky1_patch_dir}"/0024-drm-sky1-switch-from-faux_device-to-platform_device.patch || die
	eapply "${sky1_patch_dir}"/0025-mm-add-Mali-GPU-movable_ops-page-type-support.patch || die

	rm -r "${WORKDIR}/cix-linux-main-${EGIT_CIX_COMMIT}" || die
	rm -r "${WORKDIR}/linux-sky1-${EGIT_SKY1_COMMIT}" || die

	eapply "${FILESDIR}"/7.0.x/20010-7.0-cix-fix-deps-section-mismatch-and-clang-uninit-build-fail.patch || die
	eapply "${FILESDIR}"/70010-drm-cix-dptx-fix-clang-werror-in-component-bypass-builds.patch || die
	eapply "${FILESDIR}"/72000-armchina-npu-zhouyi-fix-missing-prototype-under-werror.patch || die
	eapply "${FILESDIR}"/72010-armchina-npu-fix-acpi-match-and-user-visible-text.patch || die
	eapply "${FILESDIR}"/72020-armchina-npu-fix-runtime-pm-put-build.patch || die
	eapply "${FILESDIR}"/7.0.x/72025-7.0-armchina-npu-defer-until-perf-domain-ready.patch || die
	eapply "${FILESDIR}"/7.0.x/30000-7.0-pmdomain-fix-acpi-scmi-perf-domain-wiring.patch || die
	eapply "${FILESDIR}"/7.0.x/30015-7.0-pmdomain-export-genpd-dev-pm-attach-by-name.patch || die
	eapply "${FILESDIR}"/30030-scmi-demote-unsupported-fastchannel-fallback.patch || die
	eapply "${FILESDIR}"/30070-opp-tolerate-unsupported-interconnect-paths.patch || die
	eapply "${FILESDIR}"/30080-opp-suppress-unsupported-interconnect-warning.patch || die
	eapply "${FILESDIR}"/7.0.x/72030-7.0-armchina-npu-clean-up-acpi-core-runtime-pm-on-defer.patch || die
	eapply "${FILESDIR}"/7.0.x/72040-7.0-armchina-npu-guard-missing-iova-cookie.patch || die
	eapply "${FILESDIR}"/7.0.x/72050-7.0-armchina-npu-prefer-dma-api-on-acpi.patch || die
	eapply "${FILESDIR}"/7.0.x/72055-7.0-armchina-npu-clarify-acpi-dma-api-memory-management-log.patch || die
	eapply "${FILESDIR}"/7.0.x/72060-7.0-armchina-npu-drop-invalid-oneshot-irq-flag.patch || die
	eapply "${FILESDIR}"/72070-armchina-npu-add-acpi-resume-complete-hook.patch || die
	eapply "${FILESDIR}"/72080-armchina-npu-harden-probe-and-runtime-pm-error-handling.patch || die
	eapply "${FILESDIR}"/72090-armchina-npu-clean-up-dmabuf-sg-mappings.patch || die
	eapply "${FILESDIR}"/72095-armchina-npu-defer-dmabuf-backing-free-to-release.patch || die
	eapply "${FILESDIR}"/20030-gpio-cadence-fix-pm-ops-when-pm-sleep-is-disabled.patch || die
	eapply "${FILESDIR}"/20040-cpufreq-fall-back-to-policy-max-for-fast-switch-sca.patch || die
	eapply "${FILESDIR}"/20050-topology-has-missing-cpufreq-ref.patch || die
	eapply "${FILESDIR}"/20060-acpi-processor-clarify-ignore-ppc-module-parameter.patch || die
	eapply "${FILESDIR}"/30090-scmi-hwmon-do-not-use-of-thermal-zones-on-acpi.patch || die
	eapply "${FILESDIR}"/30125-acpi-table-upgrade-add-disable-and-exclude-options.patch || die
	eapply "${FILESDIR}"/30127-acpi-thermal-filter-orion-o6-ectz-zero-readings.patch || die
	eapply "${FILESDIR}"/80010-rtw89-disable-hw-rfkill-polling-on-orion-o6.patch || die
	eapply "${FILESDIR}"/7.0.x/80020-7.0-rtw89-check-acpi-dsm-before-evaluating.patch || die
	eapply "${FILESDIR}"/60000-cix-usb-phy-fail-cleanly-on-missing-resources.patch || die
	eapply "${FILESDIR}"/10030-build-modpost-report-all-unresolved-symbols.patch || die
	eapply "${FILESDIR}"/7.0.x/10040-7.0-bpf-guard-session-return-btf-id.patch || die
	eapply "${FILESDIR}"/71000-cix-mvx-build-and-api-fixes.patch || die
	eapply "${FILESDIR}"/7.0.x/71010-7.0-cix-mvx-declare-v4l2-vb2-dependencies.patch || die
	eapply "${FILESDIR}"/7.0.x/71020-7.0-cix-mvx-fix-nested-comment-warning.patch || die
	eapply "${FILESDIR}"/71030-cix-mvx-respect-in-tree-kconfig.patch || die
	eapply "${FILESDIR}"/71040-cix-mvx-fix-user-visible-names.patch || die
	eapply "${FILESDIR}"/71050-cix-mvx-enable-jpeg-mjpeg-devices.patch || die
	eapply "${FILESDIR}"/71060-cix-mvx-port-sky1p-reset-sequencing.patch || die
	eapply "${FILESDIR}"/70020-cix-display-and-backlight-build-fixes.patch || die
	eapply "${FILESDIR}"/70030-drm-cix-dptx-make-extra-stream-clocks-optional.patch || die
	eapply "${FILESDIR}"/7.0.x/70040-7.0-drm-panthor-drop-unused-gem-device-variable.patch || die
	eapply "${FILESDIR}"/70050-drm-cix-enable-acpi-stub-fdt-display.patch || die
	eapply "${FILESDIR}"/70060-drm-add-fwnode-panel-bridge-helpers.patch || die
	eapply "${FILESDIR}"/70070-drm-cix-use-fwnode-display-links.patch || die
	eapply "${FILESDIR}"/70080-drm-cix-remove-unused-dptx-cadence-phy-kconfig.patch || die
	eapply "${FILESDIR}"/70090-drm-cix-remove-unused-display-kconfig-prompts.patch || die
	eapply "${FILESDIR}"/7.0.x/70100-7.0-drm-cix-linlon-dp-fix-clang-warnings.patch || die
	eapply "${FILESDIR}"/7.0.x/70110-7.0-drm-cix-demote-display-info-logs.patch || die
	eapply "${FILESDIR}"/80030-cadence-macb-restore-pc302gem-config-scope.patch || die
	eapply "${FILESDIR}"/80040-cadence-macb-use-sky1-acpi-aclk-as-hclk.patch || die
	eapply "${FILESDIR}"/40045-pnp-system-demote-pci-ecam-duplicate-reservations.patch || die
	eapply "${FILESDIR}"/7.0.x/40046-7.0-acpi-scan-demote-pci-ecam-duplicate-reservations.patch || die
	eapply "${FILESDIR}"/7.0.x/40050-7.0-soc-cix-arbitrate-acpi-usb-models.patch || die
	eapply "${FILESDIR}"/7.0.x/40060-7.0-soc-cix-add-gpu-cca-scan-quirk.patch || die
	eapply "${FILESDIR}"/7.0.x/40070-7.0-soc-cix-arbitrate-acpi-pcie-models.patch || die
	eapply "${FILESDIR}"/7.0.x/40080-7.0-soc-cix-ignore-disabled-acpi-models.patch || die
	eapply "${FILESDIR}"/7.0.x/90000-7.0-soc-cix-add-acpi-bus-perf-driver.patch || die
	eapply "${FILESDIR}"/7.0.x/90010-7.0-cix-sky1-acpi-socinfo-nvmem-ddrlp-ipa.patch || die
	eapply "${FILESDIR}"/7.0.x/90020-7.0-cix-fix-module-modpost-exports.patch || die
	eapply "${FILESDIR}"/7.0.x/90030-7.0-cix-cpu-ipa-use-dtb-register-size.patch || die
	eapply "${FILESDIR}"/7.0.x/90040-7.0-soc-cix-expose-raw-sky1-socinfo-fields.patch || die
	eapply "${FILESDIR}"/90045-soc-cix-align-sky1-socinfo-opn-decode-with-bsp.patch || die
	eapply "${FILESDIR}"/7.0.x/90092-7.0-hwmon-cix-add-acpi-fan-driver.patch || die
	eapply "${FILESDIR}"/90096-soc-cix-add-sky1-reboot-reason-driver.patch || die
	eapply "${FILESDIR}"/7.0.x/90098-7.0-pstore-ramoops-parse-firmware-node-properties.patch || die
	eapply "${FILESDIR}"/7.0.x/60010-7.0-usb-cdnsp-sky1-fix-acpi-fwnode-and-pm-paths.patch || die
	eapply "${FILESDIR}"/7.0.x/60020-7.0-usb-typec-rts5453-include-irq-header.patch || die
	eapply "${FILESDIR}"/7.0.x/60030-7.0-usb-typec-rts5453-fix-pm-sleep-disabled-build.patch || die
	eapply "${FILESDIR}"/7.0.x/60040-7.0-phy-cix-enable-acpi-stub-fdt.patch || die
	eapply "${FILESDIR}"/7.0.x/60050-7.0-usb-typec-rts5453-select-sky1-gpio-irq-provider.patch || die
	eapply "${FILESDIR}"/7.0.x/60060-7.0-usb-typec-rts5453-stop-permanent-defer.patch || die
	eapply "${FILESDIR}"/60070-usb-typec-add-provider-fwnode-control-lookups.patch || die
	eapply "${FILESDIR}"/60120-usb-typec-rts5453-clean-up-acpi-usbdp-integration.patch || die
	eapply "${FILESDIR}"/7.0.x/30110-7.0-cix-acpi-ids-and-clkt-consumer-fixes.patch || die
	eapply "${FILESDIR}"/30130-acpi-scope-cix-scmi-sta-quirk.patch || die
	eapply "${FILESDIR}"/30140-clk-sky1-acpi-fail-incomplete-clkt-maps.patch || die
	eapply "${FILESDIR}"/30150-firmware-arm-scmi-balance-acpi-shmem-fwnode.patch || die
	eapply "${FILESDIR}"/7.0.x/30160-7.0-scmi-handle-acpi-debugfs-fallbacks.patch || die
	eapply "${FILESDIR}"/7.0.x/30170-7.0-clk-sky1-acpi-select-cix-mailbox-for-scmi.patch || die
	eapply "${FILESDIR}"/30180-mailbox-cix-avoid-sky1-scmi-shmem-overlap.patch || die
	eapply "${FILESDIR}"/30190-clk-scmi-keep-acpi-clocks-enabled.patch || die
	eapply "${FILESDIR}"/30195-firmware-arm-scmi-use-rational-perf-frequency-conversion.patch || die
	eapply "${FILESDIR}"/7.0.x/73000-7.0-cix-hda-require-cadence-gpio-on-acpi-systems.patch || die
	eapply "${FILESDIR}"/7.0.x/50010-7.0-gpio-cadence-restore-match-data-and-skip-init.patch || die
	eapply "${FILESDIR}"/7.0.x/50020-7.0-irqchip-sky1-pdc-fix-acpi-ioremap-error-path.patch || die
	eapply "${FILESDIR}"/7.0.x/50030-7.0-mfd-syscon-fix-fwnode-property-lookup-lifetime.patch || die
	eapply "${FILESDIR}"/50040-pwm-sky1-fix-kconfig-entry.patch || die
	eapply "${FILESDIR}"/7.0.x/50045-7.0-soc-cix-require-dev-id-for-reset-lookups.patch || die
	eapply "${FILESDIR}"/7.0.x/50050-7.0-edac-a72-skip-of-cpu-scan-under-acpi.patch || die
	eapply "${FILESDIR}"/80050-pci-rtl8126-disable-vpd-quietly.patch || die
	eapply "${FILESDIR}"/7.0.x/50060-7.0-watchdog-sbsa-gwdt-use-control-frame-ping-on-cix-sky1.patch || die
	eapply "${FILESDIR}"/7.0.x/50070-7.0-dma-arm-dma350-skip-of-reserved-memory-under-acpi.patch || die
	eapply "${FILESDIR}"/7.0.x/50080-7.0-dma-arm-dma350-skip-unsafe-remote-acpi-probe.patch || die
	if use radxa-menu; then
		eapply "${FILESDIR}"/7.0.x/90050-7.0-arm64-cix-add-radxa-orion-board-profiles.patch || die
	fi

	kernel-2_src_prepare
}

src_compile_iort() {
	local src="${1:-}"
	local dest="${2:-}"
	local -a args=()

	[[ -s "${src}/iort/IORT.dat" ]] ||
		die "src_compile_iort() called without source IORT.dat"

	use acpi-table-upgrade-iort-httu && args+=( '--httu' )
	use acpi-table-upgrade-iort-msi && args+=( '--msi' )
	[[ ${#args[@]} -gt 0 ]] || return 0

	mkdir -p "${dest}" || die
	python3 "${src}/iort/build_iort_upgrade.py" "${args[@]}" \
		"${src}/iort/IORT.dat" "${dest}/IORT.aml" ||
		die "failed to build IORT table-upgrade payload"
}

src_compile() {
	if use acpi-table-upgrade; then
		local aml=''
		local asl=''
		local installed_aml_dir=''
		local linux_dir="linux-${CKV}-cix"
		local outbase=''
		local output_dir="${T}/cix-acpi-table-upgrade"
		local profile=''
		local source_aml_dir=''
		local stem=''
		local -a profiles=( initramfs )

		if [[ "${PR}" != 'r0' ]]; then
			linux_dir="linux-${CKV}-cix-${PR}"
		fi

		if use acpi-table-upgrade-dsdt; then
			profiles+=( initramfs-dsdt )
		fi

		rm -rf "${output_dir}" || die
		for profile in "${profiles[@]}"; do
			source_aml_dir="${output_dir}/${profile}/kernel/firmware/acpi"
			installed_aml_dir="/usr/src/${linux_dir}/cix-acpi-table-upgrade/${profile}/kernel/firmware/acpi"
			mkdir -p "${source_aml_dir}" || die

			for asl in "${FILESDIR}"/acpi-table-upgrade/"${VENDOR_FIRMWARE}"/ssdt/*.asl; do
				stem=${asl##*/}
				stem=${stem%.asl}
				stem=$(cix_acpi_aml_stem "${stem}") || die
				outbase="${source_aml_dir}/${stem}"
				iasl -p "${outbase}" -tc "${asl}" || die "failed to compile ${asl}"
				rm -f "${outbase}.hex" "${outbase}.lst" || die
			done

			if [[ "${profile}" == "initramfs-dsdt" ]]; then
				for asl in "${FILESDIR}"/acpi-table-upgrade/"${VENDOR_FIRMWARE}"/pptt/*.asl; do
					[[ -e "${asl:-}" ]] || continue
					stem=${asl##*/}
					stem=${stem%.asl}
					stem=$(cix_acpi_aml_stem "${stem}") || die
					outbase="${source_aml_dir}/${stem}"
					iasl -p "${outbase}" -tc "${asl}" || die "failed to compile ${asl}"
					rm -f "${outbase}.hex" "${outbase}.lst" || die
				done

				src_compile_iort "${FILESDIR}/acpi-table-upgrade/${VENDOR_FIRMWARE}" \
					"${source_aml_dir}"

				for asl in "${FILESDIR}"/acpi-table-upgrade/"${VENDOR_FIRMWARE}"/dsdt/*.asl; do
					stem=${asl##*/}
					stem=${stem%.asl}
					stem=$(cix_acpi_aml_stem "${stem}") || die
					outbase="${source_aml_dir}/${stem}"
					iasl -p "${outbase}" -tc "${asl}" || die "failed to compile ${asl}"
					rm -f "${outbase}.hex" "${outbase}.lst" || die
				done
			fi

			{
				printf 'dir /dev 0755 0 0\n'
				printf 'nod /dev/console 0600 0 0 c 5 1\n'
				printf 'dir /root 0700 0 0\n'
				printf 'dir /kernel 0755 0 0\n'
				printf 'dir /kernel/firmware 0755 0 0\n'
				printf 'dir /kernel/firmware/acpi 0755 0 0\n'

				for aml in "${source_aml_dir}"/*.aml; do
					[[ -e "${aml}" ]] || die "no AML files found in ${source_aml_dir}"
					printf 'file /kernel/firmware/acpi/%s %s/%s 0644 0 0\n' \
						"${aml##*/}" "${installed_aml_dir}" "${aml##*/}"
				done
			} > "${output_dir}/${profile}.list" || die "failed to create ${output_dir}/${profile}.list"
		done
	fi
}

src_install() {
	local linux_dir=''
	local profile=''
	local -a profiles=( initramfs )

	kernel-2_src_install

	# e.g. linux-6.1.75 -> linux-6.1.75-cix-r1
	dodir /usr/src
	if [[ "${PR}" != 'r0' ]]; then
		linux_dir="linux-${CKV}-cix-${PR}"
		mv "${ED}/usr/src/linux-${CKV}-${PR}"  \
			"${ED}/usr/src/${linux_dir}" || die
	else
		linux_dir="linux-${CKV}-cix"
		mv "${ED}/usr/src/linux-${CKV}" \
			"${ED}/usr/src/${linux_dir}" || die
	fi

	if use acpi-table-upgrade; then
		dodir "/usr/src/${linux_dir}/cix-acpi-table-upgrade"
		insinto "/usr/src/${linux_dir}/cix-acpi-table-upgrade"
		doins "${FILESDIR}"/ACPI_TABLE_UPGRADE.md
		dodir "/usr/src/${linux_dir}/cix-acpi-table-upgrade/source/${VENDOR_FIRMWARE}/ssdt"
		insinto "/usr/src/${linux_dir}/cix-acpi-table-upgrade/source/${VENDOR_FIRMWARE}/ssdt"
		doins "${FILESDIR}"/acpi-table-upgrade/"${VENDOR_FIRMWARE}"/ssdt/*.asl
		dodir "/usr/src/${linux_dir}/cix-acpi-table-upgrade/source/${VENDOR_FIRMWARE}/pptt"
		insinto "/usr/src/${linux_dir}/cix-acpi-table-upgrade/source/${VENDOR_FIRMWARE}/pptt"
		doins "${FILESDIR}"/acpi-table-upgrade/"${VENDOR_FIRMWARE}"/pptt/*.asl
		dodir "/usr/src/${linux_dir}/cix-acpi-table-upgrade/source/${VENDOR_FIRMWARE}/dsdt"
		insinto "/usr/src/${linux_dir}/cix-acpi-table-upgrade/source/${VENDOR_FIRMWARE}/dsdt"
		doins "${FILESDIR}"/acpi-table-upgrade/"${VENDOR_FIRMWARE}"/dsdt/*.asl
		dodir "/usr/src/${linux_dir}/cix-acpi-table-upgrade/source/${VENDOR_FIRMWARE}/iort"
		insinto "/usr/src/${linux_dir}/cix-acpi-table-upgrade/source/${VENDOR_FIRMWARE}/iort"
		doins "${FILESDIR}"/acpi-table-upgrade/"${VENDOR_FIRMWARE}"/iort/*
		if use acpi-table-upgrade-dsdt; then
			profiles+=( initramfs-dsdt )
		fi

		for profile in "${profiles[@]}"; do
			insinto "/usr/src/${linux_dir}/cix-acpi-table-upgrade"
			doins "${T}/cix-acpi-table-upgrade/${profile}.list"
			dodir "/usr/src/${linux_dir}/cix-acpi-table-upgrade/${profile}/kernel/firmware/acpi"
			insinto "/usr/src/${linux_dir}/cix-acpi-table-upgrade/${profile}/kernel/firmware/acpi"
			doins "${T}"/cix-acpi-table-upgrade/"${profile}"/kernel/firmware/acpi/*.aml
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

		if [[ "${PR}" != 'r0' ]]; then
			linux_dir="linux-${PV%_p*}-cix-${PR}"
		fi
		if use acpi-table-upgrade-dsdt; then
			selected_profile='initramfs-dsdt'
		fi

		elog
		elog "ACPI table-upgrade sources and compiled AML profiles were"
		elog "installed under /usr/src/${linux_dir}/cix-acpi-table-upgrade."
		elog "Selectable initramfs source lists are installed at:"
		elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/initramfs.list"
		elog "  /usr/src/${linux_dir}/cix-acpi-table-upgrade/initramfs-dsdt.list"
		elog "To build them into the kernel, enable the built-in initramfs"
		elog "ACPI override options and set CONFIG_INITRAMFS_SOURCE to:"
		elog "  /usr/src/linux/cix-acpi-table-upgrade/${selected_profile}.list"
		elog "Keep /usr/src/linux pointing at this source tree before building."
	fi

	if use symlink; then
		if [[ "${PR}" != 'r0' ]]; then
			ln -snf "linux-${PV%_p*}-cix${PR}" "${EROOT}"/usr/src/linux || die
		else
			ln -snf "linux-${PV%_p*}-cix" "${EROOT}"/usr/src/linux || die
		fi
	fi
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
