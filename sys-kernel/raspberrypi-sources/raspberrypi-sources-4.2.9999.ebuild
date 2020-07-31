# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 9e7224829a8d48a2eb2b79333374ac033ab9532e $

EAPI=5

ETYPE=sources
K_SECURITY_UNSUPPORTED=1
inherit kernel-2
detect_version
detect_arch

inherit git-r3 versionator
IUSE="-rpi1 +rpi2"
EGIT_REPO_URI=https://github.com/raspberrypi/linux.git
EGIT_BRANCH="rpi-$(get_version_component_range 1-2).y"
EGIT_CLONE_TYPE="shallow"

DESCRIPTION="Raspberry Pi kernel sources"
HOMEPAGE="https://github.com/raspberrypi/linux"

KEYWORDS="-*"

pkg_setup() {
	if use rpi1 && use rpi2; then
		eerror "It is not possible to specify USE=\"rpi1 rpi2\" - please choose one"
		eerror "architecture only."
		die "Cannot build for RPi and RPi2 simultaneously"
	fi

	if use rpi2; then
		export K_DEFCONFIG="bcm2709_defconfig"
		export EXTRAVERSION="-rpi2/-*"
	elif use rpi1; then
		export K_DEFCONFIG="bcmrpi_defconfig"
		export EXTRAVERSION="-rpi/-*"
	else
		die "One of USE=\"rpi1\" or USE=\"rpi2\" must be selected."
	fi
}

src_unpack() {
	default

	unpack_set_extraversion
}
