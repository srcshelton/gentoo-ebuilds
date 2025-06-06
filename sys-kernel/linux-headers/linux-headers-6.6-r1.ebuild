# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ETYPE="headers"
H_SUPPORTEDARCH="alpha amd64 arc arm arm64 csky hexagon hppa ia64 loong m68k microblaze mips nios2 openrisc ppc ppc64 riscv s390 sh sparc x86 xtensa"
inherit kernel-2
detect_version

PATCH_PV=${PV} # to ease testing new versions against not existing patches
PATCH_VER="1"
PATCH_DEV="sam"
SRC_URI="
	${KERNEL_URI}
	${PATCH_VER:+https://dev.gentoo.org/~${PATCH_DEV}/distfiles/sys-kernel/linux-headers/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}
"
S="${WORKDIR}/linux-${PV}"

KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl
"
RDEPEND="
	!sys-kernel/raspberrypi-headers
	!sys-kernel/rockchip-headers
"

src_unpack() {
	# Avoid kernel-2_src_unpack
	default
}

src_prepare() {
	local PATCHES=()
	[[ -n ${PATCH_VER} ]] && PATCHES+=( "${WORKDIR}"/${PATCH_PV} )
	PATCHES+=( "${FILESDIR}"/${PN}-sparc-move-struct-termio-to-asm-termios.h.patch )

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
