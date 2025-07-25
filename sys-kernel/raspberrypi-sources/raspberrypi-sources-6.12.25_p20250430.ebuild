# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ETYPE="sources"
K_WANT_GENPATCHES="extras experimental"
K_GENPATCHES_VER="29"

CKV="${PV%_p*}"

#K_DEFCONFIG="bcmrpi_defconfig" # Set below...
K_SECURITY_UNSUPPORTED=1
#
#EXTRAVERSION="-${PN}/-*" # Set below...
K_NODRYRUN=1  # Fail early rather than trying -p0 to -p5, seems to fix unipatch()!
K_NOSETEXTRAVERSION=1
K_NOUSENAME=1
K_NOUSEPR=1

K_EXP_GENPATCHES_NOUSE=1
K_DEBLOB_AVAILABLE=0

H_SUPPORTEDARCH="arm arm64"
K_FROM_GIT=1

inherit kernel-2 linux-info
detect_version
detect_arch

#ECLASS_DEBUG_OUTPUT="on"

# This release is stable_20250428 in the 'linux' repo but 1.20250430 in the
# 'firmware' repo... why is keeping two repos in sync so hard for the
# Raspberry Pi Foundation?! :(
EGIT_COMMIT="3dd2c2c507c271d411fab2e82a2b3b7e0b6d3f16"
MY_PV="stable_${PV#*_p}"

DESCRIPTION="Raspberry Pi kernel sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="
	https://github.com/raspberrypi/linux/archive/${EGIT_COMMIT:-"${MY_PV}"}.tar.gz -> ${P}.tar.gz
	${GENPATCHES_URI}
"
RESTRICT=mirror

KEYWORDS="arm arm64"
IUSE="+64bit rpi0 rpi02 rpi1 rpi2 rpi3 rpi4 rpi400 rpi5 rpi500 rpi-cm rpi-cm2 rpi-cm3 rpi-cm4 rpi-cm4s rpi-cm5"
REQUIRED_USE="
	|| ( rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi500 rpi-cm5 )
	64bit? ( || ( rpi02 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi500 rpi-cm5 ) )
"

PATCHES=(
	"${FILESDIR}/${PN}-mmc-dma-Kconfig.patch"
	#"${FILESDIR}/${PN}-pcie-brcmstb.c.patch"
	#"${FILESDIR}/${PN}-6.1.21-gentoo-kconfig.patch"
)

if [[ -n "${EGIT_COMMIT}" ]]; then
	S="${WORKDIR}/linux-${CKV}"
else
	S="${WORKDIR}/linux-${MY_PV:-"${CKV}"}"
fi

pkg_setup() {
	local kernel='' config='' version='' i=''

	ewarn ""
	ewarn "${PN} is *not* supported by the Gentoo Kernel Project in any way."
	ewarn "If you need support, please contact the raspberrypi developers directly."
	ewarn "Do *not* open bugs in Gentoo's bugzilla unless you have issues with"
	ewarn "the ebuilds. Thank you."
	ewarn ""

	# arm64: bcm2712_defconfig bcm2711_defconfig bcmrpi3_defconfig
	# arm:	 bcm2712_defconfig bcm2711_defconfig bcm2709_defconfig bcm2835_defconfig bcmrpi_defconfig
	#
	# See https://www.raspberrypi.org/documentation/linux/kernel/building.md

	for i in "${IUSE}"; do
		case "${i}" in
			rpi*) version+="+${i}" ;;
		esac
	done

	if use 64bit; then
		kernel='kernel8'
		if use rpi5 || use rpi500 || use rpi-cm5; then
			config='bcm2712_defconfig'
		elif use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
			config='bcm2711_defconfig'
		elif use rpi3 || use rpi-cm3 || use rpi02; then
			config='bcmrpi3_defconfig'
		else
			ewarn "Unknown 64-bit architecture - configuring kernel with 'defconfig' only"
		fi
	else
		if use rpi5 || use rpi500 || use rpi-cm5; then
			kernel='kernel7l'
			config='bcm2712_defconfig'
		elif use rpi4 || use rpi400 || use rpi-cm4 || use rpi-cm4s; then
			kernel='kernel7l'
			config='bcm2711_defconfig'
		elif use rpi2 || use rpi-cm2 || use rpi3 || use rpi-cm3 || use rpi02; then
			kernel='kernel7'
			config='bcm2709_defconfig'
		elif use rpi1 || use rpi-cm || use rpi0; then
			kernel='kernel'
			config='bcmrpi_defconfig'
		else
			ewarn "Unknown 32-bit architecture - configuring kernel with 'defconfig' only"
		fi
	fi

	if [[ -n "${config:-}" ]]; then
		export KERNEL="${kernel}"
		export K_DEFCONFIG="${config}"
		#export EXTRAVERSION="_p${PV#*_p}${version:-}"
		export EXTRAVERSION="_p${PV#*_p}"

		kernel-2_pkg_setup
	fi
}

universal_unpack() {
	cd "${WORKDIR}" || die "chdir() to '${WORKDIR}' failed: ${?}"
	unpack "${P}.tar.gz"

	if [[ -n "${EGIT_COMMIT}" ]]; then
		mv "linux-${EGIT_COMMIT}" "linux-${KV_FULL}"
	fi
	cd "${S}" || die "chdir() to '${S}' failed: ${?}"

	# remove all backup files
	find . -iname "*~" -exec rm {} \; 2>/dev/null
}

src_unpack() {
	# We expect unipatch to fail :(
	$( kernel-2_src_unpack ) || :
}


src_prepare() {
	default
	kernel-2_src_prepare
}

src_install() {
	# e.g. linux-raspberrypi-kernel_1.20200601-1 -> linux-4.19.118-raspberrypi-r1
	dodir /usr/src
	if [[ "${PR}" != 'r0' ]]; then
		mv "${S}" "${ED}/usr/src/linux-${CKV}-raspberrypi-${PR}"
	else
		mv "${S}" "${ED}/usr/src/linux-${CKV}-raspberrypi"
	fi
}

pkg_postinst() {
	kernel-2_pkg_postinst

	if use symlink; then
		if [[ "${PR}" != 'r0' ]]; then
			ln -snf "linux-${CKV}-raspberrypi${PR}" "${EROOT}"/usr/src/linux || die
		else
			ln -snf "linux-${CKV}-raspberrypi" "${EROOT}"/usr/src/linux || die
		fi
	fi
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
