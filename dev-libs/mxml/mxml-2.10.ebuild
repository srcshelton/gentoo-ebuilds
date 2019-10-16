# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools

MY_P="${P/mini-xml/mxml}"

DESCRIPTION="Small XML parsing library to read XML and XML-like data files"
HOMEPAGE="https://www.msweet.org/mxml/"
SRC_URI="https://github.com/michaelrsweet/mxml/releases/download/release-${PV}/mxml-${PV}.tar.gz"

LICENSE="Mini-XML"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ppc ~ppc64 ~sparc x86"
IUSE="threads sep-usr static-libs"

RESTRICT="mirror"

DEPEND="virtual/pkgconfig"
RDEPEND=""

S="${WORKDIR}/${MY_P}"

src_prepare() {
	default
	sed -e "s:755 -s:755:" \
		-e "/^TARGETS/s: testmxml::" \
		-e 's:$(DSO) $(DSOFLAGS) -o libmxml.so.1.5 $(LIBOBJS):$(DSO) $(DSOFLAGS) $(LDFLAGS) -o libmxml.so.1.5 $(LIBOBJS):' \
			-i Makefile.in || die
	sed -i -e 's:OPTIM="-Os -g":OPTIM="":' configure.ac || die
	rm configure || die
	#eautoreconf
	eautoconf
}

src_configure() {
	econf \
		--enable-shared \
		--libdir="/usr/$(get_libdir)" \
		--with-docdir="/usr/share/doc/${PF}/html" \
		$(use_enable threads)
}

src_compile() {
	emake libmxml.so.1.5 mxmldoc doc/mxml.man
}

src_install() {
	emake DSTROOT="${ED}" install

	if ! use static-libs; then
		rm "${ED}"/usr/$(get_libdir)/libmxml.a || die
	fi

	if use sep-usr; then
		# need the libs in /
		gen_usr_ldscript -a mxml
	fi

	dodoc ANNOUNCEMENT CHANGES README
	rm "${ED}/usr/share/doc/${PF}/html/"{CHANGES,COPYING,README} || die
}

src_test() {
	emake testmxml
}
