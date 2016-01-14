# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 07e1e0a78e254c1f102b19277988f55005ca9a77 $

EAPI=5

inherit eutils multilib toolchain-funcs

DESCRIPTION="A Library for Large Linear Classification"
HOMEPAGE="http://www.csie.ntu.edu.tw/~cjlin/liblinear/ https://github.com/cjlin1/liblinear"
SRC_URI="https://github.com/cjlin1/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0/3"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ~ppc ppc64 ~s390 ~sh sparc x86"
IUSE="blas"

RDEPEND="
	blas? ( virtual/blas )
"
DEPEND="
	${RDEPEND}
	blas? ( virtual/pkgconfig )
"

src_prepare() {
	# Contains broken symlinks to some guy's home directory...
	rm -rf matlab
	rm -rf windows

	sed -i \
		-e '/^AR/s|=|?=|g' \
		-e '/^RANLIB/s|=|?=|g' \
		-e '/^CFLAGS/d;/^CXXFLAGS/d' \
		blas/Makefile || die

	epatch "${FILESDIR}"/${PN}-210-Makefile.patch || die

	sed -i \
		-e 's|make|$(MAKE)|g' \
		-e '/$(LIBS)/s|$(CFLAGS)|& $(LDFLAGS)|g' \
		-e '/^CFLAGS/d;/^CXXFLAGS/d' \
		-e 's|$${SHARED_LIB_FLAG}|& $(LDFLAGS)|g' \
		Makefile || die
	if use blas; then
		sed -i -e 's:blas/blas.a::g' Makefile || die
	fi
}

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)" \
		CFLAGS="${CFLAGS} -fPIC" \
		CXXFLAGS="${CXXFLAGS} -fPIC" \
		AR="$(tc-getAR) rcv" \
		RANLIB="$(tc-getRANLIB)" \
		LIBS="$(usex blas "$( $(tc-getPKG_CONFIG) --libs blas )" blas/blas.a)" \
		lib all
}

src_install() {
	dolib ${PN}$(get_libname 3)
	dosym ${PN}$(get_libname 3) /usr/$(get_libdir)/${PN}$(get_libname)

	newbin predict ${PN}-predict
	newbin train ${PN}-train

	doheader linear.h

	dodoc README
}
