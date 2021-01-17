# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

#CKV='5.4.51'
CKV="${PV%_p*}"
ETYPE=sources
#K_NOUSENAME=1
#K_NOUSEPR=1
K_FROM_GIT=1
K_SECURITY_UNSUPPORTED=1
H_SUPPORTEDARCH="arm arm64"
inherit kernel-2
detect_version
detect_arch

MY_PV="1.${PV#*_p}-${PR#r}"

DESCRIPTION="Raspberry Pi kernel sources"
HOMEPAGE="https://github.com/raspberrypi/linux"
SRC_URI="https://github.com/raspberrypi/linux/archive/raspberrypi-kernel_${MY_PV}.tar.gz"
RESTRICT=mirror

KEYWORDS="arm arm64"
IUSE="-rpi0 -rpi1 +rpi2 rpi3 rpi4"
REQUIRED_USE="^^ ( rpi0 rpi1 rpi2 rpi3 rpi4 )"

S="${WORKDIR}/linux-raspberrypi-kernel_${MY_PV}"

pkg_setup() {
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
}

src_unpack() {
	default

	unpack_set_extraversion
}

#src_compile() {
#	emake mrproper defconfig prepare
#}

src_install() {
	# e.g. linux-raspberrypi-kernel_1.20200601-1 -> linux-4.19.118_p20200601-raspberrypi-r1
	dodir /usr/src
	mv "${S}" "${ED}/usr/src/linux-${PV%_p*}-raspberrypi-${PR}"
}
