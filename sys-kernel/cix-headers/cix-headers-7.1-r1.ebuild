# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ETYPE="headers"
H_SUPPORTEDARCH="arm arm64"
inherit kernel-2
detect_version

PATCH_PV=${PV}
PATCH_VER="1"
SRC_URI="
	${KERNEL_URI}
	${PATCH_VER:+https://distfiles.gentoo.org/pub/proj/toolchain/linux-headers/gentoo-headers-${PATCH_PV}-${PATCH_VER}.tar.xz}
"
S="${WORKDIR}/linux-${PV}"

KEYWORDS="~arm ~arm64"

BDEPEND="
	app-arch/xz-utils
	dev-lang/perl
"
RDEPEND="
	!sys-kernel/linux-headers
"

src_unpack() {
	# Avoid kernel-2_src_unpack.
	default
}

src_prepare() {
	local PATCHES=()

	[[ -n ${PATCH_VER} ]] && PATCHES+=( "${WORKDIR}"/${PATCH_PV} )
	PATCHES+=( "${FILESDIR}"/7.1-cix-sof-topology-tokens.patch )
	use elibc_musl && PATCHES+=(
		"${FILESDIR}"/5.15-remove-inclusion-sysinfo.h.patch
	)

	# Avoid kernel-2_src_prepare.
	default
}

src_install() {
	local ddir

	ddir=$(kernel_header_destdir)
	env_setup_kernel_makeopts
	emake headers "${KERNEL_MAKEOPTS[@]}"

	dodir "${ddir}"
	cp -a --no-preserve=ownership usr/include/. "${ED}${ddir}/" || die
	find "${ED}${ddir}" -type f ! -name '*.h' -delete || die
	rm -rf "${ED}${ddir}/scsi" || die

	find "${ED}" \( -name '.install' -o -name '*.cmd' \) -delete || die
	find "${ED}" -empty -type d -delete || die
}
