# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/antoniodiazdiaz.asc
inherit edo flag-o-matic toolchain-funcs unpacker verify-sig

MY_P="${PN}-${PV/_/-}"

DESCRIPTION="Your basic line editor"
HOMEPAGE="https://www.gnu.org/software/ed/"
SRC_URI="
	mirror://gnu/ed/${MY_P}.tar.lz
	https://download.savannah.gnu.org/releases/ed/${MY_P}.tar.lz
	verify-sig? (
		mirror://gnu/ed/${MY_P}.tar.lz.sig
		https://download.savannah.gnu.org/releases/ed/${MY_P}.tar.lz.sig
	)
"
S="${WORKDIR}"/${MY_P}

LICENSE="GPL-2+"
SLOT="0"
if [[ ${PV} != *_rc* ]] ; then
	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
fi

BDEPEND="
	sys-apps/texinfo
	$(unpacker_src_uri_depends)
	verify-sig? ( sec-keys/openpgp-keys-antoniodiazdiaz )
"

src_unpack() {
	use verify-sig && verify-sig_verify_detached "${DISTDIR}"/${MY_P}.tar.lz{,.sig}
	unpacker "${DISTDIR}"/${MY_P}.tar.lz
}

src_configure() {
	if use amd64 || use x86 || use amd64-linux || use x86-linux; then
		# With -z,max-page-size=0x200000 set (for x86_64), tiny binaries bloat
		# to 6.1MB each :o
		#
		filter-ldflags *-z,max-page-size=*
	fi

	edo ./configure \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		CPPFLAGS="${CPPFLAGS}" \
		--bindir="${EPREFIX}/bin" \
		--prefix="${EPREFIX}/usr"
}
