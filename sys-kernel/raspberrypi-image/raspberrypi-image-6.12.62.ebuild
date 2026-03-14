# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit mount-boot

DESCRIPTION="Raspberry Pi kernel, devicetree and modules"
HOMEPAGE="https://archive.raspberrypi.com/debian/pool/main/l/linux/"
LICENSE="GPL-2 raspberrypi-videocore-bin"
SLOT="${PV#*"_p"}"
IUSE="+64bit +devicetree +os-prefix -rpi-all rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi-cm4-io rpi5 rpi500 rpi-cm5 rpi-cm5-io rt"
REQUIRED_USE="
	|| ( rpi-all rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi500 rpi-cm5 )
	64bit? ( || ( rpi-all rpi02 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi500 rpi-cm5 ) )
	os-prefix? ( devicetree )
	rpi-all? ( !rpi0 !rpi02 !rpi1 !rpi-cm !rpi2 !rpi-cm2 !rpi3 !rpi-cm3 !rpi4 !rpi400 !rpi-cm4 !rpi-cm4s !rpi5 !rpi500 !rpi-cm5 )
	rpi-cm4-io? ( || ( rpi-cm4 rpi-cm5 ) )
	rpi-cm5-io? ( rpi-cm5 )
	rt? ( || ( rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi500 rpi-cm5 ) )
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
	!sys-kernel/linux-firmware[compress-xz]
"
BDEPEND="sys-devel/binutils"

IMAGE_BASE="https://archive.raspberrypi.com/debian/pool/main/l/linux"
IMAGE_2712="${IMAGE_BASE}/linux-image-${PV}+rpt-rpi-2712_${PV}-1+rpt1_arm64.deb"
IMAGE_V8="${IMAGE_BASE}/linux-image-${PV}+rpt-rpi-v8_${PV}-1+rpt1_arm64.deb"
IMAGE_V8_RT="${IMAGE_BASE}/linux-image-${PV}+rpt-rpi-v8-rt_${PV}-1+rpt1_arm64.deb"
IMAGE_V7="${IMAGE_BASE}/linux-image-${PV}+rpt-rpi-v7_${PV}-1+rpt1_armhf.deb"
IMAGE_V7L="${IMAGE_BASE}/linux-image-${PV}+rpt-rpi-v7l_${PV}-1+rpt1~bookworm_armhf.deb"
IMAGE_V6="${IMAGE_BASE}/linux-image-${PV}+rpt-rpi-v6_${PV}-1+rpt1_armhf.deb"

if [[ "${PV}" == '9999' ]]; then
	EGIT_REPO_URI="https://github.com/raspberrypi/firmware"
	EGIT_CLONE_TYPE="shallow"
	inherit git-r3
else
	SRC_URI="
		64bit? (
			rpi5? ( ${IMAGE_2712} )
			rpi500? ( ${IMAGE_2712} )
			rpi-cm5? ( ${IMAGE_2712} )

			rpi5? ( ${IMAGE_V8} )
			rpi500? ( ${IMAGE_V8} )
			rpi-cm5? ( ${IMAGE_V8} )
			rpi4? ( ${IMAGE_V8} )
			rpi400? ( ${IMAGE_V8} )
			rpi-cm4? ( ${IMAGE_V8} )
			rpi-cm4s? ( ${IMAGE_V8} )
			rpi02? ( ${IMAGE_V8} )
			rpi3? ( ${IMAGE_V8} )
			rpi-cm3? ( ${IMAGE_V8} )

			rt? (
				rpi5? ( ${IMAGE_V8_RT} )
				rpi500? ( ${IMAGE_V8_RT} )
				rpi-cm5? ( ${IMAGE_V8_RT} )
				rpi4? ( ${IMAGE_V8_RT} )
				rpi400? ( ${IMAGE_V8_RT} )
				rpi-cm4? ( ${IMAGE_V8_RT} )
				rpi-cm4s? ( ${IMAGE_V8_RT} )
				rpi02? ( ${IMAGE_V8_RT} )
				rpi3? ( ${IMAGE_V8_RT} )
				rpi-cm3? ( ${IMAGE_V8_RT} )
			)
		)
		!64bit? (
			rpi4? ( ${IMAGE_V7L} )
			rpi400? ( ${IMAGE_V7L} )
			rpi-cm4? ( ${IMAGE_V7L} )
			rpi-cm4s? ( ${IMAGE_V7L} )

			rpi02? ( ${IMAGE_V7} )
			rpi3? ( ${IMAGE_V7} )
			rpi-cm3? ( ${IMAGE_V7} )
			rpi2? ( ${IMAGE_V7} )
			rpi-cm2? ( ${IMAGE_V7} )

			rpi0? ( ${IMAGE_V6} )
			rpi1? ( ${IMAGE_V6} )
			rpi-cm? ( ${IMAGE_V6} )
		)
		rpi-all? ( ${IMAGE_2712} ${IMAGE_V8_RT} ${IMAGE_V8} ${IMAGE_V7L} ${IMAGE_V7} ${IMAGE_V6} )
	"
	KEYWORDS="-* arm arm64"
fi

FIRMWARE_DIR="/usr/share/raspberrypi/kernel/${PV}"

pkg_setup() {
	local state boot="${RASPBERRYPI_BOOT:-/boot}"

	einfo "Checking mount-points ..."

	[[ "${boot}" == "${boot// }" ]] ||
		die "Invalid value '${boot}' for control variable 'RASPBERRYPI_BOOT'"
	[[ "${boot:0:1}" == "/" ]] ||
		die "Invalid value '${boot}' for control variable" \
			"'RASPBERRYPI_BOOT': Value must be absolute path"
	boot="$( readlink -e "${boot}" )" ||
		die "readlink failed: ${?}"

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
			die "Please set the RASPBERRYPI_BOOT environment variable in" \
				"/etc/portage/make.conf"
		fi

		state="$(
				cut -d' ' -f 2-4 /proc/mounts 2>/dev/null |
					grep -E "^${boot} (u?msdos|v?fat) " |
					grep -Eo '[ ,]r[ow](,|$)' |
					sed 's/[ ,]//g'
			)"
		case "${state}" in
			rw)
				:
				;;
			ro)
				die "Filesystem '${boot}' is currently mounted read-only -" \
					"installation cannot proceed"
				;;
			*)
				ewarn "Cannot determine mount-state of boot filesystem" \
					"'${boot}' - is this partition mounted?"
				;;
		esac
	fi
}

src_unpack() {
	local deb='' mod_dir=''

	# bookworm layout:
	#   boot/
	#   lib/
	#     modules/
	#       e.g. 6.12.62+rpt-rpi-v7l
	#   
	# trixie layout:
	#   boot/
	#     System.map
	#     config
	#     vmlinuz
	#   usr/lib/
	#     linux-image/
	#       broadcom/
	#       overlays/
	#     modules/
	#       e.g. 6.12.62+rpt-rpi-2712
	#
	mkdir -p "${S}" || die

	for deb in ${A}; do
		# e.g. 'linux-image-6.12.62+rpt-rpi-v7l_6.12.62-1+rpt1_armhf.deb'
		einfo "Unpacking '${deb}' ..."

		mod_dir="${deb#"linux-image-"}"
		mod_dir="${mod_dir%"_${PV}"*}"

		ar -x --output="${T}" "${DISTDIR}/${deb}" ||
			die "src_unpack 'ar'-step failed for '${deb}': ${?}"
		tar -C "${S}" -xJpf "${T}"/data.tar.xz ||
			die "src_unpack 'tar'-step failed for '${deb}': ${?}"
		if ! [[ -d "${S}/lib/modules/${mod_dir}" ]] &&
				! [[ -d "${S}/usr/lib/modules/${mod_dir}" ]]
		then
			if [[ "${deb}" =~ bookworm ]]; then
				die "src_unpack failed to extract" \
					"'${S}/lib/modules/${mod_dir}' from '${deb}'"
			else
				die "src_unpack failed to extract" \
					"'${S}/usr/lib/modules/${mod_dir}' from '${deb}'"
			fi
		fi
		rm "${T}"/control.tar.xz "${T}"/data.tar.xz "${T}"/debian-binary ||
			die "src_unpack 'rm'-step failed for '${deb}': ${?}"
	done

}

src_prepare() {
	local kernel_ext=''
	local -i found=0

	rm -r "${S:?}"/usr/share

	mkdir -p "${S}"/modules

	while read -r debver; do
		mv "${debver}" "${S}"/modules/ || die
	done < <(
		[[ -d "${S}"/usr/lib/modules/ ]] && \
			find "${S}"/usr/lib/modules/ \
				-mindepth 1 -maxdepth 1 \
				-type d \
				-print

		[[ -d "${S}"/usr/lib/modules/ ]] && \
			find "${S}"/lib/modules/ \
				-mindepth 1 -maxdepth 1 \
				-type d \
				-print
	)
	rmdir "${S}"/usr/lib/modules "${S}"/lib/modules 2>/dev/null || :

	default

	for kernel_ext in '2712' 'v8-rt' 'v8' 'v7l' 'v7' 'v6'; do
		case "${kernel_ext}" in
			'2712')
				if use rpi-all || { use 64bit && {
							use rpi5 || use rpi500 || use rpi-cm5
						}; }
				then
					if ! [[ -s "${S}/modules/${PV}+rpt-rpi-${kernel_ext}" ]]
					then
						die "Could not find" \
							"'${S}/modules/${PV}+rpt-rpi-${kernel_ext}'"
					else
						einfo "Found '${PV}+rpt-rpi-${kernel_ext}' modules"
						found=1
					fi
				fi
				;;
			'v8-rt')
				if use rpi-all || { use 64bit && {
							use rpi4 || use rpi400 || use rpi-cm4 ||
							use rpi-cm4s ||
							use rpi02 ||
							use rpi3 || use rpi-cm3
						}; }
				then
					if ! [[ -s "${S}/modules/${PV}+rpt-rpi-${kernel_ext}" ]]
					then
						die "Could not find" \
							"'${S}/modules/${PV}+rpt-rpi-${kernel_ext}'"
					else
						einfo "Found '${PV}+rpt-rpi-${kernel_ext}' modules"
						found=1
					fi
				fi
				;;
			'v8')
				if use rpi-all || { use 64bit && {
							use rpi4 || use rpi400 || use rpi-cm4 ||
							use rpi-cm4s ||
							use rpi02 ||
							use rpi3 || use rpi-cm3
						}; }
				then
					if ! [[ -s "${S}/modules/${PV}+rpt-rpi-${kernel_ext}" ]]
					then
						die "Could not find" \
							"'${S}/modules/${PV}+rpt-rpi-${kernel_ext}'"
					else
						einfo "Found '${PV}+rpt-rpi-${kernel_ext}' modules"
						found=1
					fi
				fi
				;;
			'v7l')
				if use rpi-all || { use !64bit && {
							use rpi4 || use rpi400 || use rpi-cm4 ||
							use rpi-cm4s
						}; }
				then
					if ! [[ -s "${S}/modules/${PV}+rpt-rpi-${kernel_ext}" ]]
					then
						die "Could not find" \
							"'${S}/modules/${PV}+rpt-rpi-${kernel_ext}'"
					else
						einfo "Found '${PV}+rpt-rpi-${kernel_ext}' modules"
						found=1
					fi
				fi
				;;
			'v7')
				if use rpi-all || { use !64bit && {
							use rpi3 || use rpi-cm3 ||
							use rpi2 || use rpi-cm2 ||
							use rpi02
						}; }
				then
					if ! [[ -s "${S}/modules/${PV}+rpt-rpi-${kernel_ext}" ]]
					then
						die "Could not find" \
							"'${S}/modules/${PV}+rpt-rpi-${kernel_ext}'"
					else
						einfo "Found '${PV}+rpt-rpi-${kernel_ext}' modules"
						found=1
					fi
				fi
				;;
			'v6')
				if use rpi-all || { use !64bit && {
							use rpi1 || use rpi-cm ||
							use rpi0
						}; }
				then
					if ! [[ -s "${S}/modules/${PV}+rpt-rpi-${kernel_ext}" ]]
					then
						die "Could not find" \
							"'${S}/modules/${PV}+rpt-rpi-${kernel_ext}'"
					else
						einfo "Found '${PV}+rpt-rpi-${kernel_ext}' modules"
						found=1
					fi
				fi
				;;
		esac
	done

	if ! (( found )); then
		die "Could not find any kernel module directory for USE flags" \
			"'${USE}' beneath '${S}/modules'"
	fi
}

src_install() {
	local f='' boot="${RASPBERRYPI_BOOT:-/boot}"
	local variant_64='' variant_32=''
	local -i found=0
	local -a files=()

	# See https://www.raspberrypi.com/documentation/computers/linux_kernel.html#native-build-configuration
	#
	# Filename         Processor                           Raspberry Model
	#kernel.img       BCM2835                             pi0, pi1 32-bit
	#kernel7.img      BCM2836, BCM2837                    pi2, pi3 32-bit
	#kernel7l.img     BCM2711, BCM2712                    pi4, pi5 32-bit
	#kernel8.img      BCM2836, BCM2837, BCM2711, BCM2712  pi2/3/4/5 64-bit
	#kernel_2712.img  BCM2712                             pi5 64-bit kernel,
	#                                                     16k pages

	# Trixie packages have v6 & v7 DTBs in /usr/lib/<package>/, v8, v8_rt and
	# 2712 DTBs in /usr/lib/<package>/broadcom;
	# overlays are always /usr/lib/<package>/overlays;
	# the kernel image is, e.g. /boot/vmlinuz-6.12.62+rpt-rpi-2712

	# Install kernel(s) ...
	insinto "${FIRMWARE_DIR}"

	for f in boot/vmlinuz-*; do
		case "${f}" in
			"boot/vmlinuz-${PV}+rpt-rpi-v6")
				einfo "Found '${f}' ..."
				if use rpi-all || use rpi1 || use rpi-cm || use rpi0; then
					elog "Installing 'vmlinuz-${PV}+rpt-rpi-v6'/'kernel.img' for BCM2835 (Raspberry Pi Zero, Raspberry Pi) ..."
					newins "${f}" 'kernel.img'
					found=1
					variant_32='v6'
				fi
				;;
			"boot/vmlinuz-${PV}+rpt-rpi-v7")
				einfo "Found '${f}' ..."
				if use rpi-all || use rpi2 || use rpi-cm2 || use rpi3 || use rpi-cm3 || use rpi02; then
					elog "Installing 'vmlinuz-${PV}+rpt-rpi-v7'/'kernel7.img' for BCM2836 & BCM2837 (Raspberry Pi 2, Raspberry Pi 3, Raspberry Pi Zero 2 32bit) ..."
					newins "${f}" 'kernel7.img'
					found=1
					variant_32='v7'
				fi
				;;
			"boot/vmlinuz-${PV}+rpt-rpi-v7l")
				einfo "Found '${f}' ..."
				if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
					if use rpi-all || use !64bit; then
						elog "Installing 'vmlinuz-${PV}+rpt-rpi-v7l'/'kernel7l.img' for BCM2711 (Raspberry Pi 4/5 LPAE 32bit) ..."
						newins "${f}" 'kernel7l.img'
						found=1
						variant_32='v7l'
					fi
				fi
				;;
			"boot/vmlinuz-${PV}+rpt-rpi-v8")
				einfo "Found '${f}' ..."
				if use rpi-all || use rpi3 || use rpi-cm3 || use rpi02 || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s || use rpi5 || use rpi500 || use rpi-cm5; then
					if use rpi-all || use 64bit; then
						elog "Installing 'vmlinuz-${PV}+rpt-rpi-v8'/'kernel8.img' for BCM2836, BCM2837, BCM2711 (Raspberry Pi 3+ 64bit) ..."
						newins "${f}" 'kernel8.img'
						found=1
						variant_64='v8'
					fi
				fi
				;;
			"boot/vmlinuz-${PV}+rpt-rpi-v8-rt")
				einfo "Found '${f}' ..."
				if use rpi-all || use rpi3 || use rpi-cm3 || use rpi02 || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s || use rpi5 || use rpi500 || use rpi-cm5; then
					if use rpi-all || { use 64bit && use rt; }; then
						elog "Installing 'vmlinuz-${PV}+rpt-rpi-v8-rt'/'kernel8-rt.img' for BCM2836, BCM2837, BCM2711 (Raspberry Pi 3+ 64bit) ..."
						newins "${f}" 'kernel8-rt.img'
						found=1
						variant_64='v8-rt'
					fi
				fi
				;;
			"boot/vmlinuz-${PV}+rpt-rpi-2712")
				einfo "Found '${f}' ..."
				if use rpi-all || use rpi5 || use rpi500 || use rpi-cm5; then
					elog "Installing 'vmlinuz-${PV}+rpt-rpi-2712'/'kernel_2712.img' for BCM2712 (Raspberry Pi 5 64bit, 16k pages) ..."
					newins "${f}" 'kernel_2712.img'
					found=1
					variant_64='2712'
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
	if ! (( found )); then
		die "Failed to install any known kernel image - please check ebuild logic"
	fi
	files=()

	# Install kernel modules
	#
	insinto /lib/modules
	for f in modules/*; do
		case "${f}" in
			*'-v6')
				if use rpi-all || use rpi1 || use rpi-cm || use rpi0; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2835 (Raspberry Pi Zero, Raspberry Pi) ..."
					doins -r "${f}"
					dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
					files+=( "${f}" )
				fi
				;;
			*'-v7')
				if use rpi-all || use rpi2 || use rpi-cm2 || use rpi3 || use rpi-cm3 || use rpi02; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2836 & BCM2837 (Raspberry Pi 2, Raspberry Pi 3, Raspberry Pi Zero 2 32bit) ..."
					doins -r "${f}"
					dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
					files+=( "${f}" )
				fi
				;;
			*'-v7l')
				if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
					if use rpi-all || use !64bit; then
						einfo "Installing kernel modules '${f#modules/}' for BCM2711 (Raspberry Pi 4 LPAE 32bit) ..."
						doins -r "${f}"
						dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
						files+=( "${f}" )
					fi
				fi
				;;
			*'-v8')
				if use rpi-all || use rpi3 || use rpi-cm3 || use rpi02 || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
					if use rpi-all || use 64bit; then
						einfo "Installing kernel modules '${f#modules/}' for BCM2836+ (Raspberry Pi 3+ 64bit) ..."
						doins -r "${f}"
						dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
						files+=( "${f}" )
					fi
				fi
				;;
			*'-v8-rt')
				if use rpi-all || use rpi3 || use rpi-cm3 || use rpi02 || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
					if use rpi-all || { use 64bit && use rt; }; then
						einfo "Installing kernel modules '${f#modules/}' for BCM2836+ (Raspberry Pi 3+ 64bit PREEMPT_RT) ..."
						doins -r "${f}"
						dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
						files+=( "${f}" )
					fi
				fi
				;;
			*'-2712')
				if use rpi-all || use rpi5 || rpi500 || use rpi-cm5; then
					einfo "Installing kernel modules '${f#modules/}' for BCM2712 (Raspberry Pi 5 64bit, 16k pages) ..."
					doins -r "${f}"
					dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
					files+=( "${f}" )
				fi
				;;
			*)
				if [[ -e "${f}" ]]; then
					ewarn "Installing unknown kernel modules '${f#modules/}' ..."
					doins -r "${f}"
					dosym "/lib/modules/$( basename "${f}" )" "${FIRMWARE_DIR}/modules-$( basename "${f}" )"
				fi
				;;
		esac
	done
	if ! (( ${#files[@]} )); then
		die "Failed to install any known kernel modules - please check ebuild logic"
	fi
	doins -r "${files[@]}"
	files=()

	insinto "${FIRMWARE_DIR}"

	# There's little or no standardisation in regards to where System.map
	# should live, and the only two common locations seem to be /boot and /
	f=""
	if use rpi-all || use rpi5 || use rpi500 || use rpi-cm5; then
		if [[ -e "boot/System.map-${PV}+rpt-rpi-2712" ]]; then
			newins "boot/System.map-${PV}+rpt-rpi-2712" \
				"System.map-${PV}+rpt-rpi-2712"
			f="${f:+${f}, }System.map-${PV}+rpt-rpi-2712"
			files+=( "boot/System.map-${PV}+rpt-rpi-2712" "boot/config-${PV}+rpt-rpi-2712" )
		fi
	fi
	if use rpi-all || use rpi5 || use rpi500 || use rpi-cm5 || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s || use rpi02 || use rpi3 || use rpi-cm3; then
		if use rpi-all || use 64bit; then
			if [[ -e "boot/System.map-${PV}+rpt-rpi-v8" ]]; then
				newins "boot/System.map-${PV}+rpt-rpi-v8" \
					"System.map-${PV}+rpt-rpi-v8"
				f="${f:+${f}, }System.map-${PV}+rpt-rpi-v8"
				files+=( "boot/System.map-${PV}+rpt-rpi-v8" "boot/config-${PV}+rpt-rpi-v8" )
			fi
		fi
	fi
	if use rpi-all || use rpi5 || use rpi500 || use rpi-cm5 || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s || use rpi02 || use rpi3 || use rpi-cm3; then
		if use rpi-all || { use 64bit && use rt; }; then
			if [[ -e "boot/System.map-${PV}+rpt-rpi-v8-rt" ]]; then
				newins "boot/System.map-${PV}+rpt-rpi-v8-rt" \
					"System.map-${PV}+rpt-rpi-v8-rt"
				f="${f:+${f}, }System.map-${PV}+rpt-rpi-v8-rt"
				files+=( "boot/System.map-${PV}+rpt-rpi-v8-rt" "boot/config-${PV}+rpt-rpi-v8-rt" )
			fi
		fi
	fi
	if use rpi-all || use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
		if use rpi-all || use !64bit; then
			if [[ -e "boot/System.map-${PV}+rpt-rpi-v7l" ]]; then
				newins "boot/System.map-${PV}+rpt-rpi-v7l" \
					"System.map-${PV}+rpt-rpi-v7l"
				f="${f:+${f}, }System.map-${PV}+rpt-rpi-v7l"
				files+=( "boot/System.map-${PV}+rpt-rpi-v7l" "boot/config-${PV}+rpt-rpi-v7l" )
			fi
		fi
	fi
	if use rpi-all || use rpi2 || use rpi-cm2 || use rpi3 || use rpi-cm3 || use rpi02; then
		if use rpi-all || use !64bit; then
			if [[ -e "boot/System.map-${PV}+rpt-rpi-v7" ]]; then
				newins "boot/System.map-${PV}+rpt-rpi-v7" \
					"System.map-${PV}+rpt-rpi-v7"
				f="${f:+${f}, }System.map-${PV}+rpt-rpi-v7"
				files+=( "boot/System.map-${PV}+rpt-rpi-v7" "boot/config-${PV}+rpt-rpi-v7" )
			fi
		fi
	fi
	if use rpi-all || use rpi1 || use rpi-cm || use rpi0; then
			if [[ -e "boot/System.map-${PV}+rpt-rpi-v6" ]]; then
				newins "boot/System.map-${PV}+rpt-rpi-v6" \
					"System.map-${PV}+rpt-rpi-v6"
				f="${f:+${f}, }System.map-${PV}+rpt-rpi-v6"
				files+=( "boot/System.map-${PV}+rpt-rpi-v6" "boot/config-${PV}+rpt-rpi-v6" )
			fi
	fi

	einfo "You should create a symlink from /System.map to ${boot}/System.map"
	einfo "and from ${boot}/System.map to one of:"
	einfo
	xargs -r -n 1 einfo '   ' <<<"${f}"
	einfo
	einfo "... as appropriate."

	if ! (( ${#files[@]} )); then
		ewarn "Failed to install any 'System.map' file - please check ebuild logic"
	else
		doins "${files[@]}"
	fi
	files=()

	# Install Device Tree overlays ...
	#
	# The list of available 32-bit and 64-bit files differs, but it appears
	# that the practical difference is that RPi5+ DTB files are only made
	# available with 64bit kernels.
	#
	# N.B. Presented in roughly directory-listing order
	#
	if use devicetree; then
		if use rpi-all || use rpi1; then
			files+=( # <- Syntax
				bcm2708-rpi-b-plus.dtb
				bcm2708-rpi-b-rev1.dtb
				bcm2708-rpi-b.dtb
				bcm2835-rpi-a.dtb
				bcm2835-rpi-b-plus.dtb
				bcm2835-rpi-b-rev2.dtb
				bcm2835-rpi-b.dtb
			)
		fi
		if use rpi-all || use rpi-cm; then
			files+=( # <- Syntax
				bcm2708-rpi-cm.dtb
				bcm2835-rpi-cm1-io1.dtb
			)
		fi
		if use rpi-all || use rpi0; then
			files+=( # <- Syntax
				bcm2708-rpi-zero-w.dtb
				bcm2708-rpi-zero.dtb
				bcm2835-rpi-zero-w.dtb
				bcm2835-rpi-zero.dtb
			)
		fi
		if use rpi-all || use rpi2; then
			files+=( # <- Syntax
				bcm2709-rpi-2-b.dtb
				bcm2710-rpi-2-b.dtb
				bcm2836-rpi-2-b.dtb
			)
		fi
		if use rpi-all || use rpi-cm2; then
			files+=( # <- Syntax
				bcm2709-rpi-cm2.dtb
			)
		fi
		if use rpi-all || use rpi3; then
			files+=( # <- Syntax
				bcm2710-rpi-3-b-plus.dtb
				bcm2710-rpi-3-b.dtb
				bcm2837-rpi-3-a-plus.dtb
				bcm2837-rpi-3-b-plus.dtb
				bcm2837-rpi-3-b.dtb
			)
		fi
		#if use rpi-all || use rpi-cm0; then
		#	files+=( # <- Syntax
		#		bcm2710-rpi-cm0.dtb
		#
		#		bcm2710-rpi-cm0.dtb
		#	)
		#fi
		if use rpi-all || use rpi-cm3; then
			files+=( # <- Syntax
				bcm2710-rpi-cm3.dtb
				bcm2837-rpi-cm3-io3.dtb
			)
		fi
		if use rpi-all || use rpi02; then
			files+=( # <- Syntax
				bcm2710-rpi-zero-2-w.dtb
				bcm2710-rpi-zero-2.dtb
				bcm2837-rpi-zero-2-w.dtb
			)
		fi
		if use rpi-all || use rpi4; then
			files+=( # <- Syntax
				bcm2711-rpi-4-b.dtb
			)
		fi
		if use rpi-all || use rpi400; then
			files+=( # <- Syntax
				bcm2711-rpi-400.dtb
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
		if use rpi-all || use rpi5; then
			files+=( # <- Syntax
				bcm2712-d-rpi-5-b.dtb
				bcm2712-rpi-5-b.dtb
				# Raspberry Pi 5 Lite (2GB RAM), with cost-reduced 2712 CPU...
				bcm2712d0-rpi-5-b.dtb
			)
		fi
		if use rpi-all || use rpi500; then
			files+=( # <- Syntax
				bcm2712-rpi-500.dtb
			)
		fi
		if use rpi-all || use rpi-cm5; then
			if use rpi-all || use rpi-cm4-io; then
				files+=( # <- Syntax
					bcm2712-rpi-cm5-cm4io.dtb
					bcm2712-rpi-cm5l-cm4io.dtb
				)
			fi
			if use rpi-all || use rpi-cm5-io; then
				files+=( # <- Syntax
					bcm2712-rpi-cm5-cm5io.dtb
					bcm2712-rpi-cm5l-cm5io.dtb
				)
			fi
		fi

		if ! (( ${#files[@]} )); then
			die "Failed to install any Devicetree files - please check ebuild logic"
		else
			for f in "${files[@]}"; do
				case "${f}" in
					'bcm2712'*)
						if [[ -n "${variant_64:-}" ]]; then
							doins "usr/lib/linux-image-${PV}+rpt-rpi-${variant_64}/broadcom/${f}"
						else
							die "Unable to install file '${f}' with no recognised 64-bit variant available"
						fi
						;;
					'bcm271'*|'bcm2837'*)
						if [[ -n "${variant_64:-}" ]]; then
							doins "usr/lib/linux-image-${PV}+rpt-rpi-${variant_64}/broadcom/${f}"
						elif [[ -n "${variant_32:-}" ]]; then
							doins "usr/lib/linux-image-${PV}+rpt-rpi-${variant_32}/${f}"
						else
							die "Unable to install file '${f}' with no recognised variant available"
						fi
						;;
					*)
						if [[ -n "${variant_32:-}" ]]; then
							doins "usr/lib/linux-image-${PV}+rpt-rpi-${variant_32}//${f}"
						else
							die "Unable to install file '${f}' with no recognised 32-bit variant available"
						fi
						;;
				esac
			done
		fi

		if [[ -n "${variant_64:-}" ]]; then
			doins -r "usr/lib/linux-image-${PV}+rpt-rpi-${variant_64}/overlays"
		elif [[ -n "${variant_32:-}" ]]; then
			doins -r "usr/lib/linux-image-${PV}+rpt-rpi-${variant_32}/overlays"
		else
			die "Unable to install overlays with no recognised variant available"
		fi
	fi
}

pkg_postinst() {
	mount-boot_pkg_postinst

	if [[ "${MERGE_TYPE}" != "buildonly" ]]; then
		pkg_config
	fi
}

pkg_config() {
	local boot="${RASPBERRYPI_BOOT:-"${ROOT%/}/boot"}"

	if use os-prefix; then
		boot="${boot}/${PV}"
		mkdir -p "${boot}"
	fi
	#touch "${boot}/.keep_${CATEGORY}_${PN}-${SLOT:-0}"

	ebegin "Deploying Raspberry Pi kernel ${PV} from" \
		"${ROOT%/}${FIRMWARE_DIR} to ${boot}"

	set -o pipefail >/dev/null 2>&1
	if use devicetree; then
		if [[ -d "${boot}"/overlays ]]; then
			if ! mv "${boot}"/overlays "${boot}"/overlays.old; then
				eend ${?} "Failed to backup current 'overlays' directory"
				return ${?}
			fi
		fi
		if ! cp -R "${ROOT%/}${FIRMWARE_DIR}/overlays" "${boot}/"; then
			eend ${?} "Failed to copy 'overlays' directory: ${?}"
			return ${?}
		fi
		#touch "${boot}/overlays/.keep_${CATEGORY}_${PN}-${SLOT:-0}"
		if ! [[ -e "${boot}/overlays/README" ]]; then
			eend "Marker file '${boot}/overlays/README' is missing"
			return 1
		fi
	fi
	if ! find "${ROOT%/}${FIRMWARE_DIR}" \
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
