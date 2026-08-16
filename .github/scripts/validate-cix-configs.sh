#!/usr/bin/env bash
# Exercise disabled, modular, built-in, and broad CIX arm64 configurations.

set -euo pipefail

if (($# != 4)); then
	printf 'usage: %s SOURCE_DIR BUILD_ROOT KERNEL_LINE NPU_ABI\n' "$0" >&2
	exit 2
fi

source_dir=$1
build_root=$2
kernel_line=$3
npu_abi=$4
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
kconfig_update=${repo_root}/sys-kernel/cix-sources/files/kconfig_update.py

command -v modinfo >/dev/null || {
	printf 'error: modinfo is required for module metadata validation\n' >&2
	exit 1
}
[[ -f ${source_dir}/Makefile ]] || {
	printf 'error: not a kernel source tree: %s\n' "${source_dir}" >&2
	exit 1
}
[[ -x ${kconfig_update} ]] || {
	printf 'error: missing executable config helper: %s\n' "${kconfig_update}" >&2
	exit 1
}
for removed_source in rtltool.c rtltool.h; do
	[[ ! -s ${source_dir}/drivers/net/ethernet/realtek/r8126/${removed_source} ]] || {
		printf 'error: removed R8126 vendor engineering source retains content: %s\n' \
			"${removed_source}" >&2
		exit 1
	}
done
if grep -ERqs \
	'R8126_UNSAFE_DIAGNOSTICS|ENABLE_R8126_(PROCFS|SYSFS)|rtk_enable_diag' \
	"${source_dir}/drivers/net/ethernet/realtek/r8126"; then
	printf 'error: removed R8126 vendor engineering interface remains in prepared source\n' >&2
	exit 1
fi
if ! grep -ERqs 'MODULE_DEVICE_TABLE\((acpi|of),' \
	"${source_dir}/drivers/misc/armchina-npu"; then
	printf 'error: default R2P1 NPU backend has no module-device alias source\n' >&2
	exit 1
fi
if grep -ERqs 'MODULE_(ALIAS|DEVICE_TABLE)' \
	"${source_dir}/drivers/misc/armchina-npu-r2p0"; then
	printf 'error: explicit-load R2P0 NPU backend unexpectedly declares a module alias\n' >&2
	exit 1
fi
[[ ${npu_abi} == r2p0 || ${npu_abi} == r2p1 || ${npu_abi} == separate ]] || {
	printf 'error: unsupported NPU ABI: %s\n' "${npu_abi}" >&2
	exit 1
}

jobs=${CIX_CI_JOBS:-$(nproc)}
if ((jobs > 4)); then
	jobs=4
fi

run_kconfig_target() {
	local name=$1
	local target=$2
	local build_dir=${build_root}/${name}
	local -a config_env=()

	# Gentoo's generic allmod/allyes fragment selects KSTACK_ERASE while
	# LLVM lacks the GCC plugin it requires.  Exclude that unrelated generic
	# hardening combination so broad configuration diagnostics remain CIX-led.
	if [[ ${target} == allmodconfig || ${target} == allyesconfig ]]; then
		config_env=(env "KCONFIG_ALLCONFIG=${build_root}/broad-miniconfig")
	fi

	rm -rf -- "${build_dir}"
	mkdir -p -- "${build_dir}"
	"${config_env[@]}" make -s -C "${source_dir}" O="${build_dir}" \
		ARCH=arm64 LLVM=1 "${target}"
	printf '%s configuration generated at %s\n' "${target}" "${build_dir}"
}

mkdir -p -- "${build_root}"
printf '# CONFIG_GENTOO_KERNEL_SELF_PROTECTION is not set\n' \
	> "${build_root}/broad-miniconfig"

require_config() {
	local config=$1
	local expected=$2

	grep -Fqx -- "${expected}" "${config}" || {
		printf 'error: %s does not contain %s\n' "${config}" "${expected}" >&2
		exit 1
	}
}

require_integer_config_at_most() {
	local config=$1
	local symbol=$2
	local maximum=$3
	local value

	value=$(sed -n "s/^CONFIG_${symbol}=//p" "${config}")
	if [[ ! ${value} =~ ^[0-9]+$ ]] || ((value < 1 || value > maximum)); then
		printf 'error: CONFIG_%s=%s is outside the supported range 1-%s in %s\n' \
			"${symbol}" "${value:-<missing>}" "${maximum}" "${config}" >&2
		exit 1
	fi
}

require_enabled_config() {
	local config=$1
	local symbol=$2

	grep -Eq "^CONFIG_${symbol}=[my]$" "${config}" || {
		printf 'error: CONFIG_%s is not enabled in %s\n' "${symbol}" "${config}" >&2
		exit 1
	}
}

reject_enabled_config() {
	local config=$1
	local symbol=$2

	if grep -Eq "^CONFIG_${symbol}=[my]$" "${config}"; then
		printf 'error: CONFIG_%s unexpectedly enabled in %s\n' "${symbol}" "${config}" >&2
		exit 1
	fi
}

# The exact p1_v2.0.0 contract collides with the retained private engine on
# ioctl numbers, payload sizes, V3.2 enum names, and asid_base[4], but it has no
# group_id field. Prove that source detection fails closed when that structural
# distinction is removed instead of treating the private engine as the public
# R2P1 (CIX P1) interface.
abi_fixture=${build_root}/npu-abi-collision
rm -rf -- "${abi_fixture}"
mkdir -p -- "${abi_fixture}/drivers/misc/armchina-npu/include"
sed '/__u32 group_id;/d' \
	"${source_dir}/drivers/misc/armchina-npu/include/armchina_aipu.h" \
	> "${abi_fixture}/drivers/misc/armchina-npu/include/armchina_aipu.h"
PYTHONDONTWRITEBYTECODE=1 python3 - "${kconfig_update}" "${abi_fixture}" <<'PY'
import importlib.util
import pathlib
import sys

spec = importlib.util.spec_from_file_location("kconfig_update", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
try:
    module.detect_npu_abi(pathlib.Path(sys.argv[2]))
except SystemExit as exc:
    if "request numbers and payload sizes alone are ambiguous" not in str(exc):
        raise
else:
    raise SystemExit("ambiguous private NPU job layout was accepted as P1")
PY

run_kconfig_target disabled allnoconfig
for symbol in \
	CIX_RADXA_ORION_O6 \
	CIX_RADXA_ORION_O6N \
	ARMCHINA_NPU_COMMON \
	ARMCHINA_NPU \
	ARMCHINA_NPU_R2P0 \
	VIDEO_CIX_ARMCB_ISP \
	CIX_THERMAL \
	DRM_CIX \
	PWM_SKY1 \
	SND_SOC_SOF_CIX_SKY1_NOCODEC \
	SND_SOC_SOF_COMPRESS \
	SND_SOC_COMPRESS \
	SND_COMPRESS_OFFLOAD; do
	reject_enabled_config "${build_root}/disabled/.config" "${symbol}"
done

run_kconfig_target allmod allmodconfig
require_config "${build_root}/allmod/.config" 'CONFIG_ARMCHINA_NPU_COMMON=m'
require_config "${build_root}/allmod/.config" 'CONFIG_ARMCHINA_NPU=m'
require_config "${build_root}/allmod/.config" 'CONFIG_ARMCHINA_NPU_R2P0=m'
require_config "${build_root}/allmod/.config" 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
require_config "${build_root}/allmod/.config" 'CONFIG_ARMCHINA_NPU_SOC_SKY1=y'
require_config "${build_root}/allmod/.config" 'CONFIG_VIDEO_CIX_ARMCB_ISP=m'
require_config "${build_root}/allmod/.config" 'CONFIG_VIDEO_LINLON=m'
# The CIX actor cache requires ACPI_PROCESSOR=y; allmodconfig selects it as m.
reject_enabled_config "${build_root}/allmod/.config" CIX_THERMAL
require_config "${build_root}/allmod/.config" 'CONFIG_PWM_SKY1=m'
require_config "${build_root}/allmod/.config" 'CONFIG_R8169=m'
reject_enabled_config "${build_root}/allmod/.config" R8126

# MVX directly uses rtc_time64_to_tm().  Its Kconfig must therefore own the
# hidden RTC library independently of board profiles and RTC_CLASS.
for mvx_state in module builtin; do
	build_dir=${build_root}/mvx-rtc-lib-${mvx_state}
	rm -rf -- "${build_dir}"
	mkdir -p -- "${build_dir}"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 allnoconfig
	"${source_dir}/scripts/config" --file "${build_dir}/.config" \
		--enable MODULES \
		--enable MEDIA_SUPPORT \
		--enable MEDIA_PLATFORM_SUPPORT \
		--enable VIDEO_DEV \
		--enable PM \
		--enable PM_DEVFREQ \
		--enable PM_OPP \
		--enable RESET_CONTROLLER \
		--disable RTC_CLASS
	if [[ ${mvx_state} == module ]]; then
		"${source_dir}/scripts/config" --file "${build_dir}/.config" \
			--module VIDEO_LINLON
	else
		"${source_dir}/scripts/config" --file "${build_dir}/.config" \
			--enable VIDEO_LINLON
	fi
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
	require_config "${build_dir}/.config" \
		"CONFIG_VIDEO_LINLON=$([[ ${mvx_state} == module ]] && printf m || printf y)"
	require_config "${build_dir}/.config" 'CONFIG_RTC_LIB=y'
	reject_enabled_config "${build_dir}/.config" RTC_CLASS
done

# Both Realtek drivers claim PCI 10ec:8126. The restored driver Kconfig must
# resolve an attempted dual-module configuration to one implementation rather
# than leaving binding to module-alias/load order.
build_dir=${build_root}/r8126-r8169-conflict
rm -rf -- "${build_dir}"
mkdir -p -- "${build_dir}"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
"${source_dir}/scripts/config" --file "${build_dir}/.config" \
	--module R8126 \
	--module R8169
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
require_config "${build_dir}/.config" 'CONFIG_R8169=m'
reject_enabled_config "${build_dir}/.config" R8126

# Isolate the platform applicability dependency: with all other direct NPU
# prerequisites available, a non-CIX, non-COMPILE_TEST build must force an
# explicit request off; COMPILE_TEST is the only permitted generic escape.
build_dir=${build_root}/npu-platform-boundary
rm -rf -- "${build_dir}"
mkdir -p -- "${build_dir}"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 allnoconfig
"${source_dir}/scripts/config" --file "${build_dir}/.config" \
	--enable MODULES \
	--enable OF \
	--enable DMABUF_HEAPS \
	--disable ARCH_CIX \
	--disable COMPILE_TEST \
	--module ARMCHINA_NPU \
	--module ARMCHINA_NPU_R2P0
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
require_config "${build_dir}/.config" 'CONFIG_OF=y'
require_config "${build_dir}/.config" 'CONFIG_DMA_SHARED_BUFFER=y'
reject_enabled_config "${build_dir}/.config" ARCH_CIX
reject_enabled_config "${build_dir}/.config" COMPILE_TEST
reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU_COMMON
reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU
reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU_R2P0
"${source_dir}/scripts/config" --file "${build_dir}/.config" \
	--enable COMPILE_TEST \
	--module ARMCHINA_NPU \
	--module ARMCHINA_NPU_R2P0
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
require_config "${build_dir}/.config" 'CONFIG_COMPILE_TEST=y'
require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_COMMON=m'
require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU=m'
require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_R2P0=m'
require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_SOC_SKY1=y'

run_kconfig_target allyes allyesconfig
require_config "${build_root}/allyes/.config" 'CONFIG_ARMCHINA_NPU_COMMON=y'
require_config "${build_root}/allyes/.config" 'CONFIG_ARMCHINA_NPU=y'
reject_enabled_config "${build_root}/allyes/.config" ARMCHINA_NPU_R2P0
require_config "${build_root}/allyes/.config" 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
require_config "${build_root}/allyes/.config" 'CONFIG_ARMCHINA_NPU_SOC_SKY1=y'
require_config "${build_root}/allyes/.config" 'CONFIG_VIDEO_CIX_ARMCB_ISP=y'
require_config "${build_root}/allyes/.config" 'CONFIG_VIDEO_LINLON=y'
require_config "${build_root}/allyes/.config" 'CONFIG_CIX_THERMAL=y'
require_config "${build_root}/allyes/.config" 'CONFIG_PWM_SKY1=y'
for name in allmod allyes; do
	for symbol in \
		ARMCHINA_NPU_ARCH_V1 \
		ARMCHINA_NPU_ARCH_V2 \
		ARMCHINA_NPU_ARCH_V3_2 \
		ARMCHINA_NPU_SOC_DEFAULT \
		ARMCHINA_NPU_SOC_R329; do
		reject_enabled_config "${build_root}/${name}/.config" "${symbol}"
	done
done

# The two backends claim the same Sky1 platform device and /dev/aipu node.
# Prove the Kconfig ownership contract explicitly: both may be modules for
# administrator-selected sequential use, while either built-in backend excludes
# the other.  The helper deliberately chooses the first layout for board
# profiles, but the other two remain valid direct Kconfig configurations.
for npu_layout in both-modules current-builtin r2p0-builtin; do
	build_dir=${build_root}/npu-layout-${npu_layout}
	rm -rf -- "${build_dir}"
	mkdir -p -- "${build_dir}"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 allnoconfig
	"${source_dir}/scripts/config" --file "${build_dir}/.config" \
		--enable MODULES \
		--enable ARCH_CIX \
		--enable OF \
		--enable DMABUF_HEAPS \
		--enable PM \
		--enable PM_DEVFREQ \
		--module ARM_SCMI_PROTOCOL \
		--module ARM_SCMI_PERF_DOMAIN
	case ${npu_layout} in
	both-modules)
		"${source_dir}/scripts/config" --file "${build_dir}/.config" \
			--module ARMCHINA_NPU \
			--module ARMCHINA_NPU_R2P0 \
			--enable ARMCHINA_NPU_ARCH_V3 \
			--enable ARMCHINA_NPU_SOC_SKY1
		;;
	current-builtin)
		"${source_dir}/scripts/config" --file "${build_dir}/.config" \
			--enable ARMCHINA_NPU \
			--enable ARMCHINA_NPU_R2P0 \
			--enable ARMCHINA_NPU_ARCH_V3 \
			--enable ARMCHINA_NPU_SOC_SKY1
		;;
	r2p0-builtin)
		"${source_dir}/scripts/config" --file "${build_dir}/.config" \
			--disable ARMCHINA_NPU \
			--enable ARMCHINA_NPU_R2P0
		;;
	esac
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
	require_config "${build_dir}/.config" 'CONFIG_PM=y'
	require_config "${build_dir}/.config" 'CONFIG_PM_GENERIC_DOMAINS=y'
	require_config "${build_dir}/.config" 'CONFIG_PM_DEVFREQ=y'
	require_config "${build_dir}/.config" 'CONFIG_ARM_SCMI_PROTOCOL=m'
	require_config "${build_dir}/.config" 'CONFIG_ARM_SCMI_PERF_DOMAIN=m'
	require_enabled_config "${build_dir}/.config" DEVFREQ_GOV_USERSPACE
	case ${npu_layout} in
	both-modules)
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_COMMON=m'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU=m'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_R2P0=m'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_SOC_SKY1=y'
		;;
	current-builtin)
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_COMMON=y'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU=y'
		reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU_R2P0
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_SOC_SKY1=y'
		;;
	r2p0-builtin)
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_COMMON=y'
		reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_R2P0=y'
		# The separate legacy backend is source-scoped to Sky1/V3 and does
		# not consume the R2P1 backend's architecture-selection symbols.
		reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU_ARCH_V3
		reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU_SOC_SKY1
		;;
	esac
done

# Prove that the generated 90050 menu is independently useful, rather than
# relying on the configuration helper to hide incomplete imply dependencies.
for preference in module builtin; do
	build_dir=${build_root}/menu-o6-acpi-${preference}
	rm -rf -- "${build_dir}"
	mkdir -p -- "${build_dir}"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
	# Model an older configuration which has never answered the generated
	# accelerator and CIX thermal prerequisite symbols. An explicit user choice
	# must remain authoritative; leaving defconfig's answered values here would
	# test that override policy rather than the generated menu's default closure.
	"${source_dir}/scripts/config" --file "${build_dir}/.config" \
		--undefine CIX_RADXA_OPTIONAL_ACCELERATORS \
		--undefine DMA_SHARED_BUFFER \
		--undefine PM_DEVFREQ \
		--undefine DEVFREQ_GOV_USERSPACE \
		--disable ARM_HISI_UNCORE_DEVFREQ \
		--disable ARM_IMX_BUS_DEVFREQ \
		--disable ARM_IMX8M_DDRC_DEVFREQ \
		--undefine I2C \
		--undefine PM \
		--undefine RESET_CONTROLLER \
		--undefine COMMON_CLK \
		--undefine REGULATOR \
		--undefine REGULATOR_FIXED_VOLTAGE \
		--undefine R8169 \
		--undefine R8126 \
		--undefine ARMCHINA_NPU \
		--undefine ARMCHINA_NPU_R2P0 \
		--undefine ARMCHINA_NPU_ARCH_V1 \
		--undefine ARMCHINA_NPU_ARCH_V2 \
		--undefine ARMCHINA_NPU_ARCH_V3 \
		--undefine ARMCHINA_NPU_ARCH_V3_2 \
		--undefine ARMCHINA_NPU_SOC_DEFAULT \
		--undefine ARMCHINA_NPU_SOC_R329 \
		--undefine ARMCHINA_NPU_SOC_SKY1 \
		--undefine MEDIA_SUPPORT \
		--disable MEDIA_SUPPORT_FILTER \
		--undefine MEDIA_CAMERA_SUPPORT \
		--undefine MEDIA_PLATFORM_SUPPORT \
		--undefine MEDIA_PLATFORM_DRIVERS \
		--undefine VIDEO_DEV \
		--undefine MEDIA_CONTROLLER \
		--undefine VIDEO_LINLON \
		--undefine VIDEO_CIX_ARMCB_ISP \
		--undefine THERMAL \
		--undefine THERMAL_GOV_POWER_ALLOCATOR \
		--undefine CPU_FREQ \
		--undefine ENERGY_MODEL \
		--undefine ACPI_PROCESSOR \
		--undefine ACPI_THERMAL \
		--undefine ACPI_CPPC_CPUFREQ \
		--undefine CIX_THERMAL
	if [[ ${preference} == builtin ]]; then
		"${source_dir}/scripts/config" --file "${build_dir}/.config" --disable MODULES
		driver_state=y
	else
		driver_state=m
	fi
	"${source_dir}/scripts/config" --file "${build_dir}/.config" \
		--enable ARCH_CIX \
		--enable CIX_RADXA_ORION_O6 \
		--enable CIX_RADXA_ORION_ACPI
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig

	require_config "${build_dir}/.config" "CONFIG_CIX_RADXA_OPTIONAL_ACCELERATORS=${driver_state}"
	require_config "${build_dir}/.config" 'CONFIG_DMA_SHARED_BUFFER=y'
	require_config "${build_dir}/.config" 'CONFIG_PM_DEVFREQ=y'
	# CIX_BUS_PERF defaults built-in for ARCH_CIX and deliberately selects the
	# userspace governor which provides its explicit policy control surface.
	require_config "${build_dir}/.config" 'CONFIG_CIX_BUS_PERF=y'
	require_config "${build_dir}/.config" 'CONFIG_DEVFREQ_GOV_USERSPACE=y'
	require_config "${build_dir}/.config" "CONFIG_I2C=${driver_state}"
	require_config "${build_dir}/.config" 'CONFIG_PM=y'
	require_config "${build_dir}/.config" 'CONFIG_RESET_CONTROLLER=y'
	require_config "${build_dir}/.config" 'CONFIG_COMMON_CLK=y'
	require_config "${build_dir}/.config" 'CONFIG_REGULATOR=y'
	require_config "${build_dir}/.config" "CONFIG_REGULATOR_FIXED_VOLTAGE=${driver_state}"
	require_config "${build_dir}/.config" "CONFIG_ARMCHINA_NPU=${driver_state}"
	require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
	require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_SOC_SKY1=y'
	for symbol in \
		ARMCHINA_NPU_ARCH_V1 \
		ARMCHINA_NPU_ARCH_V2 \
		ARMCHINA_NPU_ARCH_V3_2; do
		reject_enabled_config "${build_dir}/.config" "${symbol}"
	done
	require_config "${build_dir}/.config" "CONFIG_MEDIA_SUPPORT=${driver_state}"
	require_config "${build_dir}/.config" "CONFIG_VIDEO_DEV=${driver_state}"
	require_config "${build_dir}/.config" 'CONFIG_MEDIA_CAMERA_SUPPORT=y'
	require_config "${build_dir}/.config" 'CONFIG_MEDIA_PLATFORM_SUPPORT=y'
	require_config "${build_dir}/.config" 'CONFIG_MEDIA_PLATFORM_DRIVERS=y'
	require_config "${build_dir}/.config" 'CONFIG_MEDIA_CONTROLLER=y'
	reject_enabled_config "${build_dir}/.config" MEDIA_SUPPORT_FILTER
	require_config "${build_dir}/.config" "CONFIG_VIDEO_LINLON=${driver_state}"
	require_config "${build_dir}/.config" "CONFIG_VIDEO_CIX_ARMCB_ISP=${driver_state}"
	require_config "${build_dir}/.config" 'CONFIG_THERMAL=y'
	require_config "${build_dir}/.config" 'CONFIG_THERMAL_GOV_POWER_ALLOCATOR=y'
	require_config "${build_dir}/.config" 'CONFIG_CPU_FREQ=y'
	require_config "${build_dir}/.config" 'CONFIG_ENERGY_MODEL=y'
	require_config "${build_dir}/.config" 'CONFIG_ACPI_PROCESSOR=y'
	require_config "${build_dir}/.config" 'CONFIG_ACPI_THERMAL=y'
	require_config "${build_dir}/.config" 'CONFIG_ACPI_CPPC_CPUFREQ=y'
	require_config "${build_dir}/.config" 'CONFIG_CIX_THERMAL=y'
	require_config "${build_dir}/.config" "CONFIG_R8126=${driver_state}"
	reject_enabled_config "${build_dir}/.config" R8169
done

# An explicit per-feature user override must remain authoritative even when the
# board's default buckets are enabled.
build_dir=${build_root}/menu-o6-acpi-user-overrides
rm -rf -- "${build_dir}"
mkdir -p -- "${build_dir}"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
"${source_dir}/scripts/config" --file "${build_dir}/.config" \
	--enable ARCH_CIX \
	--enable CIX_RADXA_ORION_O6 \
	--enable CIX_RADXA_ORION_ACPI \
	--module CIX_RADXA_OPTIONAL_ACCELERATORS \
	--disable ARMCHINA_NPU \
	--disable ARMCHINA_NPU_R2P0 \
	--disable VIDEO_LINLON \
	--disable VIDEO_CIX_ARMCB_ISP \
	--disable CIX_THERMAL
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
require_config "${build_dir}/.config" 'CONFIG_CIX_RADXA_OPTIONAL_ACCELERATORS=m'
for symbol in \
	ARMCHINA_NPU \
	ARMCHINA_NPU_R2P0 \
	VIDEO_LINLON \
	VIDEO_CIX_ARMCB_ISP \
	CIX_THERMAL; do
	reject_enabled_config "${build_dir}/.config" "${symbol}"
done

# Exercise the end-user hardware breadth independently of the broad build
# matrix below. These checks deliberately start from defconfig so dependency
# closure, not only the Python tuple composition tests, determines the result.
for hardware_profile in server desktop; do
	build_dir=${build_root}/hardware-${hardware_profile}-o6-acpi
	rm -rf -- "${build_dir}"
	mkdir -p -- "${build_dir}"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
	python3 "${kconfig_update}" \
		--mode update \
		--kernel-tree "${source_dir}" \
		--board-profile o6-acpi \
		--hardware-profile "${hardware_profile}" \
		--cix-patches yes \
		--require-npu-abi "${npu_abi}" \
		--driver-preference module \
		--rewrite-existing-driver-states \
		--apply \
		"${build_dir}/.config" >"${build_dir}/kconfig-update.diff"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig

	require_config "${build_dir}/.config" 'CONFIG_CIX_BUS_PERF=m'
	require_config "${build_dir}/.config" 'CONFIG_CIX_DDR_LP=m'
	reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU
	reject_enabled_config "${build_dir}/.config" ARMCHINA_NPU_R2P0
	reject_enabled_config "${build_dir}/.config" VIDEO_LINLON
	reject_enabled_config "${build_dir}/.config" VIDEO_CIX_ARMCB_ISP
	reject_enabled_config "${build_dir}/.config" PWM_SKY1
	reject_enabled_config "${build_dir}/.config" TOUCHSCREEN_GOODIX
	if [[ ${hardware_profile} == server ]]; then
		reject_enabled_config "${build_dir}/.config" DRM_PANTHOR
		reject_enabled_config "${build_dir}/.config" DRM_TRILIN_DPSUB
		require_config "${build_dir}/.config" 'CONFIG_SND_HDA_CIX_IPBLOQ=m'
		reject_enabled_config "${build_dir}/.config" SND_SOC_SKY1_SOUND_CARD
	else
		require_config "${build_dir}/.config" 'CONFIG_DRM_PANTHOR=m'
		require_config "${build_dir}/.config" 'CONFIG_DRM_TRILIN_DPSUB=m'
		require_config "${build_dir}/.config" 'CONFIG_SND_HDA_CIX_IPBLOQ=m'
		require_config "${build_dir}/.config" 'CONFIG_SND_SOC_SKY1_SOUND_CARD=m'
	fi
done

# The niche touchscreen selector intentionally closes over the eDP display
# path while leaving the independent GPU, NPU and VPU/ISP groups disabled.
build_dir=${build_root}/hardware-server-touchscreen-o6-acpi
rm -rf -- "${build_dir}"
mkdir -p -- "${build_dir}"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--hardware-profile server \
	--with-touchscreen \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--driver-preference module \
	--rewrite-existing-driver-states \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-update.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
for expected in \
	DRM_TRILIN_DPSUB \
	PWM_SKY1 \
	TOUCHSCREEN_GOODIX \
	SND_HDA_CIX_IPBLOQ \
	SND_SOC_SKY1_SOUND_CARD; do
	require_config "${build_dir}/.config" "CONFIG_${expected}=m"
done
for omitted in \
	DRM_PANTHOR \
	ARMCHINA_NPU \
	ARMCHINA_NPU_R2P0 \
	VIDEO_LINLON \
	VIDEO_CIX_ARMCB_ISP; do
	reject_enabled_config "${build_dir}/.config" "${omitted}"
done

# Explicit graphics and audio profiles override the broad hardware profile.
# Display audio closes over its required display pipeline; the automatic audio
# profile follows the resolved graphics pipeline.
build_dir=${build_root}/hardware-explicit-profiles-o6-acpi
rm -rf -- "${build_dir}"
mkdir -p -- "${build_dir}"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--hardware-profile full \
	--graphics-profile gpu \
	--audio-profile auto \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--driver-preference module \
	--rewrite-existing-driver-states \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-update.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
require_config "${build_dir}/.config" 'CONFIG_DRM_PANTHOR=m'
require_config "${build_dir}/.config" 'CONFIG_SND_HDA_CIX_IPBLOQ=m'
for omitted in \
	DRM_TRILIN_DPSUB \
	SND_SOC_SKY1_SOUND_CARD \
	VIDEO_LINLON \
	VIDEO_CIX_ARMCB_ISP; do
	reject_enabled_config "${build_dir}/.config" "${omitted}"
done

build_dir=${build_root}/hardware-display-audio-o6-acpi
rm -rf -- "${build_dir}"
mkdir -p -- "${build_dir}"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--hardware-profile server \
	--graphics-profile none \
	--audio-profile display \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--driver-preference module \
	--rewrite-existing-driver-states \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-update.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
require_config "${build_dir}/.config" 'CONFIG_DRM_TRILIN_DPSUB=m'
require_config "${build_dir}/.config" 'CONFIG_SND_SOC_SKY1_SOUND_CARD=m'
reject_enabled_config "${build_dir}/.config" DRM_PANTHOR
reject_enabled_config "${build_dir}/.config" SND_HDA_CIX_IPBLOQ

for profile in o6-acpi o6-dt o6n-acpi o6n-dt; do
	case ${profile} in
	o6-*)
		board_symbol=CIX_RADXA_ORION_O6
		opposite_board_symbol=CIX_RADXA_ORION_O6N
		;;
	o6n-*)
		board_symbol=CIX_RADXA_ORION_O6N
		opposite_board_symbol=CIX_RADXA_ORION_O6
		;;
	esac
	case ${profile} in
	*-acpi)
		interface_symbol=CIX_RADXA_ORION_ACPI
		opposite_interface_symbol=CIX_RADXA_ORION_DT
		;;
	*-dt)
		interface_symbol=CIX_RADXA_ORION_DT
		opposite_interface_symbol=CIX_RADXA_ORION_ACPI
		;;
	esac

	for preference in module builtin; do
		build_dir=${build_root}/${profile}-${preference}
		rm -rf -- "${build_dir}"
		mkdir -p -- "${build_dir}"
		make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
		# Ubuntu-derived and other generic arm64 configurations do not carry
		# ARCH_CIX.  Prove that the profile updater enables the platform parent
		# rather than inheriting it accidentally from the CIX defconfig. Seed
		# the former broad NPU architecture set as well, proving that the final
		# scoped Kconfig cannot retain stale non-V3 selections.
		"${source_dir}/scripts/config" --file "${build_dir}/.config" \
			--disable ARCH_CIX \
			--disable CGROUPS \
			--disable MEMCG \
			--disable MEDIA_SUPPORT_FILTER \
			--disable ARM_HISI_UNCORE_DEVFREQ \
			--disable ARM_IMX_BUS_DEVFREQ \
			--disable ARM_IMX8M_DDRC_DEVFREQ \
			--undefine DEVFREQ_GOV_USERSPACE \
			--enable ARMCHINA_NPU_ARCH_V1 \
			--enable ARMCHINA_NPU_ARCH_V2 \
			--enable ARMCHINA_NPU_ARCH_V3_2
		python3 "${kconfig_update}" \
			--mode update \
			--kernel-tree "${source_dir}" \
			--board-profile "${profile}" \
			--hardware-profile full \
			--cix-patches yes \
			--with-npu \
			--with-edp \
			--require-npu-abi "${npu_abi}" \
			--driver-preference "${preference}" \
			--rewrite-existing-driver-states \
			--apply \
			"${build_dir}/.config" > "${build_dir}/kconfig-update.diff"
		# These distribution-policy options are deliberately outside the board
		# helper's remit; prove that a disabled input remains disabled.
		require_config "${build_dir}/.config" '# CONFIG_CGROUPS is not set'
		require_config "${build_dir}/.config" '# CONFIG_MEMCG is not set'
		printf '%s %s profile update: %s lines\n' \
			"${profile}" "${preference}" \
			"$(wc -l < "${build_dir}/kconfig-update.diff")"
		make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig

		require_config "${build_dir}/.config" 'CONFIG_ARCH_CIX=y'
		require_config "${build_dir}/.config" "CONFIG_${board_symbol}=y"
		require_config "${build_dir}/.config" "CONFIG_${interface_symbol}=y"
		reject_enabled_config "${build_dir}/.config" "${opposite_board_symbol}"
		reject_enabled_config "${build_dir}/.config" "${opposite_interface_symbol}"
		require_config "${build_dir}/.config" 'CONFIG_CIX_RADXA_ESSENTIAL=y'
		require_config "${build_dir}/.config" "CONFIG_PWM_SKY1=$([[ ${preference} == module ]] && printf m || printf y)"
		require_config "${build_dir}/.config" 'CONFIG_DMA_SHARED_BUFFER=y'
		require_config "${build_dir}/.config" 'CONFIG_I2C=y'
		require_config "${build_dir}/.config" 'CONFIG_PM=y'
		require_config "${build_dir}/.config" 'CONFIG_PM_SLEEP=y'
		require_config "${build_dir}/.config" 'CONFIG_PM_SLEEP_SMP=y'
		require_config "${build_dir}/.config" 'CONFIG_SUSPEND=y'
		require_config "${build_dir}/.config" 'CONFIG_SUSPEND_FREEZER=y'
		require_config "${build_dir}/.config" 'CONFIG_RESET_CONTROLLER=y'
		require_config "${build_dir}/.config" 'CONFIG_COMMON_CLK=y'
		require_config "${build_dir}/.config" 'CONFIG_REGULATOR=y'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_COMMON=m'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU=m'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_R2P0=m'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
		require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_SOC_SKY1=y'
		for symbol in \
			ARMCHINA_NPU_ARCH_V1 \
			ARMCHINA_NPU_ARCH_V2 \
			ARMCHINA_NPU_ARCH_V3_2 \
			ARMCHINA_NPU_SOC_DEFAULT \
			ARMCHINA_NPU_SOC_R329; do
			reject_enabled_config "${build_dir}/.config" "${symbol}"
		done
		require_config "${build_dir}/.config" 'CONFIG_PM_DEVFREQ=y'
		require_config "${build_dir}/.config" "CONFIG_DEVFREQ_GOV_USERSPACE=$([[ ${preference} == module ]] && printf m || printf y)"
		require_config "${build_dir}/.config" "CONFIG_MEDIA_SUPPORT=$([[ ${preference} == module ]] && printf m || printf y)"
		require_config "${build_dir}/.config" "CONFIG_VIDEO_DEV=$([[ ${preference} == module ]] && printf m || printf y)"
		require_config "${build_dir}/.config" 'CONFIG_MEDIA_CAMERA_SUPPORT=y'
		require_config "${build_dir}/.config" 'CONFIG_MEDIA_PLATFORM_SUPPORT=y'
		require_config "${build_dir}/.config" 'CONFIG_MEDIA_PLATFORM_DRIVERS=y'
		require_config "${build_dir}/.config" 'CONFIG_MEDIA_CONTROLLER=y'
		reject_enabled_config "${build_dir}/.config" MEDIA_SUPPORT_FILTER
		require_config "${build_dir}/.config" "CONFIG_VIDEO_LINLON=$([[ ${preference} == module ]] && printf m || printf y)"
		require_config "${build_dir}/.config" "CONFIG_VIDEO_CIX_ARMCB_ISP=$([[ ${preference} == module ]] && printf m || printf y)"
		if [[ ${profile} == *-acpi ]]; then
			require_enabled_config "${build_dir}/.config" REGULATOR_FIXED_VOLTAGE
			require_config "${build_dir}/.config" 'CONFIG_THERMAL=y'
			require_config "${build_dir}/.config" 'CONFIG_THERMAL_GOV_POWER_ALLOCATOR=y'
			require_config "${build_dir}/.config" 'CONFIG_THERMAL_GOV_STEP_WISE=y'
			require_config "${build_dir}/.config" 'CONFIG_CPU_FREQ=y'
			require_config "${build_dir}/.config" 'CONFIG_ENERGY_MODEL=y'
			require_config "${build_dir}/.config" 'CONFIG_ACPI_PROCESSOR=y'
			require_config "${build_dir}/.config" "CONFIG_ACPI_THERMAL=$([[ ${preference} == module ]] && printf m || printf y)"
			require_config "${build_dir}/.config" 'CONFIG_ACPI_CPPC_CPUFREQ=y'
			require_config "${build_dir}/.config" 'CONFIG_CIX_THERMAL=y'
		else
			reject_enabled_config "${build_dir}/.config" CIX_THERMAL
		fi
		reject_enabled_config "${build_dir}/.config" CIX_SCMI_ENERGY_MODEL
		if [[ ${profile} == o6-* ]]; then
			require_config "${build_dir}/.config" "CONFIG_R8126=$([[ ${preference} == module ]] && printf m || printf y)"
			reject_enabled_config "${build_dir}/.config" R8169
		else
			require_config "${build_dir}/.config" "CONFIG_R8169=$([[ ${preference} == module ]] && printf m || printf y)"
			reject_enabled_config "${build_dir}/.config" R8126
		fi
	done
done

# MPAM.aml is inert when arm64 MPAM is disabled. Prove that the Linux 7.2
# Kconfig opt-in closes over the hidden resctrl integration while the ordinary
# DSDT profile and its initramfs path remain unchanged.
if [[ ${kernel_line} == 7.1 || ${kernel_line} == 7.2 ]]; then
	build_dir=${build_root}/mpam-kconfig-o6-acpi
	rm -rf -- "${build_dir}"
	mkdir -p -- "${build_dir}"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
	python3 "${kconfig_update}" \
		--mode update \
		--kernel-tree "${source_dir}" \
		--board-profile o6-acpi \
		--firmware 1.2 \
		--cix-patches yes \
		--require-npu-abi "${npu_abi}" \
		--acpi-table-upgrade dsdt \
		--apply \
		"${build_dir}/.config" >"${build_dir}/kconfig-update.diff"
	"${source_dir}/scripts/config" --file "${build_dir}/.config" \
		--enable ARM64_MPAM \
		--enable RESCTRL_FS
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
	require_config "${build_dir}/.config" 'CONFIG_ARM64_MPAM=y'
	require_config "${build_dir}/.config" 'CONFIG_RESCTRL_FS=y'
	require_config "${build_dir}/.config" 'CONFIG_ARM64_MPAM_RESCTRL_FS=y'
	require_config "${build_dir}/.config" \
		'CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6/1.2/initramfs-dsdt.list"'

	# CIX_DSP_RPROC may be modular, but its pre-linear-map ownership
	# correction and fixed heap must remain built in. Prove that the public
	# helper selects the complete XAF transport boundary without enabling SOF.
	build_dir=${build_root}/hifi5-kconfig-o6-acpi
	rm -rf -- "${build_dir}"
	mkdir -p -- "${build_dir}"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
	"${source_dir}/scripts/config" --file "${build_dir}/.config" \
		--disable SND_SOC_SOF_TOPLEVEL
	python3 "${kconfig_update}" \
		--mode update \
		--kernel-tree "${source_dir}" \
		--board-profile o6-acpi \
		--driver-preference module \
		--cix-patches yes \
		--require-npu-abi "${npu_abi}" \
		--enable-hifi5-dsp xaf \
		--apply \
		"${build_dir}/.config" >"${build_dir}/kconfig-update.diff"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
	require_config "${build_dir}/.config" 'CONFIG_CIX_DSP_RPROC=m'
	require_config "${build_dir}/.config" 'CONFIG_CIX_HIFI5_FIRMWARE_XAF=y'
	reject_enabled_config "${build_dir}/.config" CIX_HIFI5_FIRMWARE_SOF
	require_config "${build_dir}/.config" 'CONFIG_CIX_HIFI5_COMMON=y'
	require_config "${build_dir}/.config" 'CONFIG_DMABUF_HEAPS=y'
	require_config "${build_dir}/.config" 'CONFIG_DMABUF_HEAPS_CIX_DSP=y'
	require_config "${build_dir}/.config" 'CONFIG_RPMSG_VIRTIO=m'
	require_config "${build_dir}/.config" 'CONFIG_RPMSG_CHAR=m'
	require_config "${build_dir}/.config" 'CONFIG_RPMSG_CTRL=m'
	if grep -qx 'CONFIG_ARM64_4K_PAGES=y' "${build_dir}/.config"; then
		require_integer_config_at_most \
			"${build_dir}/.config" PAGE_BLOCK_MAX_ORDER 10
	elif grep -qx 'CONFIG_ARM64_16K_PAGES=y' "${build_dir}/.config"; then
		require_integer_config_at_most \
			"${build_dir}/.config" PAGE_BLOCK_MAX_ORDER 11
	else
		require_integer_config_at_most \
			"${build_dir}/.config" PAGE_BLOCK_MAX_ORDER 9
	fi
	reject_enabled_config "${build_dir}/.config" SND_SOC_SOF_TOPLEVEL
	reject_enabled_config "${build_dir}/.config" SND_SOC_SOF_COMPRESS

	# The alternative owner is modular and intentionally excludes XAF.  Its
	# mailbox doorbells exist only in the full DSDT profile, so the helper must
	# also retain that exact initramfs selection.  Exercise both tristate
	# ownership layouts because the hidden compressed-offload symbols propagate
	# differently from a modular and a built-in SOF owner.
	for preference in module builtin; do
		build_dir=${build_root}/hifi5-sof-kconfig-o6-acpi-${preference}
		rm -rf -- "${build_dir}"
		mkdir -p -- "${build_dir}"
		make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
		python3 "${kconfig_update}" \
			--mode update \
			--kernel-tree "${source_dir}" \
			--board-profile o6-acpi \
			--firmware 1.2 \
			--cix-patches yes \
			--driver-preference "${preference}" \
			--rewrite-existing-driver-states \
			--require-npu-abi "${npu_abi}" \
			--acpi-table-upgrade dsdt \
			--enable-hifi5-dsp sof \
			--apply \
			"${build_dir}/.config" >"${build_dir}/kconfig-update.diff"
		make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
		expected=$([[ ${preference} == module ]] && printf m || printf y)
		require_config "${build_dir}/.config" 'CONFIG_CIX_HIFI5_FIRMWARE_SOF=y'
		require_config "${build_dir}/.config" "CONFIG_SOUND=${expected}"
		require_config "${build_dir}/.config" "CONFIG_SND=${expected}"
		require_config "${build_dir}/.config" "CONFIG_SND_SOC=${expected}"
		require_config "${build_dir}/.config" "CONFIG_SND_SOC_SOF_CIX_SKY1=${expected}"
		require_config "${build_dir}/.config" 'CONFIG_CIX_HIFI5_COMMON=y'
		require_config "${build_dir}/.config" "CONFIG_SND_SOC_SOF=${expected}"
		require_config "${build_dir}/.config" "CONFIG_SND_SOC_SOF_ACPI_DEV=${expected}"
		require_config "${build_dir}/.config" \
			"CONFIG_SND_SOC_SOF_CIX_SKY1_NOCODEC=${expected}"
		reject_enabled_config "${build_dir}/.config" SND_SOC_SOF_NOCODEC
		require_config "${build_dir}/.config" "CONFIG_SND_SOC_SOF_XTENSA=${expected}"
		require_config "${build_dir}/.config" 'CONFIG_SND_SOC_SOF_COMPRESS=y'
		require_config "${build_dir}/.config" 'CONFIG_SND_SOC_COMPRESS=y'
		require_config "${build_dir}/.config" "CONFIG_SND_COMPRESS_OFFLOAD=${expected}"
		reject_enabled_config "${build_dir}/.config" CIX_HIFI5_FIRMWARE_XAF
		reject_enabled_config "${build_dir}/.config" CIX_DSP_RPROC
		for symbol in \
			SND_SOC_SOF_FORCE_PROBE_WORKQUEUE \
			SND_SOC_SOF_NOCODEC_SUPPORT \
			SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT \
			SND_SOC_SOF_STRICT_ABI_CHECKS \
			SND_SOC_SOF_ALLOW_FALLBACK_TO_NEWER_IPC_VERSION; do
			reject_enabled_config "${build_dir}/.config" "${symbol}"
		done
		require_config "${build_dir}/.config" \
			'CONFIG_INITRAMFS_SOURCE="/usr/src/linux/cix-acpi-table-upgrade/o6/1.2/initramfs-dsdt.list"'
	done
fi

# Keep the diagnostic profile opt-in and prove that a maintainer can prepare a
# single runtime-qualification build without enabling the heavyweight memory
# corruption profile.
build_dir=${build_root}/runtime-qualification-o6-acpi
rm -rf -- "${build_dir}"
mkdir -p -- "${build_dir}"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 defconfig
"${source_dir}/scripts/config" --file "${build_dir}/.config" \
	--enable KALLSYMS \
	--enable STACKTRACE
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-production-update.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
for symbol in \
	DEBUG_MISC \
	DEBUG_FS \
	PM_DEBUG \
	PM_ADVANCED_DEBUG \
	PM_SLEEP_DEBUG \
	THERMAL_STATISTICS \
	CPU_FREQ_STAT \
	IOMMU_DEBUGFS \
	FTRACE \
	TRACING \
	EVENT_TRACING \
	SND_SOC_SOF_DEVELOPER_SUPPORT \
	SND_SOC_SOF_DEBUG \
	SND_SOC_SOF_DEBUG_ENABLE_DEBUGFS_CACHE \
	SND_SOC_SOF_DEBUG_ENABLE_FIRMWARE_TRACE \
	SND_SOC_SOF_FORCE_PROBE_WORKQUEUE \
	SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT \
	SND_SOC_SOF_FORCE_NOCODEC_MODE \
	SND_SOC_SOF_DEBUG_XRUN_STOP \
	SND_SOC_SOF_DEBUG_FORCE_IPC_POSITION \
	SND_SOC_SOF_DEBUG_IPC_FLOOD_TEST \
	SND_SOC_SOF_DEBUG_IPC_MSG_INJECTOR \
	SND_SOC_SOF_DEBUG_IPC_KERNEL_INJECTOR \
	SND_SOC_SOF_DEBUG_RETAIN_DSP_CONTEXT \
	SND_SOC_SOF_DEBUG_VERBOSE_IPC \
	SLUB_DEBUG \
	FAULT_INJECTION \
	FAULT_INJECTION_DEBUG_FS \
	FAIL_PAGE_ALLOC \
	FAILSLAB; do
	reject_enabled_config "${build_dir}/.config" "${symbol}"
done
for symbol in \
	KALLSYMS \
	STACKTRACE; do
	require_config "${build_dir}/.config" "CONFIG_${symbol}=y"
done
python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--enable-runtime-qualification \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-update.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
for symbol in \
	DEBUG_KERNEL \
	DEBUG_MISC \
	DEBUG_FS \
	PM_DEBUG \
	PM_ADVANCED_DEBUG \
	PM_SLEEP_DEBUG \
	THERMAL_STATISTICS \
	CPU_FREQ_STAT \
	IOMMU_DEBUGFS \
	FTRACE \
	TRACING \
	EVENT_TRACING \
	SND_SOC_SOF_DEVELOPER_SUPPORT \
	SND_SOC_SOF_DEBUG \
	SND_SOC_SOF_DEBUG_ENABLE_DEBUGFS_CACHE \
	SND_SOC_SOF_DEBUG_ENABLE_FIRMWARE_TRACE; do
	require_config "${build_dir}/.config" "CONFIG_${symbol}=y"
done
for symbol in \
	SND_SOC_SOF_FORCE_PROBE_WORKQUEUE \
	SND_SOC_SOF_NOCODEC_SUPPORT \
	SND_SOC_SOF_STRICT_ABI_CHECKS \
	SND_SOC_SOF_ALLOW_FALLBACK_TO_NEWER_IPC_VERSION \
	SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT \
	SND_SOC_SOF_FORCE_NOCODEC_MODE \
	SND_SOC_SOF_DEBUG_XRUN_STOP \
	SND_SOC_SOF_DEBUG_FORCE_IPC_POSITION \
	SND_SOC_SOF_DEBUG_IPC_FLOOD_TEST \
	SND_SOC_SOF_DEBUG_IPC_MSG_INJECTOR \
	SND_SOC_SOF_DEBUG_IPC_KERNEL_INJECTOR \
	SND_SOC_SOF_DEBUG_RETAIN_DSP_CONTEXT \
	SND_SOC_SOF_DEBUG_VERBOSE_IPC \
	SLUB_DEBUG \
	FAULT_INJECTION \
	FAULT_INJECTION_DEBUG_FS \
	FAIL_PAGE_ALLOC \
	FAILSLAB; do
	reject_enabled_config "${build_dir}/.config" "${symbol}"
done
require_config "${build_dir}/.config" 'CONFIG_EXPERT=y'
reject_enabled_config "${build_dir}/.config" DMA_API_DEBUG
reject_enabled_config "${build_dir}/.config" KASAN

# Prove that the heavier memory-debug selector is also an exact profile switch:
# it disables runtime-only facilities, retains shared tracing/debug
# prerequisites, and is later unioned with the other diagnostic profiles.
python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--enable-kernel-memory-debug \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-memory-debug-update.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
for symbol in \
	DEBUG_KERNEL \
	DEBUG_FS \
	DMA_API_DEBUG \
	IOMMU_DEBUGFS \
	KFENCE \
	PAGE_OWNER \
	DEBUG_VM \
	SLUB_DEBUG \
	UBSAN \
	HARDENED_USERCOPY \
	FTRACE \
	TRACING; do
	require_config "${build_dir}/.config" "CONFIG_${symbol}=y"
done
for symbol in \
	PM_DEBUG \
	PM_ADVANCED_DEBUG \
	PM_SLEEP_DEBUG \
	THERMAL_STATISTICS \
	CPU_FREQ_STAT \
	SND_SOC_SOF_DEVELOPER_SUPPORT \
	SND_SOC_SOF_DEBUG \
	SND_SOC_SOF_DEBUG_ENABLE_DEBUGFS_CACHE \
	SND_SOC_SOF_DEBUG_ENABLE_FIRMWARE_TRACE \
	SND_SOC_SOF_FORCE_PROBE_WORKQUEUE \
	SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT \
	SND_SOC_SOF_FORCE_NOCODEC_MODE \
	SND_SOC_SOF_DEBUG_XRUN_STOP \
	SND_SOC_SOF_DEBUG_FORCE_IPC_POSITION \
	SND_SOC_SOF_DEBUG_IPC_FLOOD_TEST \
	SND_SOC_SOF_DEBUG_IPC_MSG_INJECTOR \
	SND_SOC_SOF_DEBUG_IPC_KERNEL_INJECTOR \
	SND_SOC_SOF_DEBUG_RETAIN_DSP_CONTEXT \
	SND_SOC_SOF_DEBUG_VERBOSE_IPC \
	FAULT_INJECTION \
	FAULT_INJECTION_DEBUG_FS \
	FAIL_PAGE_ALLOC \
	FAILSLAB; do
	reject_enabled_config "${build_dir}/.config" "${symbol}"
done

# Fault injection is a third exact profile: it exposes bounded page/slab
# failure controls without retaining the runtime or heavyweight memory-debug
# instrumentation, and it supplies only the shared prerequisites it needs.
python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--enable-fault-injection \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-fault-injection-update.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
for symbol in \
	DEBUG_KERNEL \
	DEBUG_FS \
	STACKTRACE \
	FAULT_INJECTION \
	FAULT_INJECTION_DEBUG_FS \
	FAIL_PAGE_ALLOC \
	FAILSLAB; do
	require_config "${build_dir}/.config" "CONFIG_${symbol}=y"
done
for symbol in \
	DMA_API_DEBUG \
	KASAN \
	SLUB_DEBUG \
	PM_DEBUG \
	PM_ADVANCED_DEBUG \
	PM_SLEEP_DEBUG \
	THERMAL_STATISTICS \
	CPU_FREQ_STAT \
	SND_SOC_SOF_DEVELOPER_SUPPORT \
	SND_SOC_SOF_DEBUG; do
	reject_enabled_config "${build_dir}/.config" "${symbol}"
done

python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--enable-kernel-memory-debug \
	--enable-runtime-qualification \
	--enable-fault-injection \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-combined-debug-update.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
for symbol in \
	DMA_API_DEBUG \
	SLUB_DEBUG \
	PM_DEBUG \
	PM_ADVANCED_DEBUG \
	PM_SLEEP_DEBUG \
	THERMAL_STATISTICS \
	CPU_FREQ_STAT \
	SND_SOC_SOF_DEVELOPER_SUPPORT \
	SND_SOC_SOF_DEBUG \
	SND_SOC_SOF_DEBUG_ENABLE_DEBUGFS_CACHE \
	SND_SOC_SOF_DEBUG_ENABLE_FIRMWARE_TRACE \
	FAULT_INJECTION \
	FAULT_INJECTION_DEBUG_FS \
	FAIL_PAGE_ALLOC \
	FAILSLAB; do
	require_config "${build_dir}/.config" "CONFIG_${symbol}=y"
done
for symbol in \
	SND_SOC_SOF_FORCE_PROBE_WORKQUEUE \
	SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT \
	SND_SOC_SOF_FORCE_NOCODEC_MODE \
	SND_SOC_SOF_DEBUG_XRUN_STOP \
	SND_SOC_SOF_DEBUG_FORCE_IPC_POSITION \
	SND_SOC_SOF_DEBUG_IPC_FLOOD_TEST \
	SND_SOC_SOF_DEBUG_IPC_MSG_INJECTOR \
	SND_SOC_SOF_DEBUG_IPC_KERNEL_INJECTOR \
	SND_SOC_SOF_DEBUG_RETAIN_DSP_CONTEXT \
	SND_SOC_SOF_DEBUG_VERBOSE_IPC; do
	reject_enabled_config "${build_dir}/.config" "${symbol}"
done
python3 "${kconfig_update}" \
	--mode update \
	--kernel-tree "${source_dir}" \
	--board-profile o6-acpi \
	--cix-patches yes \
	--require-npu-abi "${npu_abi}" \
	--apply \
	"${build_dir}/.config" >"${build_dir}/kconfig-production-reset.diff"
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
for symbol in \
	DEBUG_MISC \
	DEBUG_FS \
	KPROBES \
	KPROBE_EVENTS \
	TRACING \
	EVENT_TRACING \
	FTRACE \
	FUNCTION_TRACER \
	DYNAMIC_FTRACE \
	DMA_API_DEBUG \
	DMA_API_DEBUG_SG \
	DEBUG_SG \
	IOMMU_DEBUGFS \
	KFENCE \
	PAGE_OWNER \
	PAGE_POISONING \
	DEBUG_PAGEALLOC \
	SLUB_DEBUG \
	SLUB_DEBUG_ON \
	DEBUG_LIST \
	DEBUG_VM \
	UBSAN \
	UBSAN_BOUNDS \
	UBSAN_LOCAL_BOUNDS \
	REFCOUNT_FULL \
	HARDENED_USERCOPY \
	INIT_ON_ALLOC_DEFAULT_ON \
	INIT_ON_FREE_DEFAULT_ON \
	KASAN \
	KASAN_HW_TAGS \
	KASAN_SW_TAGS \
	KASAN_GENERIC \
	KASAN_EXTRA_INFO \
	KASAN_VMALLOC \
	PM_DEBUG \
	PM_ADVANCED_DEBUG \
	PM_SLEEP_DEBUG \
	THERMAL_STATISTICS \
	CPU_FREQ_STAT \
	SND_SOC_SOF_DEVELOPER_SUPPORT \
	SND_SOC_SOF_DEBUG \
	SND_SOC_SOF_DEBUG_ENABLE_DEBUGFS_CACHE \
	SND_SOC_SOF_DEBUG_ENABLE_FIRMWARE_TRACE \
	SND_SOC_SOF_FORCE_PROBE_WORKQUEUE \
	SND_SOC_SOF_NOCODEC_DEBUG_SUPPORT \
	SND_SOC_SOF_FORCE_NOCODEC_MODE \
	SND_SOC_SOF_DEBUG_XRUN_STOP \
	SND_SOC_SOF_DEBUG_FORCE_IPC_POSITION \
	SND_SOC_SOF_DEBUG_IPC_FLOOD_TEST \
	SND_SOC_SOF_DEBUG_IPC_MSG_INJECTOR \
	SND_SOC_SOF_DEBUG_IPC_KERNEL_INJECTOR \
	SND_SOC_SOF_DEBUG_RETAIN_DSP_CONTEXT \
	SND_SOC_SOF_DEBUG_VERBOSE_IPC \
	FAULT_INJECTION \
	FAULT_INJECTION_DEBUG_FS \
	FAIL_PAGE_ALLOC \
	FAILSLAB; do
	reject_enabled_config "${build_dir}/.config" "${symbol}"
done
# EXPERT and DEBUG_KERNEL are independent end-user choices.  The helper
# preserves both while disabling the production profile's owned
# instrumentation, including SLUB_DEBUG.
require_config "${build_dir}/.config" 'CONFIG_EXPERT=y'
require_config "${build_dir}/.config" 'CONFIG_DEBUG_KERNEL=y'
for symbol in \
	KALLSYMS \
	STACKTRACE; do
	require_config "${build_dir}/.config" "CONFIG_${symbol}=y"
done

# The maintained source surface is deliberately Sky1/Zhouyi V3-only. Check
# source absence separately from configuration absence so a future import
# cannot silently re-expand the audited profile.
for path in \
	drivers/misc/armchina-npu/default/Makefile \
	drivers/misc/armchina-npu/default/default.c \
	drivers/misc/armchina-npu/r329/Makefile \
	drivers/misc/armchina-npu/r329/r329.c \
	drivers/misc/armchina-npu/zhouyi/v1.c \
	drivers/misc/armchina-npu/zhouyi/v1v2_priv.c \
	drivers/misc/armchina-npu/zhouyi/v2.c \
	drivers/misc/armchina-npu/zhouyi/v3_2.c \
	drivers/misc/armchina-npu/zhouyi/v3_2_priv.c; do
	[[ ! -s ${source_dir}/${path} ]] || {
		printf 'error: scoped NPU source unexpectedly retains content in %s\n' \
			"${path}" >&2
		exit 1
	}
done

# Keep the retained common/V3/Sky1 path buildable when optional power
# management or devfreq support is absent. These are enabled NPU cases, not an
# allnoconfig proxy.
for power_case in pm-disabled devfreq-disabled; do
	build_dir=${build_root}/npu-${power_case}
	rm -rf -- "${build_dir}"
	mkdir -p -- "${build_dir}"
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 allnoconfig
	"${source_dir}/scripts/config" --file "${build_dir}/.config" \
		--enable MODULES \
		--enable ARCH_CIX \
		--enable OF \
		--enable DMABUF_HEAPS \
		--module ARMCHINA_NPU \
		--module ARMCHINA_NPU_R2P0
	if [[ ${power_case} == pm-disabled ]]; then
		"${source_dir}/scripts/config" --file "${build_dir}/.config" \
			--disable PM \
			--disable PM_DEVFREQ
	else
		"${source_dir}/scripts/config" --file "${build_dir}/.config" \
			--enable PM \
			--disable PM_DEVFREQ
	fi
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
	require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_COMMON=m'
	require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU=m'
	require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_R2P0=m'
	require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_ARCH_V3=y'
	require_config "${build_dir}/.config" 'CONFIG_ARMCHINA_NPU_SOC_SKY1=y'
	if [[ ${power_case} == pm-disabled ]]; then
		reject_enabled_config "${build_dir}/.config" PM
	else
		require_config "${build_dir}/.config" 'CONFIG_PM=y'
	fi
	reject_enabled_config "${build_dir}/.config" PM_DEVFREQ
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 \
		-j"${jobs}" prepare modules_prepare
	make -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 \
		W=1 -j"${jobs}" \
		drivers/misc/armchina-npu-common/ \
		drivers/misc/armchina-npu/ \
		drivers/misc/armchina-npu-r2p0/
done

# Compile each permitted backend ownership layout with both maintained CI
# Clang and native GCC. This makes the ABI-layout assertions, mutual exclusion,
# and V3-only object composition fatal at the stated acceptance boundary
# without promoting unrelated broad-tree warnings to CIX failures.
for compiler in clang gcc; do
	if [[ ${compiler} == clang ]]; then
		toolchain=(LLVM=1)
	else
		toolchain=()
	fi
	for npu_layout in both-modules current-builtin r2p0-builtin; do
		config_source=${build_root}/npu-layout-${npu_layout}/.config
		build_dir=${build_root}/npu-strict-${compiler}-${npu_layout}
		rm -rf -- "${build_dir}"
		mkdir -p -- "${build_dir}"
		cp -- "${config_source}" "${build_dir}/.config"
		make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 \
			"${toolchain[@]}" olddefconfig
		make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 \
			"${toolchain[@]}" -j"${jobs}" prepare modules_prepare
		case ${npu_layout} in
		both-modules)
			npu_targets=(
				drivers/misc/armchina-npu-common/
				drivers/misc/armchina-npu/
				drivers/misc/armchina-npu-r2p0/
			)
			sky1_objects=(
				drivers/misc/armchina-npu/sky1/sky1.o
				drivers/misc/armchina-npu-r2p0/sky1/sky1.o
			)
			;;
		current-builtin)
			npu_targets=(
				drivers/misc/armchina-npu-common/
				drivers/misc/armchina-npu/
			)
			sky1_objects=(drivers/misc/armchina-npu/sky1/sky1.o)
			;;
		r2p0-builtin)
			npu_targets=(
				drivers/misc/armchina-npu-common/
				drivers/misc/armchina-npu-r2p0/
			)
			sky1_objects=(drivers/misc/armchina-npu-r2p0/sky1/sky1.o)
			;;
		esac
		make -C "${source_dir}" O="${build_dir}" ARCH=arm64 \
			"${toolchain[@]}" W=1 -j"${jobs}" \
			"${npu_targets[@]}"
		for sky1_object in "${sky1_objects[@]}"; do
			sky1_object=${build_dir}/${sky1_object}
			if ! nm -u "${sky1_object}" |
				grep -Eq '(^|[[:space:]])U[[:space:]]+dev_pm_genpd_set_performance_state$'; then
				printf 'error: %s does not use the SCMI generic-power-domain performance-state API\n' \
					"${sky1_object}" >&2
				exit 1
			fi
			if nm -u "${sky1_object}" |
				grep -Eq '(^|[[:space:]])U[[:space:]]+dev_pm_opp_set_rate$'; then
				printf 'error: %s still routes SCMI performance-domain transitions through the clock-oriented OPP rate API\n' \
					"${sky1_object}" >&2
				exit 1
			fi
		done
	done
done

# The Sky1 SOF owner carries generic IPC3 changes as well as its platform
# driver.  Compile the whole sound ownership boundary with both maintained
# toolchains so the normally dormant compressed-offload object is not hidden
# by a successful CIX-only directory build.  Full package builds provide the
# final vmlinux and module-link gates.
if [[ ${kernel_line} == 7.1 || ${kernel_line} == 7.2 ]]; then
	for compiler in clang gcc; do
		if [[ ${compiler} == clang ]]; then
			toolchain=(LLVM=1)
		else
			toolchain=()
		fi
		for preference in module builtin; do
			config_source=${build_root}/hifi5-sof-kconfig-o6-acpi-${preference}/.config
			build_dir=${build_root}/hifi5-sof-strict-${compiler}-${preference}
			rm -rf -- "${build_dir}"
			mkdir -p -- "${build_dir}"
			cp -- "${config_source}" "${build_dir}/.config"
			make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 \
				"${toolchain[@]}" olddefconfig
			make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 \
				"${toolchain[@]}" -j"${jobs}" prepare modules_prepare
			make -C "${source_dir}" O="${build_dir}" ARCH=arm64 \
				"${toolchain[@]}" W=1e -j"${jobs}" \
				drivers/soc/cix/ \
				sound/core/ \
				sound/soc/ \
				sound/soc/sof/ \
				sound/soc/sof/cix/
			for object in \
				sound/core/compress_offload.o \
				sound/soc/soc-compress.o \
				sound/soc/sof/compress.o \
				sound/soc/sof/cix/cix-sky1.o \
				sound/soc/sof/cix/cix-sky1-ipc3.o \
				sound/soc/sof/cix/snd-sof-cix-sky1-nocodec.o; do
				[[ -f ${build_dir}/${object} ]] || {
					printf 'error: SOF %s profile did not compile %s with %s\n' \
						"${preference}" "${object}" "${compiler}" >&2
					exit 1
				}
			done

			if [[ ${preference} == module ]]; then
				make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 \
					"${toolchain[@]}" KBUILD_MODPOST_WARN=1 -j"${jobs}" \
					sound/soc/sof/cix/snd-sof-cix-sky1.ko
				modinfo -F softdep \
					"${build_dir}/sound/soc/sof/cix/snd-sof-cix-sky1.ko" |
					grep -Fx 'pre: cix_mailbox clk_sky1_audss reset_sky1_audss'
				modinfo -F softdep \
					"${build_dir}/sound/soc/sof/cix/snd-sof-cix-sky1.ko" |
					grep -Fx 'pre: snd-sof-cix-sky1-nocodec'
				sof_object=${build_dir}/sound/soc/sof/cix/cix-sky1.o
				common_object=${build_dir}/drivers/soc/cix/cix-hifi5.o
				if nm -u "${sof_object}" |
					grep -Eq '(^|[[:space:]])U[[:space:]]+dma_(declare|release)_coherent_memory$'; then
					printf 'error: modular CIX SOF directly uses unexported coherent-DMA internals\n' >&2
					exit 1
				fi
				if ! nm -u "${sof_object}" |
					grep -Eq '(^|[[:space:]])U[[:space:]]+devm_cix_hifi5_declare_dma_pool$'; then
					printf 'error: modular CIX SOF does not use its built-in DMA-pool broker\n' >&2
					exit 1
				fi
				for symbol in dma_declare_coherent_memory dma_release_coherent_memory; do
					if ! nm -u "${common_object}" |
						grep -Eq "(^|[[:space:]])U[[:space:]]+${symbol}$"; then
						printf 'error: built-in CIX HiFi5 broker does not own %s\n' \
							"${symbol}" >&2
						exit 1
					fi
				done
			fi
		done
	done
fi

# Compile a focused cross-subsystem slice from both modular and built-in board
# profiles. W=1 is intentionally diagnostic rather than KBUILD_WERROR:
# inherited vendor warnings must be reviewed semantically before individual
# classes become fatal. The module profile compiles thermal.o with
# CONFIG_ACPI_THERMAL=m; the full package-build job supplies vmlinux and
# Module.symvers for final .ko/modpost validation.
for preference in module builtin; do
	build_dir=${build_root}/o6-acpi-${preference}
	make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 \
		-j"${jobs}" prepare modules_prepare
	make -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 W=1 \
		-j"${jobs}" \
		drivers/clk/clk-scmi.o \
		drivers/clk/cix/ \
		drivers/mailbox/cix-mailbox.o \
		drivers/dma/arm-dma350.o \
		drivers/gpio/gpio-cadence.o \
		drivers/i2c/busses/i2c-cadence.o \
		drivers/irqchip/irq-sky1-pdc.o \
		drivers/mfd/syscon.o \
		drivers/reset/reset-sky1.o \
		drivers/reset/reset-sky1-audss.o \
		drivers/soc/cix/ \
		drivers/acpi/property.o \
		drivers/acpi/processor_thermal.o \
		drivers/acpi/thermal.o \
		drivers/opp/core.o \
		drivers/cpufreq/cppc_cpufreq.o \
		drivers/thermal/gov_power_allocator.o \
		kernel/bpf/bpf_struct_ops.o \
		drivers/gpu/drm/cix/dptx/ \
		drivers/gpu/drm/cix/linlon-dp/ \
		drivers/misc/armchina-npu-common/ \
		drivers/misc/armchina-npu/ \
		drivers/misc/armchina-npu-r2p0/ \
		drivers/net/ethernet/realtek/r8126/ \
		drivers/media/platform/cix/ \
		drivers/pwm/pwm-sky1.o \
		drivers/hwmon/cix-fan.o
	if [[ ${preference} == module ]]; then
		dptx_object=${build_dir}/drivers/gpu/drm/cix/dptx/trilin-dpsub.o
	else
		dptx_object=${build_dir}/drivers/gpu/drm/cix/dptx/trilin_drm.o
	fi
	[[ -f ${dptx_object} ]] || {
		printf 'error: profile did not compile %s\n' "${dptx_object}" >&2
		exit 1
	}
	if ! grep -Fqx 'CONFIG_DEBUG_FS=y' "${build_dir}/.config" &&
		nm -u "${dptx_object}" |
		grep -Eq '(^|[[:space:]])U[[:space:]]+trilin_dp_connector_debugfs_init$'; then
		printf 'error: DPTX retains a debugfs callback reference with CONFIG_DEBUG_FS disabled\n' >&2
		exit 1
	fi
	if ! grep -Fqx 'CONFIG_BPF_STRUCT_OPS=y' "${build_dir}/.config" &&
		nm -u "${build_dir}/kernel/bpf/bpf_struct_ops.o" |
		grep -Eq '(^|[[:space:]])U[[:space:]]+bpf_struct_ops_test_run$'; then
		printf 'error: BPF core retains its disabled struct-ops test-provider callback\n' >&2
		exit 1
	fi
	for object in \
		drivers/misc/armchina-npu/zhouyi/v3.o \
		drivers/misc/armchina-npu/zhouyi/v3_priv.o; do
		[[ -f ${build_dir}/${object} ]] || {
			printf 'error: profile did not compile %s\n' "${object}" >&2
			exit 1
		}
	done
	if [[ ${preference} == module ]]; then
		# A directory target stops after the composite module object.  Link the
		# two focused modules as explicit top-level targets so their generated
		# .modinfo can be inspected without doing an otherwise redundant full
		# vmlinux build.  Missing generic-kernel symbols are expected at this
		# focused boundary and are covered by the full package build.
		make -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 \
			KBUILD_MODPOST_WARN=1 -j"${jobs}" \
			drivers/usb/cdns3/cdns3-sky1.ko \
			drivers/misc/armchina-npu-common/armchina_npu_common.ko \
			drivers/misc/armchina-npu/armchina_npu.ko \
			drivers/misc/armchina-npu-r2p0/armchina_npu_r2p0.ko \
			drivers/net/ethernet/realtek/r8126/r8126.ko \
			sound/hda/controllers/snd-hda-cix-ipbloq.ko \
			sound/soc/cix/snd-soc-cdns-i2s-mc.ko \
			sound/soc/cix/snd-soc-sky1-card.ko
		for module in \
			drivers/usb/cdns3/cdns3-sky1.ko \
			drivers/misc/armchina-npu-common/armchina_npu_common.ko \
			drivers/misc/armchina-npu/armchina_npu.ko \
			drivers/misc/armchina-npu-r2p0/armchina_npu_r2p0.ko \
			drivers/net/ethernet/realtek/r8126/r8126.ko \
			sound/hda/controllers/snd-hda-cix-ipbloq.ko \
			sound/soc/cix/snd-soc-cdns-i2s-mc.ko \
			sound/soc/cix/snd-soc-sky1-card.ko; do
			[[ -f ${build_dir}/${module} ]] || {
				printf 'error: module profile did not build %s\n' "${module}" >&2
				exit 1
			}
		done
		modinfo -F softdep \
			"${build_dir}/drivers/misc/armchina-npu/armchina_npu.ko" |
			grep -Fx 'pre: governor_userspace scmi_perf_domain'
		modinfo -F softdep \
			"${build_dir}/drivers/misc/armchina-npu-r2p0/armchina_npu_r2p0.ko" |
			grep -Fx 'pre: governor_userspace scmi_perf_domain'
		modinfo -F softdep \
			"${build_dir}/drivers/usb/cdns3/cdns3-sky1.ko" |
			grep -Fx 'pre: phy-cix-usbdp'
		modinfo -F softdep \
			"${build_dir}/sound/hda/controllers/snd-hda-cix-ipbloq.ko" |
			grep -Fx 'pre: clk_sky1_audss reset_sky1_audss'
		modinfo -F softdep \
			"${build_dir}/sound/soc/cix/snd-soc-cdns-i2s-mc.ko" |
			grep -Fx 'pre: arm_dma350 clk_sky1_audss reset_sky1_audss'
		modinfo -F softdep \
			"${build_dir}/sound/soc/cix/snd-soc-sky1-card.ko" |
			grep -Fx 'pre: snd_soc_cdns_i2s_mc'
		for module in \
			"${build_dir}/drivers/misc/armchina-npu/armchina_npu.ko" \
			"${build_dir}/drivers/misc/armchina-npu-r2p0/armchina_npu_r2p0.ko"; do
			modinfo -F depends "${module}" |
				tr ',' '\n' |
				grep -Fx 'armchina_npu_common'
		done
		common_aliases=$(modinfo -F alias \
			"${build_dir}/drivers/misc/armchina-npu-common/armchina_npu_common.ko")
		[[ -z ${common_aliases} ]] || {
			printf 'error: internal NPU common module exposes aliases: %s\n' \
				"${common_aliases}" >&2
			exit 1
		}
		if ! modinfo -F alias \
			"${build_dir}/drivers/misc/armchina-npu/armchina_npu.ko" |
			grep -Fq 'CIXH4000'; then
			printf 'error: default R2P1 NPU module has no CIXH4000 modalias\n' >&2
			exit 1
		fi
		r2p0_aliases=$(modinfo -F alias \
			"${build_dir}/drivers/misc/armchina-npu-r2p0/armchina_npu_r2p0.ko")
		[[ -z ${r2p0_aliases} ]] || {
			printf 'error: explicit-load R2P0 NPU module exposes aliases: %s\n' \
				"${r2p0_aliases}" >&2
			exit 1
		}
	fi
done

# Keep the DPTX module independent of the generic kernel-debugging menu and
# exercise both newly independent Kconfig choices in one build.
build_dir=${build_root}/dptx-no-debug-kernel
rm -rf -- "${build_dir}"
mkdir -p -- "${build_dir}"
cp -- "${build_root}/o6-acpi-module/.config" "${build_dir}/.config"
"${source_dir}/scripts/config" --file "${build_dir}/.config" \
	--enable EXPERT \
	--disable DEBUG_KERNEL \
	--disable DEBUG_FS \
	--disable SLUB_DEBUG
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 olddefconfig
require_config "${build_dir}/.config" 'CONFIG_EXPERT=y'
for symbol in DEBUG_KERNEL DEBUG_FS SLUB_DEBUG; do
	reject_enabled_config "${build_dir}/.config" "${symbol}"
done
require_config "${build_dir}/.config" 'CONFIG_DRM_TRILIN_DPSUB=m'
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 \
	-j"${jobs}" prepare modules_prepare
make -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 W=1 \
	-j"${jobs}" mm/slub.o mm/slab_common.o drivers/gpu/drm/cix/dptx/
dptx_object=${build_dir}/drivers/gpu/drm/cix/dptx/trilin-dpsub.o
[[ -f ${dptx_object} ]] || {
	printf 'error: DEBUG_KERNEL-disabled profile did not compile %s\n' \
		"${dptx_object}" >&2
	exit 1
}
if nm -u "${dptx_object}" |
	grep -Eq '(^|[[:space:]])U[[:space:]]+trilin_dp_connector_debugfs_init$'; then
	printf 'error: DEBUG_KERNEL-disabled DPTX retains its debugfs callback\n' >&2
	exit 1
fi

# Compile the accelerator paths once through their DT-facing profile as well;
# the full ACPI slice above remains the broader subsystem integration build.
build_dir=${build_root}/o6-dt-module
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 \
	-j"${jobs}" prepare modules_prepare
make -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 W=1 \
	-j"${jobs}" \
	drivers/misc/armchina-npu-common/ \
	drivers/misc/armchina-npu/ \
	drivers/misc/armchina-npu-r2p0/ \
	drivers/media/platform/cix/

# Broad configurations also keep quarantined and explicitly opt-in vendor code
# buildable beyond the drivers selected by maintained board profiles.
build_dir=${build_root}/allmod
usb_sky1_object=drivers/usb/cdns3/cdnsp-sky1.o
[[ ${kernel_line} != 7.2 ]] || \
	usb_sky1_object=drivers/usb/cdns3/cdns3-sky1.o
make -s -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 \
	-j"${jobs}" prepare modules_prepare
make -C "${source_dir}" O="${build_dir}" ARCH=arm64 LLVM=1 W=1 \
	-j"${jobs}" \
	drivers/media/platform/cix/ \
	drivers/misc/armchina-npu-common/ \
	drivers/misc/armchina-npu/ \
	drivers/misc/armchina-npu-r2p0/ \
	drivers/gpu/drm/panthor/ \
	drivers/net/ethernet/cadence/ \
	drivers/net/ethernet/realtek/r8126/ \
	drivers/pinctrl/cix/ \
	drivers/spi/spi-cadence.o \
	"${usb_sky1_object}" \
	drivers/usb/typec/rts5453.o \
	sound/hda/controllers/snd-hda-cix-ipbloq.o \
	sound/soc/cix/

printf 'CIX config and focused compile validation passed for Linux %s (%s)\n' \
	"${kernel_line}" "${npu_abi}"
