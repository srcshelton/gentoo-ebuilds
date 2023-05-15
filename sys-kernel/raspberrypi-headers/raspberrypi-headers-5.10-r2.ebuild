# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MY_PV="1.20220308"
ETYPE="headers"
H_SUPPORTEDARCH="arm arm64"
inherit kernel-2
detect_version

PATCH_PV=${PV} # to ease testing new versions against not existing patches
PATCH_VER="1"
SRC_URI="https://github.com/raspberrypi/linux/archive/${MY_PV}.tar.gz
	${PATCH_VER:+mirror://gentoo/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}
	${PATCH_VER:+https://dev.gentoo.org/~sam/distfiles/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}
"
S="${WORKDIR}/linux-${MY_PV}"

KEYWORDS="arm arm64"

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl"
RDEPEND="
	!sys-kernel/linux-headers"

[[ -n ${PATCH_VER} ]] && PATCHES=( "${WORKDIR}"/${PATCH_PV} )

src_unpack() {
	# avoid kernel-2_src_unpack
	default
}

src_prepare() {
	# TODO: May need forward porting to newer versions
	use elibc_musl && PATCHES+=(
		"${FILESDIR}"/${PN}-5.10-Use-stddefs.h-instead-of-compiler.h.patch
	)

	# avoid kernel-2_src_prepare
	default
}

src_test() {
	emake headers_check "${KERNEL_MAKEOPTS[@]}"
}

src_install() {
	kernel-2_src_install

	find "${ED}" \( -name '.install' -o -name '*.cmd' \) -delete || die
	# delete empty directories
	find "${ED}" -empty -type d -delete || die
}
