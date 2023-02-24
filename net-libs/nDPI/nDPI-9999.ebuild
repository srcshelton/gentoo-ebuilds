# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools edo

DESCRIPTION="Open Source Deep Packet Inspection Software Toolkit"
HOMEPAGE="https://www.ntop.org/"
if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://github.com/ntop/${PN}"
	inherit git-r3
else
	SRC_URI="https://github.com/ntop/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="LGPL-3+"
SLOT="0/$(ver_cut 1)"

IUSE="hyperscan"

DEPEND="dev-libs/json-c:=
	dev-libs/libgcrypt:=
	dev-libs/libgpg-error
	net-libs/libpcap
	hyperscan? ( dev-libs/hyperscan )"
RDEPEND="${DEPEND}"

src_prepare() {
	default

	## Let's not sink to this level of craziness...
	##./autogen.sh
	#
	## ... but instead try to sort it out ourselves:
	##NDPI_MAJOR="$( grep -m 1 'NDPI_MAJOR' autogen.sh | cut -d'"' -f 2 )"
	##NDPI_MINOR="$( grep -m 1 'NDPI_MINOR' autogen.sh | cut -d'"' -f 2 )"
	##NDPI_PATCH="$( grep -m 1 'NDPI_PATCH' autogen.sh | cut -d'"' -f 2 )"
	#eval $(grep '^NDPI_MAJOR=' autogen.sh)
	#eval $(grep '^NDPI_MINOR=' autogen.sh)
	#eval $(grep '^NDPI_PATCH=' autogen.sh)
	#NDPI_VERSION_SHORT="${NDPI_MAJOR}.${NDPI_MINOR}.${NDPI_PATCH}"
	#
	#sed \
	#	-e "s/@NDPI_MAJOR@/${NDPI_MAJOR}/g" \
	#	-e "s/@NDPI_MINOR@/${NDPI_MINOR}/g" \
	#	-e "s/@NDPI_PATCH@/${NDPI_PATCH:-0}/g" \
	#	-e "s/@NDPI_VERSION_SHORT@/${NDPI_VERSION_SHORT}/g" \
	#	< configure.seed \
	#	> configure.ac || die "Version substitution failed: ${?}"

	sed -i \
		-e "s%^libdir\s*=\s*\${prefix}/lib\s*$%libdir     = \${prefix}/$(get_libdir)%" \
		src/lib/Makefile.in || die

	#default

	# Now let's let Portage do its thing ...
	eautoreconf

	## Taken from autogen.sh (bug #704074):
	#sed -i \
	#	-e "s/#define PACKAGE/#define NDPI_PACKAGE/g" \
	#	-e "s/#define VERSION/#define NDPI_VERSION/g" \
	#	configure || die
}

src_configure() {
	# configure script reacts to the presence of 'hyperscan', ignoring '--with'
	# or '--without' :(
	#econf $(use_with hyperscan)
	econf $(usex hyperscan '--with-hyperscan' '' )
}

src_configure() {
	# "local" here means "local to the system", and hence means
	# system copy, not the bundled one.
	econf --with-local-libgcrypt
}

src_test() {
	pushd tests || die

	edo ./do.sh
	edo ./do-unit.sh

	popd || die
}

src_install() {
	## More breakage :(
	##
	## These files exist after configure is run, but are overwritten during the
	## build process, and so this is the next opportunity we have to alter them
	## in a persistent way.
	#sed -e '/pkgconfig/s|libdata|share|' \
	#	-i Makefile \
	#|| die "Makefile update failed: ${?}"
	#
	##if [[ "$(get_libdir)" != 'lib' ]]; then
	##	sed -e "/^libdir/s|lib$|$(get_libdir)|" \
	##		-e "/ln -Ffs/s| \$(DESTDIR)\$(libdir)/\$(NDPI_LIB_SHARED) \$(DESTDIR)| \$(NDPI_LIB_SHARED) ${ED%/}/|g" \
	##		-i src/lib/Makefile \
	##	|| die "libdir correction failed: ${?}"
	##fi
	default

	rm "${ED%/}/usr/$(get_libdir)"/lib${PN,,}.a || die

	mv "${ED%/}"/usr/sbin/ndpi "${ED%/}"/usr/share/

	# Makefile logic is broken in 4.6, let's wait a bit given history and
	# go with hack for now.
	mv "${ED}/usr/$(get_libdir)/pkgconfig" "${ED}/usr/usr/$(get_libdir)/pkgconfig" || die
	mv "${ED}"/usr/usr/* "${ED}"/usr/ || die
	rm -rf "${ED}"/usr/usr || die
}
