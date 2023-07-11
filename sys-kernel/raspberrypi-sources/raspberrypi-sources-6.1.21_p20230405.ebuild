# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CKV="${PV%_p*}"

ETYPE=sources
#K_DEFCONFIG="bcmrpi_defconfig" # Set below...
K_SECURITY_UNSUPPORTED=1
#EXTRAVERSION="-${PN}/-*" # Set below...

K_EXP_GENPATCHES_NOUSE=1
K_GENPATCHES_VER="$(ver_cut 3)"
K_DEBLOB_AVAILABLE=0
K_WANT_GENPATCHES="base extras"

H_SUPPORTEDARCH="arm arm64"
K_FROM_GIT=1
#K_NOUSENAME=1
#K_NOUSEPR=1

inherit kernel-2 linux-info
detect_version
detect_arch

MY_PV="1.${PV#*_p}"

DESCRIPTION="Raspberry Pi kernel sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="
	https://github.com/raspberrypi/linux/archive/${MY_PV}.tar.gz -> ${P}.tar.gz
	${GENPATCHES_URI}
"
RESTRICT=mirror

KEYWORDS="arm arm64"
IUSE="+64bit rpi0 rpi02 rpi1 rpi2 rpi3 rpi4 rpi400 rpi-cm rpi-cm2 rpi-cm3 rpi-cm4 rpi-cm4s"
REQUIRED_USE="
	|| ( rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s )
	64bit? ( || ( rpi02 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s ) )
"

PATCHES=( "${FILESDIR}/${PN}-6.1.21-gentoo-kconfig.patch" )

UNIPATCH_EXCLUDE="
	10*
	15*
	1700
	2000
	29*
	3000
	4567"

S="${WORKDIR}/linux-${MY_PV}"

pkg_setup() {
	local kernel='' config='' version='' i=''

	ewarn ""
	ewarn "${PN} is *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the raspberrypi developers directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn ""

	# arm64: bcm2711_defconfig bcmrpi3_defconfig
	# arm:	 bcm2711_defconfig bcm2709_defconfig bcm2835_defconfig bcmrpi_defconfig
	#
	# See https://www.raspberrypi.org/documentation/linux/kernel/building.md

	for i in "${IUSE}"; do
		case "${i}" in
			rpi*) version+="+${i}" ;;
		esac
	done

	if use 64bit; then
		kernel='kernel8'
		if use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
			config='bcm2711_defconfig'
		elif use rpi02 || use rpi3 || use rpi-cm3; then
			config='bcmrpi3_defconfig'
		else
			ewarn "Unknown 64-bit architecture - configuring kernel with 'defconfig' only"
		fi
	else
		if use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
			kernel='kernel7l'
			config='bcm2711_defconfig'
		elif use rpi2 || use rpi-cm2 || use rpi3 || use rpi-cm3 || use rpi02; then
			kernel='kernel7'
			config='bcm2709_defconfig'
		elif use rpi0 || use rpi1 || use rpi-cm; then
			kernel='kernel'
			config='bcmrpi_defconfig'
		else
			ewarn "Unknown 32-bit architecture - configuring kernel with 'defconfig' only"
		fi
	fi

	if [[ -n "${config:-}" ]]; then
		export KERNEL="${kernel}"
		export K_DEFCONFIG="${config}"
		export EXTRAVERSION="${version}"

		kernel-2_pkg_setup
	fi
}

universal_unpack() {
	unpack "${P}.tar.gz"

	# remove all backup files
	find . -iname "*~" -exec rm {} \; 2>/dev/null
}

src_prepare() {
	default
	kernel-2_src_prepare
}

src_install() {
	# e.g. linux-raspberrypi-kernel_1.20200601-1 -> linux-4.19.118_p20200601-raspberrypi-r1
	dodir /usr/src
	if [[ "${PR}" != 'r0' ]]; then
		mv "${S}" "${ED}/usr/src/linux-${PV%_p*}-raspberrypi-${PR}"
	else
		mv "${S}" "${ED}/usr/src/linux-${PV%_p*}-raspberrypi"
	fi
}

pkg_postinst() {
	kernel-2_pkg_postinst
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
