# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit autotools eutils multilib versionator

DESCRIPTION="Open Source Deep Packet Inspection Software Toolkit"
HOMEPAGE="http://www.ntop.org/"
SRC_URI="https://github.com/ntop/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="hyperscan static-libs"

DEPEND="dev-libs/json-c:=
	net-libs/libpcap
	hyperscan? ( dev-libs/hyperscan )"
RDEPEND="${DEPEND}"

src_prepare() {
	# Let's not sink to this level of craziness...
	#./autogen.sh

	# ... but instead try to sort it out ourselves:
	NDPI_MAJOR="$(get_version_component_range 1)"
	NDPI_MINOR="$(get_version_component_range 2)"
	NDPI_PATCH="$(get_version_component_range 3)"
	NDPI_VERSION_SHORT="${PV}"

	sed -e "s/@NDPI_MAJOR@/${NDPI_MAJOR}/g" \
		-e "s/@NDPI_MINOR@/${NDPI_MINOR}/g" \
		-e "s/@NDPI_PATCH@/${NDPI_PATCH:-0}/g" \
		-e "s/@NDPI_VERSION_SHORT@/${NDPI_VERSION_SHORT}/g" \
		configure.seed > configure.ac ||
	die "Version substitution failed: ${?}"

	epatch "${FILESDIR}/${P}-fix-pkgconfigdir.patch"
	epatch "${FILESDIR}/${P}-relative-sym.patch"

	default

	# Now let's let Portage do its thing ...
	eautoreconf

	sed -e 's/#define PACKAGE/#define NDPI_PACKAGE/g ; s/#define VERSION/#define NDPI_VERSION/g' \
		-i configure \
	|| die "configure update failed: ${?}"

	# configure script reacts to the presence of 'hyperscan', ignoring '--with'
	# or '--without' :(
	#econf $(use_with hyperscan)
	econf $(usex hyperscan '--with-hyperscan' '' )
}

src_install() {
	# More breakage :(
	#
	# These files exist after configure is run, but are overwritten during the
	# build process, and so this is the next opportunity we have to alter them
	# in a persistent way.
	sed -e '/pkgconfig/s|libdata|share|' \
		-i Makefile \
	|| die "Makefile update failed: ${?}"

	if [[ "$(get_libdir)" != 'lib' ]]; then
		sed -e "/^libdir/s|lib$|$(get_libdir)|" \
			-e "/ln -Ffs/s| \$(DESTDIR)\$(libdir)/\$(NDPI_LIB_SHARED) \$(DESTDIR)| \$(NDPI_LIB_SHARED) ${ED%/}/|g" \
			-i src/lib/Makefile \
		|| die "libdir correction failed: ${?}"
	fi
	default

	if ! use static-libs; then
		rm "${ED%/}"/usr/$(get_libdir)/lib${PN,,}.a || die
	fi
	prune_libtool_files
}
