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
# Official designations: pi1, pi2, pi3, pi3+, pi4, pi400, cm4, pi0, pi0w, pi02
IUSE="-rpi0 -rpi1 +rpi2 rpi3 rpi4"
REQUIRED_USE="^^ ( rpi0 rpi1 rpi2 rpi3 rpi4 )"

PATCHES=("${FILESDIR}"/${PN}-$(ver_cut 1-2).32-gentoo-kconfig.patch)

UNIPATCH_EXCLUDE="
	10*
	15*
	2000
	29*
	3000
	4567"

S="${WORKDIR}/linux-${MY_PV}"

pkg_setup() {
	ewarn ""
	ewarn "${PN} is *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the raspberrypi developers directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn ""

	# arm64: bcm2711_defconfig bcmrpi3_defconfig
	# arm:   bcm2709_defconfig bcm2711_defconfig bcm2835_defconfig bcmrpi_defconfig
	#
	# bcm2835: rpi0, rpi1
	# bcm2709: 
	# bcm2711: rpi4
	#
	# See https://www.raspberrypi.org/documentation/linux/kernel/building.md

	if use rpi4; then
		export K_DEFCONFIG="bcm2711_defconfig"
		export EXTRAVERSION="-rpi4/-*"
	elif use rpi3; then
		export K_DEFCONFIG="bcm2709_defconfig"
		export EXTRAVERSION="-rpi3/-*"
	elif use rpi2; then
		export K_DEFCONFIG="bcm2709_defconfig"
		export EXTRAVERSION="-rpi2/-*"
	elif use rpi1; then
		export K_DEFCONFIG="bcmrpi_defconfig"
		export EXTRAVERSION="-rpi1/-*"
	elif use rpi0; then
		export K_DEFCONFIG="bcmrpi_defconfig"
		export EXTRAVERSION="-rpi0/-*"
	else
		die 'One of USE="rpi0", USE="rpi1", USE="rpi2", USE="rpi3", or USE="rpi4" must be selected'
	fi

	kernel-2_pkg_setup
}

universal_unpack() {
	unpack "${P}.tar.gz"

	# remove all backup files
	find . -iname "*~" -exec rm {} \; 2>/dev/null
}

#src_unpack() {
#	default
#
#	unpack_set_extraversion
#
#	# remove all backup files
#	find . -iname "*~" -exec rm {} \; 2>/dev/null
#}

src_prepare() {
	default
	kernel-2_src_prepare

	## kernel-2_src_prepare doesn't apply PATCHES()
	#handle_genpatches --set-unipatch-list
	#[[ -n ${UNIPATCH_LIST} || -n ${UNIPATCH_LIST_DEFAULT} || -n ${UNIPATCH_LIST_GENPATCHES} ]] && \
	#	unipatch "${UNIPATCH_LIST_DEFAULT} ${UNIPATCH_LIST_GENPATCHES} ${UNIPATCH_LIST}"
	#
	#unpack_fix_install_path
	#
	## Setup xmakeopts and cd into sourcetree.
	#env_setup_xmakeopts
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
