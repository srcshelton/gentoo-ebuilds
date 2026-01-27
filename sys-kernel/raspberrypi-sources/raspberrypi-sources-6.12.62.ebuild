# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="68"
#K_BASE_VER="${PV}"

CKV="${PV%_p*}"

#K_DEFCONFIG="bcmrpi_defconfig" # Set below...
K_SECURITY_UNSUPPORTED=1

#EXTRAVERSION="-${PN}/-*" # Set below...
#K_NODRYRUN=1  # Fail early rather than trying -p0 to -p5, seems to fix unipatch()!
#K_NOSETEXTRAVERSION=1
#K_NOUSENAME=1
#K_NOUSEPR=1

# Hide 'experimental' USE flag
#K_EXP_GENPATCHES_NOUSE=1
K_DEBLOB_AVAILABLE=0

H_SUPPORTEDARCH="arm arm64"

DEBIAN_PATCH="pios%2f1%25${PV}-1+rpt1.tar.gz"

inherit kernel-2 linux-info
detect_version
detect_arch

#ECLASS_DEBUG_OUTPUT="on"

DESCRIPTION="Raspberry Pi kernel sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="
	https://github.com/RPi-Distro/linux-packaging/archive/refs/tags/${DEBIAN_PATCH}
	${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}
"
RESTRICT=mirror

KEYWORDS="arm arm64"
IUSE="+64bit experimental rpi0 rpi02 rpi1 rpi2 rpi3 rpi4 rpi400 rpi5 rpi500 rpi-cm rpi-cm2 rpi-cm3 rpi-cm4 rpi-cm4s rpi-cm5"
REQUIRED_USE="
	|| ( rpi0 rpi02 rpi1 rpi-cm rpi2 rpi-cm2 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi500 rpi-cm5 )
	64bit? ( || ( rpi02 rpi3 rpi-cm3 rpi4 rpi400 rpi-cm4 rpi-cm4s rpi5 rpi500 rpi-cm5 ) )
"

PATCHES=(
	"${WORKDIR}/linux-packaging-pios-1-${PV}-1-rpt1/debian/patches/rpi/rpi.patch"
)

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

	# Patched configuration definitions:
	#   arch/arm/configs/bcm2709_defconfig
	#   arch/arm/configs/bcm2711_defconfig
	#   arch/arm/configs/bcmrpi_defconfig

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

src_unpack() {
	kernel-2_src_unpack

	cd "${WORKDIR}" || die "chdir() to '${WORKDIR}' failed: ${?}"
	unpack "${DEBIAN_PATCH}"
}


src_prepare() {
	default
	kernel-2_src_prepare
}

src_install() {
	# e.g. linux-raspberrypi-kernel_1.20200601-1 -> linux-4.19.118-raspberrypi-r1
	dodir /usr/src
	if [[ "${PR:-"r0"}" != 'r0' ]]; then
		mv "${S}" "${ED}/usr/src/linux-${CKV}-raspberrypi-${PR}"
	else
		mv "${S}" "${ED}/usr/src/linux-${CKV}-raspberrypi"
	fi
}

pkg_postinst() {
	kernel-2_pkg_postinst

	if use symlink; then
		if [[ "${PR:-"r0"}" != 'r0' ]]; then
			ln -snf "linux-${CKV}-raspberrypi-${PR}" "${EROOT}"/usr/src/linux || die
		else
			ln -snf "linux-${CKV}-raspberrypi" "${EROOT}"/usr/src/linux || die
		fi
	fi
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
