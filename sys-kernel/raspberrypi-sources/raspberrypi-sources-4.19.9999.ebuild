# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

ETYPE=sources
K_SECURITY_UNSUPPORTED=1
inherit kernel-2
detect_version
detect_arch

inherit git-r3
IUSE="-rpi1 +rpi2 -rpi4"
REQUIRED_USE="^^ ( rpi1 rpi2 rpi4 )"

EGIT_REPO_URI="https://github.com/raspberrypi/linux.git -> raspberrypi-linux.git"
EGIT_BRANCH="rpi-$(ver_cut 1-2).y"
EGIT_CHECKOUT_DIR="${WORKDIR}/linux-${PV}-raspberrypi"
EGIT_CLONE_TYPE="shallow"

DESCRIPTION="Raspberry Pi kernel sources"
HOMEPAGE="https://github.com/raspberrypi/linux"

KEYWORDS=""

pkg_setup() {
	if use rpi4; then
		# For Raspberry Pi 4  and Compute Module 4
		#export KERNEL=kernel7l # 32bit
		#export KERNEL=kernel8  # 64bit
		export K_DEFCONFIG="bcm2711_defconfig"
		export EXTRAVERSION="-rpi4/-*"
	elif use rpi2; then
		# For Raspberry Pi 2, Pi 3, Pi 3+, and Compute Module 3
		#export KERNEL=kernel7
		export K_DEFCONFIG="bcm2709_defconfig"
		export EXTRAVERSION="-rpi/-*"
	elif use rpi1; then
		#export KERNEL=kernel
		# For Raspberry Pi 1, Pi Zero, Pi Zero W, and Compute Module
		export K_DEFCONFIG="bcmrpi_defconfig"
		export EXTRAVERSION="-rpi1/-*"
	fi
}

src_unpack() {
	git-r3_src_unpack
	unpack_set_extraversion
}
