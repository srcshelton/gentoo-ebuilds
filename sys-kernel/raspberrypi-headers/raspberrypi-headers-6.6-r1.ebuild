# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KV_MINOR="51"
MY_PV="20241008"
#EGIT_COMMIT="6f16847710cc0502450788b9f12f0a14d3429668"
ETYPE="headers"
H_SUPPORTEDARCH="arm arm64"
inherit kernel-2
detect_version

PATCH_PV=${PV} # to ease testing new versions against not existing patches
PATCH_VER="1"
PATCH_DEV="sam"
SRC_URI="https://github.com/raspberrypi/linux/archive/${EGIT_COMMIT:-"${PY_PV}"}.tar.gz -> raspberrypi-sources-${PV}.${KV_MINOR}_p${MY_PV#*_}.tar.gz
	${PATCH_VER:+https://dev.gentoo.org/~${PATCH_DEV}/distfiles/sys-kernel/linux-headers/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}"
S="${WORKDIR}/linux-${EGIT_COMMIT:-"stable_${MY_PV}"}"

KEYWORDS="arm arm64"

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl
"
RDEPEND="
	!sys-kernel/linux-headers
"

src_unpack() {
	# Avoid kernel-2_src_unpack
	default
}

src_prepare() {
	local -a PATCHES=()
	[[ -n ${PATCH_VER} ]] && PATCHES+=( "${WORKDIR}"/${PATCH_PV} )
	# Fails to apply to RPi sources...
	#PATCHES+=( "${FILESDIR}"/${PN}-sparc-move-struct-termio-to-asm-termios.h.patch )

	# TODO: May need forward porting to newer versions
	use elibc_musl && PATCHES+=(
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
