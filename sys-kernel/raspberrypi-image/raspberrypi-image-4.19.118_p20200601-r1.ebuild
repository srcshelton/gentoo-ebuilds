# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit mount-boot

DESCRIPTION="Raspberry Pi (all versions) kernel and modules"
HOMEPAGE="https://github.com/raspberrypi/firmware"
LICENSE="GPL-2 raspberrypi-videocore-bin"
SLOT="0"
IUSE="+rpi0 +rpi1 +rpi2 +rpi3 +rpi4 64bit"

RESTRICT="binchecks mirror strip"

# Temporary safety measure to prevent ending up with a pair of
# sys-kernel/raspberrypi-image and sys-boot/raspberrypi-firmware
# both of which installed device tree files.
# Restore to simply "sys-boot/raspberrypi-firmware" when the mentioned version
# and all older ones are deleted.
RDEPEND=">sys-boot/raspberrypi-firmware-1.20190709"

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/raspberrypi/firmware"
	EGIT_CLONE_TYPE="shallow"
else
	[[ "$(ver_cut 4)" == 'p' ]] || die "Unsupported version format, tweak the ebuild."
	MY_PV="1.$(ver_cut 5)"
	SRC_URI="https://github.com/raspberrypi/firmware/archive/${MY_PV}.tar.gz -> raspberrypi-firmware-${MY_PV}.tar.gz"
	S="${WORKDIR}/firmware-${MY_PV}"
	KEYWORDS="-* ~arm"
fi

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

src_install() {
	local f boot="${RASPBERRYPI_BOOT:-/boot}" ver

	keepdir "${boot}"
	#keepdir "${boot}"/kernel
	keepdir "${boot}"/overlays
	keepdir /lib/modules

	# Firmware blobs are now installed by sys-boot/raspberrypi-firmware
	#insinto "${boot}"
	#for f in boot/*.bin boot/*.dat boot/*.elf; do
	#	if [[ -e "${f}" ]]; then
	#		if use rpi4 || [[ "${f}" != *4* ]]; then
	#			doins "${f}"
	#		fi
	#	fi
	#done

	#Filename       Processor                       Raspberry Model
	#kernel.img     BCM2835                         pi0, pi1
	#kernel7.img    BCM2836, BCM2837                pi2, pi3
	#kernel7l.img   BCM2711                         pi4
	#kernel8.img    BCM2836, BCM2837, BCM2711       pi2/3/4 Beta 64 bit kernel

	# Install kernel(s) ...
	#insinto "${boot}"/kernel
	insinto "${boot}"
	for f in boot/*.img; do
		case "${f}" in
			boot/kernel.img)
				if use rpi0 || use rpi1; then
					einfo "Installing 'kernel.img' for BCM2835 (Raspberry Pi Zero, Raspberry Pi) ..."
					doins "${f}"
				fi
				;;
			boot/kernel7.img)
				if use rpi2 || use rpi3; then
					einfo "Installing 'kernel7.img' for BCM2836 & BCM2837 (Raspberry Pi 2, Raspberry Pi 3) ..."
					doins "${f}"
				fi
				;;
			boot/kernel7l.img)
				if use rpi4; then
					einfo "Installing 'kernel7l.img' for BCM2711 (Raspberry Pi 4 LPAE) ..."
					doins "${f}"
				fi
				;;
			boot/kernel8.img)
				if use 64bit; then
					einfo "Installing 'kernel8.img' for BCM2836, BCM2837 & BCM2711  (Raspberry Pi 2+ 64bit) ..."
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

	# Install kernel modules ...
	insinto /lib/modules
	for f in modules/*; do
		case "${f}" in
			*-v7+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v7+$//' )"
				if use rpi2 || use rpi3; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2836 & BCM2837 (Raspberry Pi 2, Raspberry Pi 3) ..."
					doins -r "${f}"
				fi
				;;
			*-v7l+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v7l+$//' )"
				if use rpi4; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2711 (Raspberry Pi 4 LPAE) ..."
					doins -r "${f}"
				fi
				;;
			*-v8+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/-v87+$//' )"
				if use 64bit; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2711 (Raspberry Pi 4 LPAE) ..."
					doins -r "${f}"
				fi
				;;
			*+)
				[[ -z "${ver}" ]] && ver="$( basename "${f}" | sed 's/+$//' )"
				if use rpi0 || use rpi1; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2835 (Raspberry Pi Zero, Raspberry Pi) ..."
					doins -r "${f}"
				fi
				;;
			*)
				if [[ -e "${f}" ]]; then
					[[ -z "${ver}" ]] && ver="$( basename "${f}" )"

					ewarn "Installing unknown kernel modules '${f#modules/}' ..."
					doins -r "${f}"
				fi
				;;
		esac
	done

	# There's little or no standardisation in regards to where System.map
	# should live, and the only two common locations seem to be /boot and /
	if [[ -n "${ver}" ]]; then
		f=""
		insinto "${boot}"
		if use 64bit; then
			[[ -e extra/System8.map ]] && newins extra/System8.map "System.map-${ver}-v8+"
			f="${f:+${f}, }System.map-${ver}-v8+"
		fi
		if use rpi4; then
			[[ -e extra/System7l.map ]] && newins extra/System7l.map "System.map-${ver}-v7l+"
			f="${f:+${f}, }System.map-${ver}-v7l+"
		fi
		if use rpi2 || use rpi3; then
			[[ -e extra/System7.map ]] && newins extra/System7.map "System.map-${ver}-v7+"
			f="${f:+${f}, }System.map-${ver}-v7+"
		fi
		if use rpi0 || use rpi1; then
			[[ -e extra/System.map ]] && newins extra/System.map "System.map-${ver}+"
			f="${f:+${f}, }System.map-${ver}+"
		fi

		einfo "You should create a symlink from /System.map to ${boot}/System.map"
		einfo "and from ${boot}/System.map to one of"
		einfo "${f},"
		einfo "as appropriate."
	fi

	# Install Device Tree overlays ...
	insinto "${boot}"
	doins boot/*.dtb
	doins -r boot/overlays
}
