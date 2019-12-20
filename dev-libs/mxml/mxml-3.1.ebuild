# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools usr-ldscript

DESCRIPTION="A small XML parsing library that you can use to read XML data files or strings"
HOMEPAGE="
	https://github.com/michaelrsweet/mxml
	https://www.msweet.org/mxml/
"
SRC_URI="https://github.com/michaelrsweet/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Mini-XML"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ppc ~ppc64 ~sparc x86"
IUSE="doc threads static-libs"

BDEPEND="virtual/pkgconfig"

src_prepare() {
	default

	# Respect users CFLAGS
	sed -i -e 's:OPTIM="-Os -g":OPTIM="":' configure.ac || die

	# Don't run always tests
	# Enable verbose compiling
	sed -e '/ALLTARGETS/s/testmxml//g' -e '/.SILENT:/d' -i Makefile.in || die

	# Build only static-libs, when requested by user, also build docs without static-libs in that case
	if ! use static-libs; then
		local mysedopts=(
			-e '/^install:/s/install-libmxml.a//g'
			-e '/^mxml.xml:/s/-static//g'
			-e '/^mxml.epub:/s/-static//g'
			-e '/^valgrind/s/-static//g'
			-e 's/.\/mxmldoc-static/LD_LIBRARY_PATH="." .\/mxmldoc/g'
		)
		sed "${mysedopts[@]}" -i Makefile.in || die
	fi

	sed -e "s:755 -s:755:" \
		-e 's:$(DSO) $(DSOFLAGS) -o libmxml.so.1.5 $(LIBOBJS):$(DSO) $(DSOFLAGS) $(LDFLAGS) -o libmxml.so.1.5 $(LIBOBJS):' \
			-i Makefile.in || die

	rm configure || die
	eautoconf
}

src_configure() {
	local myeconfargs=(
		--enable-shared
		--libdir="/usr/$(get_libdir)"
		--with-docdir="/usr/share/doc/${PF}"
		$(use_enable threads)
	)

	econf "${myeconfargs[@]}"
}

src_install() {
	emake DSTROOT="${ED}" install

	# need the libs in /
	gen_usr_ldscript -a mxml

	dodoc CHANGES.md README.md
	rm "${ED%/}/usr/share/doc/${PF}/"{CHANGES,LICENSE,NOTICE,README,mxml.epub} || die
	use doc || rm -r "${ED%/}/usr/share/doc/${PF}"
}

src_test() {
	emake testmxml
}
