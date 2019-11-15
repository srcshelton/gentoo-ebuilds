# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit autotools eutils multilib versionator

DESCRIPTION="Open Source Deep Packet Inspection Software Toolkit"
HOMEPAGE="https://www.ntop.org/"
SRC_URI="https://github.com/ntop/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="static-libs"

DEPEND="dev-libs/json-c:=
	net-libs/libpcap"
RDEPEND="${DEPEND}"

src_prepare() {
	# We love well-maintained source repos...
	[[ -e lib ]] && rm lib

	# Let's not sink to this level of craziness...
	#./autogen.sh

	# ... but instead try to sort it out ourselves:
	NDPI_MAJOR="$(get_version_component_range 1)"
	NDPI_MINOR="$(get_version_component_range 2)"
	NDPI_PATCH="$(get_version_component_range 3)"
	NDPI_VERSION_SHORT="${PV}"

	sed -e "s/@NDPI_MAJOR@/${NDPI_MAJOR}/g" \
		-e "s/@NDPI_MINOR@/${NDPI_MINOR}/g" \
		-e "s/@NDPI_PATCH@/${NDPI_PATCH}/g" \
		-e "s/@NDPI_VERSION_SHORT@/${NDPI_VERSION_SHORT}/g" \
		configure.seed > configure.ac ||
	die "Version substitution failed: ${?}"

	mv "${S}/src/lib/third_party/include/libcache.h" "${S}/src/include"
	epatch "${FILESDIR}/${P}-libcache-include.patch"

	default

	# Now let's let Portage do its thing ...
	eautoreconf
}

src_install() {
	default
	if ! use static-libs; then
		rm "${D}"/usr/$(get_libdir)/lib${PN,,}.a || die
	fi
	prune_libtool_files
}
