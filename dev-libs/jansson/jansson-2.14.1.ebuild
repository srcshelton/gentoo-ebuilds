# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools usr-ldscript

DESCRIPTION="C library for encoding, decoding and manipulating JSON data"
HOMEPAGE="https://www.digip.org/jansson/"
SRC_URI="https://github.com/akheron/jansson/releases/download/v${PV}/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0/4"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-macos"
IUSE="doc static-libs"

BDEPEND="
	dev-build/autoconf-archive
	sys-devel/binutils
	doc? ( dev-python/sphinx )
"

PATCHES=(
	"${FILESDIR}"/jansson-2.14.1-default-symver-test.patch
)

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	econf $(use_enable static-libs static)
}

src_compile() {
	default

	if use doc ; then
		emake html
		HTML_DOCS=( doc/_build/html/. )
	fi
}

src_install() {
	default

	if use split-usr; then
		# need the libs in /
		gen_usr_ldscript -a jansson
	fi

	find "${ED}" -name '*.la' -delete || die
}
