# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KV_MINOR="89"
EGIT_COMMIT="fd1a9d06cef85f16a4dcb16061a9128437e235f4"
ETYPE="headers"
H_SUPPORTEDARCH="arm arm64"
inherit kernel-2
detect_version

PATCH_PV=${PV} # to ease testing new versions against not existing patches
PATCH_VER="1"
PATCH_DEV="sam"
SRC_URI="
	https://github.com/radxa/kernel/archive/${EGIT_COMMIT}.tar.gz -> cix-sources-${PV}.${KV_MINOR}.tar.gz
	${PATCH_VER:+"https://dev.gentoo.org/~${PATCH_DEV}/distfiles/sys-kernel/linux-headers/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz"}"
S="${WORKDIR}/kernel-${EGIT_COMMIT}"

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
		"${FILESDIR}"/5.15-remove-inclusion-sysinfo.h.patch
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
