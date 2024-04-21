# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit mount-boot

DESCRIPTION="Raspberry Pi kernel, devicetree and modules"
HOMEPAGE="https://github.com/raspberrypi/firmware"
LICENSE="GPL-2 raspberrypi-videocore-bin"
SLOT="${PV#*"_p"}"
IUSE="+64bit +devicetree extras +os-prefix +rpi-all rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi-cm4-io rpi5 rpi-cm5 rpi-cm5-io"
REQUIRED_USE="
	|| ( rpi-all rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi-cm5 )
	64bit? ( || ( rpi-all rpi02 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi-cm5 ) )
	os-prefix? ( devicetree )
	rpi-all? ( !rpi0 !rpi02 !rpi1 !rpi-cm !rpi2 !rpi-cm2 !rpi3 !rpi-cm3 !rpi4 !rpi400 !rpi-cm4 !rpi-cm4s !rpi5 !rpi-cm5 )
	rpi-cm4-io? ( || ( rpi-cm4 rpi-cm5 ) )
	rpi-cm5-io? ( rpi-cm5 )
	rpi-cm5? ( || ( rpi-cm4-io rpi-cm5-io ) )
"

RESTRICT="binchecks mirror strip"

# Temporary safety measure to prevent ending up with a pair of
# sys-kernel/raspberrypi-image and sys-boot/raspberrypi-firmware
# both of which installed device tree files.
# Restore to simply "sys-boot/raspberrypi-firmware" when the mentioned version
# and all older ones are deleted.
RDEPEND="
	>sys-boot/raspberrypi-firmware-1.20190709
	devicetree? ( !sys-boot/raspberrypi-firmware[devicetree] )
	!devicetree? ( sys-boot/raspberrypi-firmware[devicetree] )
	!sys-boot/raspberrypi-firmware[kernel]
"

if [[ "${PV}" == '9999' ]]; then
	EGIT_REPO_URI="https://github.com/raspberrypi/firmware"
	EGIT_CLONE_TYPE="shallow"
	inherit git-r3
else
	[[ "$(ver_cut 4)" == 'p' ]] || die "Unsupported version format, tweak the ebuild."
	MY_PV="1.$(ver_cut 5)"
	# Share with sys-boot/raspberrypi-firmware
	SRC_URI="https://github.com/raspberrypi/firmware/archive/${MY_PV}.tar.gz -> raspberrypi-firmware-${MY_PV}.tar.gz"
	S="${WORKDIR}/firmware-${MY_PV}"
	KEYWORDS="-* arm arm64"
fi

FIRMWARE_DIR="/usr/share/raspberrypi/kernel/${PV}"

pkg_setup() {
	local state boot="${RASPBERRYPI_BOOT:-/boot}"

	einfo "Checking mount-points ..."

	[[ "${boot}" == "${boot// }" ]] || die "Invalid value '${boot}' for control variable 'RASPBERRYPI_BOOT'"
	[[ "${boot:0:1}" == "/" ]] || die "Invalid value '${boot}' for control variable 'RASPBERRYPI_BOOT': Value must be absolute path"
	boot="$( readlink -e "${boot}" )" || die "readlink failed: ${?}"

	if [[ -z "${RASPBERRYPI_BOOT:-}" ]]; then
		ewarn "This ebuild assumes that your FAT32 firmware/boot partition is"
		ewarn "mounted on '${boot}'."
		ewarn
		ewarn "If this is not the case, please cancel this install *NOW* and"
		ewarn "re-install having set the RASPBERRYPI_BOOT environment variable"
		ewarn "in /etc/portage/make.conf"
		sleep 5
	else
		einfo "Using '${boot}' as boot-partition mount-point"
	fi

	if [[ "${MERGE_TYPE}" != "buildonly" ]]; then
		if ! [[ -d "${boot}" ]]; then
			eerror "Directory '${boot}' does not exist"
			eerror
			die "Please set the RASPBERRYPI_BOOT environment variable in /etc/portage/make.conf"
		fi

		state="$( cut -d' ' -f 2-4 /proc/mounts 2>/dev/null | grep -E "^${boot} (u?msdos|v?fat) " | grep -Eo '[ ,]r[ow](,|$)' | sed 's/[ ,]//g' )"
		case "${state}" in
			rw)
				:
				;;
			ro)
				die "Filesystem '${boot}' is currently mounted read-only - installation cannot proceed"
				;;
			*)
				ewarn "Cannot determine mount-state of boot filesystem '${boot}' - is this partition mounted?"
				;;
		esac
	fi
}

src_prepare() {
	default

	local expected_kernel_version="$(ver_cut 1-3)+"
	local found_kernel_version=( "${S}"/modules/$(ver_cut 1).*.*+ )

	found_kernel_version=${found_kernel_version[0]}
	found_kernel_version=${found_kernel_version##*/}

	if [[ ${expected_kernel_version} != ${found_kernel_version} ]] ; then
		eerror "Expected kernel version: ${expected_kernel_version}"
		eerror "Found kernel version: ${found_kernel_version}"
		die "Please fix ebuild version to contain ${found_kernel_version}!"
	fi

	if [[ ! -d "${S}"/modules/${expected_kernel_version} ]] ; then
		eerror "Kernel module directory is missing!"
		die "${S}/modules/${expected_kernel_version} not found!"
	fi
}

src_install() {
	local f='' boot="${RASPBERRYPI_BOOT:-/boot}" ver=''
	local -a files=()

	# 'keepdir' will fail on FAT32 filesystems = moved to pkg_preinst
	#keepdir "${boot}"
	#use devicetree && keepdir "${boot}"/overlays
	#keepdir /lib/modules

	# Firmware blobs are now installed by sys-boot/raspberrypi-firmware
	#insinto "${boot}"
	#for f in boot/*.bin boot/*.dat boot/*.elf; do
	#	if [[ -e "${f}" ]]; then
	#		if use rpi4 || [[ "${f}" != *4* ]]; then
	#			doins "${f}"
	#		fi
	#	fi
	#done

	#Filename         Processor                           Raspberry Model
	#kernel.img       BCM2835                             pi0, pi1
	#kernel7.img      BCM2836, BCM2837                    pi2, pi3
	#kernel7l.img     BCM2711, BCM2712                    pi4, pi5
	#kernel8.img      BCM2836, BCM2837, BCM2711, BCM2712  pi2/3/4/5 64-bit kernel
	#kernel_2712.img  BCM2712                             pi5 64-bit kernel, 16k pages

	# Install kernel(s) ...
	insinto "${FIRMWARE_DIR}"

	for f in boot/*.img; do
		case "${f}" in
			boot/kernel.img)
				if use rpi-all || use rpi1 || use rpi-cm || use rpi0; then
					einfo "Installing 'kernel.img' for BCM2835 (Raspberry Pi Zero, Raspberry Pi) ..."
					doins "${f}"
				fi
				;;
			boot/kernel7.img)
				if use rpi-all || use rpi2 || use rpi-cm2 || use rpi3 || use rpi-cm3 || use rpi02; then
					einfo "Installing 'kernel7.img' for BCM2836 & BCM2837 (Raspberry Pi 2, Raspberry Pi 3, Raspberry Pi Zero 2 32bit) ..."
					doins "${f}"
				fi
				;;
			boot/kernel7l.img)
				if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
					if use rpi-all || ! use 64bit; then
						einfo "Installing 'kernel7l.img' for BCM2711 (Raspberry Pi 4/5 LPAE 32bit) ..."
						doins "${f}"
					fi
				fi
				;;
			boot/kernel8.img)
				if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
					if use rpi-all || ! use 64bit; then
						einfo "Installing 'kernel8.img' for BCM2836, BCM2837, BCM2711 (Raspberry Pi 2+ 64bit) ..."
						doins "${f}"
					fi
				fi
				;;
			boot/kernel_2712.img)
				if use rpi-all || use rpi5 || use rpi-cm5; then
					einfo "Installing 'kernel_2712.img' for BCM2712 (Raspberry Pi 5 64bit, 16k pages) ..."
					doins "${f}"
				fi
				;;
			*)
				if [[ -e "${f}" ]]; then
					ewarn "Installing unknown boot file '${f}' ..."
					doins "${f}"
				fi
				;;
		esac
	done

	# Install kernel modules
	#
	# N.B. ${ver} only needs to be set once, and should be identical for all
	#      possible values of '${f}'...
	#
	insinto /lib/modules
	for f in modules/*; do
		case "${f}" in
			*-v7+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v7+$//' )"
				if use rpi-all || use rpi2 || use rpi-cm2 || use rpi3 || use rpi-cm3 || use rpi02; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2836 & BCM2837 (Raspberry Pi 2, Raspberry Pi 3, Raspberry Pi Zero 2 32bit) ..."
					doins -r "${f}"
					dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
				fi
				;;
			*-v7l+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v7l+$//' )"
				if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
					if use rpi-all || ! use 64bit; then
						einfo "Installing kernel modules '${f#modules/}' for BCM2711 (Raspberry Pi 4 LPAE 32bit) ..."
						doins -r "${f}"
						dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
					fi
				fi
				;;
			*-v8+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v8+$//' )"
				if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
					if use rpi-all || use 64bit; then
						einfo "Installing kernel modules '${f#modules/}' for BCM2836+ (Raspberry Pi 2+ 64bit) ..."
						doins -r "${f}"
						dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
					fi
				fi
				;;
			*-v8-16k+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v8-16k+$//' )"
				if use rpi-all || use rpi5 || use rpi-cm5; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2712 (Raspberry Pi 5 64bit, 16k pages) ..."
					doins -r "${f}"
					dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
				fi
				;;
			*+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/+$//' )"
				if use rpi-all || use rpi1 || use rpi-cm || use rpi0; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2835 (Raspberry Pi Zero, Raspberry Pi) ..."
					doins -r "${f}"
					dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
				fi
				;;
			*)
				if [[ -e "${f}" ]]; then
					[[ -z "${ver}" ]] && ver="$( basename "${f}" )"

					ewarn "Installing unknown kernel modules '${f#modules/}' ..."
					doins -r "${f}"
					dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
				fi
				;;
		esac
	done

	# There's little or no standardisation in regards to where System.map
	# should live, and the only two common locations seem to be /boot and /
	if [[ -n "${ver}" ]]; then
		f=""
		insinto "${FIRMWARE_DIR}"
		if use rpi-all || use rpi5 || use rpi-cm5; then
			if [[ -e extra/System_2712.map ]]; then
				newins extra/System_2712.map "System.map-${ver}-v8-16k+"
				f="${f:+${f}, }System.map-${ver}-v8-16k+"
			fi
			if use extras; then
				newins extra/Module_2712.symvers "Module.symvers-${ver}-v8-16k+"
				newins extra/uname_string_2712 "uname-${ver}-v8-16k+"
			fi
		fi
		if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
			if use rpi-all || use 64bit; then
				if [[ -e extra/System8.map ]]; then
					newins extra/System8.map "System.map-${ver}-v8+"
					f="${f:+${f}, }System.map-${ver}-v8+"
				fi
				if use extras; then
					newins extra/Module8.symvers "Module.symvers-${ver}-v8+"
					newins extra/uname_string8 "uname-${ver}-v8+"
				fi
			fi
		fi
		if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
			if use rpi-all || ! use 64bit; then
				if [[ -e extra/System7l.map ]]; then
					newins extra/System7l.map "System.map-${ver}-v7l+"
					f="${f:+${f}, }System.map-${ver}-v7l+"
				fi
				if use extras; then
					newins extra/Module7l.symvers "Module.symvers-${ver}-v7l+"
					newins extra/uname_string7l "uname-${ver}-v7l+"
				fi
			fi
		fi
		if use rpi-all || use rpi2 || use rpi-cm2 || use rpi3 || use rpi-cm3 || use rpi02; then
			if use rpi-all || ! use 64bit; then
				if [[ -e extra/System7.map ]]; then
					newins extra/System7.map "System.map-${ver}-v7+"
					f="${f:+${f}, }System.map-${ver}-v7+"
				fi
				if use extras; then
					newins extra/Module7.symvers "Module.symvers-${ver}-v7+"
					newins extra/uname_string7 "uname-${ver}-v7+"
				fi
			fi
		fi
		if use rpi-all || use rpi1 || use rpi-cm || use rpi0; then
			if [[ -e extra/System.map ]]; then
				newins extra/System.map "System.map-${ver}+"
				f="${f:+${f}, }System.map-${ver}+"
			fi
			if use extras; then
				newins extra/Module8.symvers "Module.symvers-${ver}+"
				newins extra/uname_string7 "uname-${ver}-v7+"
			fi
		fi
		if use extras; then
			doins extra/dt-blob.dts extra/git_hash
		fi

		einfo "You should create a symlink from /System.map to ${boot}/System.map"
		einfo "and from ${boot}/System.map to one of:"
		xargs -r -n 1 einfo '   ' <<<"${f}"
		einfo "... as appropriate."
	fi

	# Install Device Tree overlays ...
	if use devicetree; then
		if use rpi-all || use rpi1; then
			files+=( # <- Syntax
				bcm2708-rpi-b.dtb
				bcm2708-rpi-b-plus.dtb
				bcm2708-rpi-b-rev1.dtb
			)
		fi
		if use rpi-all || use rpi-cm; then
			files+=( # <- Syntax
				bcm2708-rpi-cm.dtb
			)
		fi
		if use rpi-all || use rpi0; then
			files+=( # <- Syntax
				bcm2708-rpi-zero.dtb
				bcm2708-rpi-zero-w.dtb
			)
		fi
		if use rpi-all || use rpi2; then
			files+=( # <- Syntax
				bcm2709-rpi-2-b.dtb
				bcm2710-rpi-2-b.dtb
			)
		fi
		if use rpi-all || use rpi-cm2; then
			files+=( # <- Syntax
				bcm2709-rpi-cm2.dtb
			)
		fi
		if use rpi-all || use rpi3; then
			files+=( # <- Syntax
				bcm2710-rpi-3-b.dtb
				bcm2710-rpi-3-b-plus.dtb
			)
		fi
		if use rpi-all || use rpi-cm3; then
			files+=( # <- Syntax
				bcm2710-rpi-cm3.dtb
			)
		fi
		if use rpi-all || use rpi02; then
			files+=( # <- Syntax
				bcm2710-rpi-zero-2.dtb
				bcm2710-rpi-zero-2-w.dtb
			)
		fi
		if use rpi-all || use rpi4; then
			files+=( # <- Syntax
				bcm2711-rpi-4-b.dtb
			)
		fi
		if use rpi-all || use rpi-cm4 || use rpi-cm4s; then
			if use rpi-all || use rpi-cm4-io; then
				files+=( # <- Syntax
					bcm2711-rpi-cm4-io.dtb
				)
			fi
			if use rpi-all || use rpi-cm4; then
				files+=( # <- Syntax
					bcm2711-rpi-cm4.dtb
				)
			fi
			if use rpi-all || use rpi-cm4s; then
				files+=( # <- Syntax
					bcm2711-rpi-cm4s.dtb
				)
			fi
		fi
		if use rpi-all || use rpi400; then
			files+=( # <- Syntax
				bcm2711-rpi-400.dtb
			)
		fi
		if use rpi-all || use rpi5; then
			files+=( # <- Syntax
				bcm2712-rpi-5-b.dtb
				bcm2712d0-rpi-5-b.dtb
			)
		fi
		if use rpi-all || use rpi-cm5; then
			if use rpi-all || use rpi-cm4-io; then
				files+=( # <- Syntax
					bcm2712-rpi-cm5-cm4io.dtb
				)
			fi
			if use rpi-all || use rpi-cm5-io; then
				files+=( # <- Syntax
					bcm2712-rpi-cm5-cm5io.dtb
				)
			fi
		fi
		insinto "${FIRMWARE_DIR}"
		pushd boot >/dev/null || die
		doins -r "${files[@]}" overlays
		popd >/dev/null
	fi
}

pkg_preinst() {
	local boot="${RASPBERRYPI_BOOT:-/boot}"

	if use os-prefix; then
		boot="${boot}/${PV}"
	fi

	mkdir -p "${boot}"
	#touch "${boot}/.keep_${CATEGORY}_${PN}-${SLOT:-0}"
	if use devicetree; then
		mkdir -p "${boot}"/overlays
	#	touch "${boot}/overlays/.keep_${CATEGORY}_${PN}-${SLOT:-0}"
	fi

	mount-boot_pkg_preinst
}

pkg_postinst() {
	if [[ "${MERGE_TYPE}" != "buildonly" ]]; then
		pkg_config
	fi

	mount-boot_pkg_postinst
}

pkg_postrm() {
	local boot="${RASPBERRYPI_BOOT:-/boot}" file=''
	local -a files=()

	if use os-prefix; then
		boot="${boot}/${PV}"
	fi

	#files=( "${boot}/.keep_${CATEGORY}_${PN}-${SLOT:-0}" )
	#if use devicetree; then
	#	files+=( "${boot}/overlays/.keep_${CATEGORY}_${PN}-${SLOT:-0}" )
	#fi

	for file in "${files[@]}"; do
		if [[ -e "${file}" && -f "${file}" && ! -s "${file}" ]]; then
			rm "${file}"
			rmdir --ignore-fail-on-non-empty -p "${boot}" || :
		fi
	done

	mount-boot_pkg_postrm
}

pkg_config() {
	local boot="${RASPBERRYPI_BOOT:-/boot}"

	if use os-prefix; then
		boot="${boot}/${PV}"
	fi

	ebegin "Deploying Raspberry Pi kernel ${PV} from" \
		"${FIRMWARE_DIR} to ${boot}"

	set -o pipefail >/dev/null 2>&1
	if use devicetree; then
		if [[ -d "${boot}"/overlays ]]; then
			if ! mv "${boot}"/overlays "${boot}"/overlays.old; then
				eend ${?} "Failed to backup current 'overlays' directory"
				return ${?}
			fi
		fi
		if ! cp -r "${FIRMWARE_DIR}/overlays" "${boot}/"; then
			eend ${?} "Failed to copy 'overlays' directory: ${?}"
			return ${?}
		fi
		if ! [[ -e "${boot}/overlays/README" ]]; then
			eend "Marker file '${boot}/overlays/README' is missing"
			return 1
		fi
	fi
	if ! find "${FIRMWARE_DIR}" \
				-mindepth 1 \
				-maxdepth 1 \
				-type f \
				-not -name config.txt \
				-not -name cmdline.txt \
				-print0 |
		xargs -0 -r -I'{}' cp --no-dereference '{}' "${boot}/"
	then
		eend ${?} "kernel file copy failed: ${?}"
		return ${?}
	fi

	if use devicetree && [[ -d "${boot}"/overlays.old ]]; then
		if ! diff -qr "${boot}"/overlays{.old,}; then
			ewarn "Overlay differences:"
			diff -r "${boot}"/overlays{.old,}
			elog "Please remove '${boot}/overlays.old' once" \
				"reconciled"
		else
			rm -r "${boot}"/overlays.old
		fi
	fi

	eend 0
}

# vi: set diffopt=filler,iwhite:
