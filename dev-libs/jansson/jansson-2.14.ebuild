# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs usr-ldscript multilib-minimal

DESCRIPTION="C library for encoding, decoding and manipulating JSON data"
HOMEPAGE="https://www.digip.org/jansson/"
SRC_URI="https://github.com/akheron/jansson/releases/download/v${PV}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0/4"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-macos"
IUSE="doc static-libs"

BDEPEND="doc? ( dev-python/sphinx )
	>=dev-build/automake-1.16"

PATCHES=( "${FILESDIR}/${P}-test-symbols.patch" )

multilib_src_configure() {
	tc-ld-force-bfd

	ECONF_SOURCE="${S}" econf $(use_enable static-libs static)
}

multilib_src_compile() {
	default

	if multilib_is_native_abi && use doc ; then
		emake html
		HTML_DOCS=( "${BUILD_DIR}"/doc/_build/html/. )
	fi
}

multilib_src_install() {
	default

	if use split-usr && multilib_is_native_abi; then
		# need the libs in /
		gen_usr_ldscript -a jansson
	fi

	find "${D}" -name '*.la' -delete || die
}
