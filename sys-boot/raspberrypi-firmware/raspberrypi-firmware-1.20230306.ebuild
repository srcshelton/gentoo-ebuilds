# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit mount-boot readme.gentoo-r1

if [[ "${PV}" == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/raspberrypi/firmware"
	EGIT_CLONE_TYPE="shallow" # The current repo is ~4GB in size, but contains
				  # only ~200MB of data - the rest is (literally)
				  # history :(
	if ! [[ "${PV}" == 9999 ]]; then
		EGIT_BRANCH="stable"
	fi
else
	SRC_URI="https://github.com/raspberrypi/firmware/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* arm arm64"
	S="${WORKDIR}/firmware-${PV}"
fi

DESCRIPTION="Raspberry Pi bootloader and GPU firmware"
HOMEPAGE="https://github.com/raspberrypi/firmware"

LICENSE="GPL-2 raspberrypi-videocore-bin"
SLOT="0"
IUSE="64bit +rpi4"

# Temporary safety measure to prevent ending up with a pair of
# sys-kernel/raspberrypi-image and sys-boot/raspberrypi-firmware
# none of which installed device tree files.
# Remove when the mentioned version and all older ones are deleted.
RDEPEND="!<=sys-kernel/raspberrypi-image-4.19.57_p20190709"

RESTRICT="binchecks mirror strip"

QA_PREBUILT="/boot/start*.elf /usr/lib/libelftoolchain.so"

DOC_CONTENTS="Please customise your Raspberry Pi configuration by editing ${RASPBERRYPI_BOOT:-/boot}/config.txt"

pkg_setup() {
	local state boot="${RASPBERRYPI_BOOT:-/boot}"

	einfo "Checking mount-points ..."

	[[ "${boot}" == "${boot// }" ]] || die "Invalid value '${boot}' for control variable 'RASPBERRYPI_BOOT'"
	[[ "${boot:0:1}" == "/" ]] || die "Invalid value '${boot}' for control variable 'RASPBERRYPI_BOOT': Value must be absolute path"
	boot="$( readlink -e "${boot}" )" || die "readlink failed: ${?}"

	export RASPBERRYPI_BOOT="${boot}"

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

	cp "${FILESDIR}"/${PN}-1.20201022-config.txt "${T}" || die

	if use arm64 && use 64bit; then
		# Select 64-bit kernel8.img to match our userland...
		echo "arm_64bit=1" >> "${T}"/${PN}-1.20201022-config.txt || die
	fi
}

src_install() {
	local f boot="${RASPBERRYPI_BOOT:-/boot}" ver

	keepdir "${boot}"

	# Install firmware blobs ...
	insinto "${boot}"
	for f in boot/*.bin boot/*.dat boot/*.elf boot/LICEN[CS]E.*; do
		if [[ -e "${f}" ]]; then
			case "${f}" in
				boot/bootcode.bin)
					use rpi4 && continue
					;;
				boot/*.elf|boot/*.dat)
					if use rpi4; then
						[[ "${f}" != *4* ]] && continue
					else
						[[ "${f}" == *4* ]] && continue
					fi
					;;
			esac
			doins "${f}"
		fi
	done

	if [[ "${ARCH}" == 'arm' ]]; then
		# Install library required by vcdbg ...
		#insinto /usr/$(get_libdir)
		insinto /usr/lib
		doins hardfp/opt/vc/lib/libelftoolchain.so
	fi

	insinto "${boot}"
	newins "${T}"/${PN}-1.20201022-config.txt config.txt
	newins "${FILESDIR}"/${PN}-1.20201022-cmdline.txt cmdline.txt

	cp "${FILESDIR}"/"${PN}"-0_p20130711-envd "${T}"/"${PN}"-envd
	sed -i "s|/boot|${boot}|g" "${T}"/"${PN}"-envd
	newenvd "${T}"/"${PN}"-envd "90${PN}"

	readme.gentoo_create_doc
}

pkg_preinst() {
	local boot="${RASPBERRYPI_BOOT:-/boot}"

	if [[ "${MERGE_TYPE}" != "buildonly" ]]; then
		if [[ -z "${REPLACING_VERSIONS}" ]] ; then
			local msg=""

			if [[ -e "${ED}"/boot/cmdline.txt ]] && [[ -e /boot/cmdline.txt ]] ; then
				msg+="/boot/cmdline.txt "
			fi

			if [[ -e "${ED}${boot}"/config.txt ]] && [[ -e "${boot}"/config.txt ]] ; then
				msg+="${boot}/config.txt "
			fi

			if [[ -n "${msg}" ]] ; then
				msg="This package installs the following files: ${msg}"
				msg="${msg} Please backup and remove your local verions prior to installation"
				msg="${msg} and merge your changes afterwards."
				msg="${msg} Further updates will be CONFIG_PROTECTed."
				die "${msg}"
			fi
		fi
	fi

	mount-boot_pkg_preinst
}

pkg_postinst() {
	mount-boot_pkg_postinst

	readme.gentoo_print_elog
}

# vi: set diffopt=filler,iwhite:
