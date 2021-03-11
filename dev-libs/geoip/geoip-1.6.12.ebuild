# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="GeoIP Legacy C API"
HOMEPAGE="https://github.com/maxmind/geoip-api-c"
SRC_URI="https://github.com/maxmind/${PN}-api-c/archive/v${PV}.tar.gz -> ${P}.tar.gz"

# GPL-2 for md5.c - part of libGeoIPUpdate, MaxMind for GeoLite Country db
LICENSE="LGPL-2.1 GPL-2 MaxMind2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~mips ppc ppc64 s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="static-libs tools"
RESTRICT="test"

RDEPEND="tools? ( net-misc/geoipupdate )"

S="${WORKDIR}/${PN}-api-c-${PV}"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	econf $(use_enable static-libs static)
}

src_install() {
	default

	dodoc AUTHORS ChangeLog NEWS.md README*

	find "${ED}" -name '*.la' -delete || die

	keepdir /usr/share/GeoIP
}

pkg_postinst() {
	ewarn "WARNING: Databases are no longer installed by this ebuild."
	elog "Don't forget to run 'geoipupdate' (from net-misc/geoipupdate)"
	elog "to populate ${EROOT}/usr/share/GeoIP/ with geo-located IP"
	elog "address databases."
}
