# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KV_MINOR="0"
EGIT_COMMIT="375956b48579a046bdcc325fc8c19dc685005ffa"
ETYPE="headers"
H_SUPPORTEDARCH="arm arm64"
inherit kernel-2
detect_version

PATCH_PV="${PV}" # to ease testing new versions against not existing patches
PATCH_VER="1"
PATCH_DEV="sam"
SRC_URI="https://github.com/Joshua-Riek/linux-rockchip/archive/${EGIT_COMMIT}.tar.gz -> linux-rockchip-${PV}.${KV_MINOR}.tar.gz
	${PATCH_VER:+https://dev.gentoo.org/~${PATCH_DEV}/distfiles/sys-kernel/linux-headers/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}"
S="${WORKDIR}/linux-rockchip-${EGIT_COMMIT}"

KEYWORDS="arm arm64"

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl"
RDEPEND="
	!sys-kernel/linux-headers"

[[ -n ${PATCH_VER} ]] && PATCHES=( "${WORKDIR}/${PATCH_PV}" )

src_unpack() {
	# Avoid kernel-2_src_unpack
	default
}

src_prepare() {
	# TODO: May need forward porting to newer versions
	use elibc_musl && PATCHES+=(
		"${FILESDIR}"/${PN}-5.10-Use-stddefs.h-instead-of-compiler.h.patch
		"${FILESDIR}"/${PN}-5.15-remove-inclusion-sysinfo.h.patch
	)

	# Avoid kernel-2_src_prepare
	default
}

src_install() {
	kernel-2_src_install

	find "${ED}" \( -name '.install' -o -name '*.cmd' \) -delete || die

	# Delete empty directories
	find "${ED}" -empty -type d -delete || die
}
