# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 0a795a42185b5d063b378228f164f8f160d66de1 $

EAPI=5
inherit autotools eutils multilib

DESCRIPTION="A swiss knife tool for ARP"
HOMEPAGE="http://sid.rstack.org/arp-sk/"
SRC_URI="http://sid.rstack.org/arp-sk/files/${P}.tgz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"

DEPEND=">=net-libs/libnet-1.1"
RDEPEND="${DEPEND}"

DOCS=( ARP AUTHORS CONTRIB ChangeLog README TODO )

src_prepare() {
	epatch "${FILESDIR}"/${P}-libnet1_2.patch
	sed -i configure.in -e 's|AM_CONFIG_HEADER|AC_CONFIG_HEADERS|g' || die

	# Fix hard-coding of /usr/lib/ for libnet...
	sed -i configure.in -e "s|/lib |/$(get_libdir) |g" || die

	rm missing || die "removing of 'missing' script failed"
	epatch_user

	eautoreconf
}

src_install() {
	default

	# We don't need libcompat as it has a potential to clash with other packages.
	rm -fr "${D}"/usr/$(get_libdir)
}
