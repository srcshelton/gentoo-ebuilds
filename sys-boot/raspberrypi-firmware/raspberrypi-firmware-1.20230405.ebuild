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
	S="${WORKDIR}/firmware-${PV}/boot"
fi

DESCRIPTION="Raspberry Pi bootloader and GPU firmware"
HOMEPAGE="https://github.com/raspberrypi/firmware"

LICENSE="GPL-2 raspberrypi-videocore-bin"
SLOT="0"
IUSE="+64bit -devicetree -kernel +rpi-all rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s"
REQUIRED_USE="
	|| ( rpi-all rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s )
	rpi-all? ( !rpi0 !rpi02 !rpi1 !rpi-cm !rpi2 !rpi-cm2 !rpi3 !rpi-cm3 !rpi4 !rpi400 !rpi-cm4 !rpi-cm4s )
	64bit? ( || ( rpi-all rpi02 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s ) )
	kernel? ( devicetree )
"

# Temporary safety measure to prevent ending up with a pair of
# sys-kernel/raspberrypi-image and sys-boot/raspberrypi-firmware
# none of which installed device tree files.
# Remove when the mentioned version and all older ones are deleted.
RDEPEND="
	!<=sys-kernel/raspberrypi-image-4.19.57_p20190709
	devicetree? ( !sys-kernel/raspberrypi-image[devicetree] )
	!devicetree? ( sys-kernel/raspberrypi-image[devicetree] )
	kernel? ( !sys-kernel/raspberrypi-image )
"

RESTRICT="mirror strip"

FIRMWARE_DIR='/usr/share/raspberrypi/firmware'

QA_PREBUILT="
	${FIRMWARE_DIR#/}/start*.elf
	usr/lib/libelftoolchain.so
"

DOC_CONTENTS="Please customise your Raspberry Pi configuration by editing ${RASPBERRYPI_BOOT:-/boot}/config.txt"

pkg_setup() {
	local state='' boot="${RASPBERRYPI_BOOT:-/boot}"

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
	local boot="${RASPBERRYPI_BOOT:-/boot}"

	default

	cp "${FILESDIR}"/config.txt "${T}" || die

	if use arm64 && use 64bit; then
		# Select 64-bit kernel8.img to match our userland...
		if grep -q -- '^\s*arm_64bit=' "${T}"/config.txt; then
			sed -i "${T}"/config.txt \
				-e '/arm_64bit/s/arm_64bit=[^[:space:]#]\+/arm_64bit=1/' || die
		elif grep -q -- '#.*arm_64bit.*=' "${T}"/config.txt; then
			sed -i "${T}"/config.txt \
				-e '/arm_64bit/a arm_64bit=1' || die
		else
			echo "arm_64bit=1" >> "${T}"/config.txt || die
		fi
	fi

	cp "${FILESDIR}"/"${PN}"-envd "${T}"/"${PN}"-envd || die
	sed -i "s|/boot|${boot}|g" "${T}"/"${PN}"-envd || die
}

src_install() {
	local f='' boot="${RASPBERRYPI_BOOT:-/boot}"
	local -a repofiles=() files=()

	# Ancilliary files...
	#
	repofiles=( # <- Syntax
		autorun.inf
		logo.ico
	)

	files=( # <- Syntax
		COPYING.linux
		LICENCE.broadcom
	)

	# VideoCore firmware files...
	#
	if
			use rpi-all ||
			use rpi0 ||
			use rpi02 ||
			use rpi1 ||
			use rpi2 ||
			use rpi-cm2 ||
			use rpi3 ||
			use rpi-cm3
	then
		files+=( # <- Syntax
			bootcode.bin
			fixup_cd.dat
			fixup.dat
			fixup_db.dat
			fixup_x.dat
			start_cd.elf
			start_db.elf
			start.elf
			start_x.elf
		)
	fi

	if
			use rpi-all ||
			use rpi4 ||
			use rpi400 ||
			use rpi-cm4
	then
		files+=( # <- Syntax
			fixup4cd.dat
			fixup4.dat
			fixup4db.dat
			fixup4x.dat
			start4cd.elf
			start4db.elf
			start4.elf
			start4x.elf
		)
	fi

	# Kernel images...
	#
	if use kernel; then
		if
				use rpi-all ||
				use rpi1 || use rpi-cm ||
				use rpi0
		then
			files+=( # <- Syntax
				kernel.img
				$( use kernel && ls -1 ../modules/ | grep -Fv -- '-v' )
			)
		fi
		if
				use rpi-all ||
				use rpi2 || use rpi-cm2 ||
				use rpi02 ||
				use rpi3 || use rpi-cm3
		then
			files+=( # <- Syntax
				kernel7.img
				$( use kernel && ls -1 ../modules/ | grep -Fv -- '-v7+' )
			)
		fi
		if
				use rpi-all ||
				use rpi4 || use rpi-cm4 || use rpi-cm4s ||
				use rpi400
		then
			if use 64bit; then
				files+=( # <- Syntax
					kernel8.img
					$( use kernel && ls -1 ../modules/ | grep -Fv -- '-v8+' )
				)
			else
				files+=( # <- Syntax
					kernel7l.img
					$( use kernel && ls -1 ../modules/ | grep -Fv -- '-v7l+' )
				)
			fi
		fi
	fi

	# DeviceTree binaries...
	#
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
			files+=( # <- Syntax
				bcm2711-rpi-cm4-io.dtb
			)
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
	fi

	# 'keepdir' will fail on FAT32 filesystems = moved to pkg_preinst
	#keepdir "${boot}"
	#use devicetree && keepdir "${boot}"/overlays
	use kernel && keepdir /lib/modules

	# Install firmware blobs ...
	insinto "${FIRMWARE_DIR}"

	for f in "${repofiles[@]}"; do
		doins "${FILESDIR}/${f}"
	done
	doins -r "${files[@]}"
	use devicetree && doins -r overlays

	# config-protect config.txt and cmdline.txt
	doins "${T}"/config.txt
	doins "${FILESDIR}"/overclock.txt
	doins "${FILESDIR}"/legacy.txt
	doins "${FILESDIR}"/cmdline.txt
	newenvd "${T}"/"${PN}"-envd "90${PN}"

	if [[ "${ARCH}" == 'arm' ]]; then
		# Install library required by vcdbg ...
		dolib.so ../hardfp/opt/vc/lib/libelftoolchain.so
	fi

	readme.gentoo_create_doc
}

pkg_preinst() {
	local boot="${RASPBERRYPI_BOOT:-/boot}"

	mkdir -p "${boot}"
	touch "${boot}/.keep_${CATEGORY}_${PN}-${SLOT:-0}"
	if use devicetree; then
		mkdir -p "${boot}"/overlays
		touch "${boot}/overlays/.keep_${CATEGORY}_${PN}-${SLOT:-0}"
	fi

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
	if [[ "${MERGE_TYPE}" != "buildonly" ]]; then
		pkg_config
	fi

	mount-boot_pkg_postinst

	readme.gentoo_print_elog
}

pkg_postrm() {
	local boot="${RASPBERRYPI_BOOT:-/boot}" file=''
	local -a files=()

	files=( "${boot}/.keep_${CATEGORY}_${PN}-${SLOT:-0}" )
	if use devicetree; then
		files+=( "${boot}/overlays/.keep_${CATEGORY}_${PN}-${SLOT:-0}" )
	fi

	for file in "${files[@]}"; do
		if [[ -e "${file}" && -f "${file}" && ! -s "${file}" ]]; then
			rm "${file}"
			rmdir --ignore-fail-on-non-empty -p "${boot}" || :
		fi
	done

	mount-boot_pkg_postrm
}

pkg_config() {
	local boot="${RASPBERRYPI_BOOT:-/boot}" cfg=''
	local -i rc=0 s=0

	ebegin "Deploying Raspberry Pi firmware ${PV} from" \
		"${FIRMWARE_DIR} to ${RASPBERRYPI_BOOT}"

	set -o pipefail >/dev/null 2>&1
	if use devicetree; then
		if [[ -d "${RASPBERRYPI_BOOT}"/overlays ]]; then
			if ! mv "${RASPBERRYPI_BOOT}"/overlays "${RASPBERRYPI_BOOT}"/overlays.old; then
				eend ${?} "Failed to backup current 'overlays' directory"
				return ${?}
			fi
		fi
		cp -r "${FIRMWARE_DIR}/overlays" "${RASPBERRYPI_BOOT}/" ||
			eend ${?} "'overlays' directory copy failed: ${?}" ||
			return ${?}
	fi
	find "${FIRMWARE_DIR}" \
				-mindepth 1 \
				-maxdepth 1 \
				-type f \
				-not -name config.txt \
				-not -name cmdline.txt \
				-print0 |
		xargs -0 -r -I'{}' cp '{}' "${RASPBERRYPI_BOOT}/"
	rc=${?}
	eend ${rc} "firmware file copy failed: ${rc}" || return ${rc}

	for cfg in config overclock legacy cmdline; do
		if [[ -s "${FIRMWARE_DIR}/${cfg}.txt" ]]; then
			for s in {0..9999}; do
				[[ -e "${RASPBERRYPI_BOOT}/._cfg$( printf '%04d' "${s}" )_${cfg}.txt" ]] || break
			done
			cp "${FIRMWARE_DIR}/${cfg}.txt" \
				"${RASPBERRYPI_BOOT}/._cfg$( printf '%04d' "${s}" )_${cfg}.txt"
		fi
	done

	if use devicetree && [[ -d "${RASPBERRYPI_BOOT}"/overlays.old ]]; then
		if ! (( rc )); then
			if ! diff -qr "${RASPBERRYPI_BOOT}"/overlays{.old,}; then
				ewarn "Overlay differences:"
				diff -r "${RASPBERRYPI_BOOT}"/overlays{.old,}
				elog "Please remove '${RASPBERRYPI_BOOT}/overlays.old' once" \
					"reconciled"
			else
				rm -r "${RASPBERRYPI_BOOT}"/overlays.old
			fi
		fi
	fi
}

# vi: set diffopt=filler,iwhite:
