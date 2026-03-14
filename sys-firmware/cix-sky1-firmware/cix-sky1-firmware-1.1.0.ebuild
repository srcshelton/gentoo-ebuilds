# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info

DESCRIPTION="Firmware files for CIX Sky1 SoC (GPU, DSP, VPU)"
HOMEPAGE="https://github.com/Sky1-Linux/sky1-firmware"
SRC_URI="https://github.com/Sky1-Linux/${PN#"cix-"}/archive/refs/tags/v${PV}.tar.gz"
S="${WORKDIR}/${P#"cix-"}/firmware"

# Parent repo states ARM and CIX licences, but doesn't link to these :(
LICENSE="Arm-Mali"
SLOT="0"
KEYWORDS="arm arm64"
IUSE="compress-xz compress-zstd rtw89"
REQUIRED_USE="?? ( compress-xz compress-zstd )"

BDEPEND="
	compress-xz? ( app-arch/xz-utils )
	compress-zstd? ( app-arch/zstd )
"
RDEPEND="
	rtw89? ( !sys-kernel/linux-firmware[-savedconfig] )
"

QA_PREBUILT="*"

pkg_setup() {
	if use compress-xz || use compress-zstd ; then
		local CONFIG_CHECK

		if kernel_is -ge 5 19; then
			use compress-xz && CONFIG_CHECK="~FW_LOADER_COMPRESS_XZ"
			use compress-zstd && CONFIG_CHECK="~FW_LOADER_COMPRESS_ZSTD"
		else
			use compress-xz && CONFIG_CHECK="~FW_LOADER_COMPRESS"
			if use compress-zstd; then
				eerror "Kernels <5.19 do not support ZSTD-compressed firmware files"
			fi
		fi
		linux-info_pkg_setup
	fi
}

pkg_pretend() {
	local -a BADFILES=()
	local bin file

	if ! use rtw89; then
		return 0
	fi

	for bin in "${EPREFIX}"/lib/firmware/rtw89/rtw8852*_fw*.bin; do
		[[ -e "${bin}" ]] && BADFILES+=( "${bin}" )
	done

	if [[ "${#BADFILES[@]}" -gt 0 ]]; then
		eerror "The following files should be excluded from the savedconfig of"
		eerror "linux-firmware and linux-firmware should be re-emerged."
		eerror
		eerror "List of files:"
		for file in "${BADFILES[@]}"; do
			eerror "  ${file}"
		done
	fi
}

src_install() {
	insinto /lib/firmware/arm/mali
	doins arm/mali/mali_csffw.bin

	dosym -r /lib/firmware/arm/mali/mali_csffw.bin /lib/firmware/mali_csffw.bin

	if use rtw89; then
		insinto /lib/firmware/rtw89
		doins rtw89/*.bin
	fi

	insinto /lib/firmware
	doins dsp_fw.bin *.fwb

	if use compress-xz; then
		find "${ED}"/lib/firmware -type f -exec xz {} +
	elif use compress-zstd; then
		find "${ED}"/lib/firmware -type f -exec zstd {} +
	fi
}
