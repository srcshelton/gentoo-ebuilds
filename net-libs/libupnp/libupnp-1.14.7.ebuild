# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools flag-o-matic

MY_PN="pupnp"

DESCRIPTION="A Portable Open Source UPnP Development Kit" # forked in 2008 from upstream libupnp-1.6.6
HOMEPAGE="http://pupnp.sourceforge.net/"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/archive/release-${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0/17"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ppc ppc64 sparc x86 ~amd64-linux"
IUSE="blocking-tcp +client debug examples ipv6 +reuseaddr +server static-libs +tools +webserver"
REQUIRED_USE="!server? ( !webserver )"

# bug 733750
RESTRICT="test"

DOCS="ChangeLog"

S="${WORKDIR}/${MY_PN}-release-${PV}"

src_prepare() {
	default

	# fix tests
	chmod +x ixml/test/test_document.sh || die

	eautoreconf
}

src_configure() {
	use x86-fbsd &&	append-flags -O1
	# w/o docdir to avoid sandbox violations
	econf \
		$(use_enable client) \
		$(use_enable blocking-tcp blocking-tcp-connections) \
		$(use_enable debug) \
		$(use_enable ipv6) \
		$(use_enable reuseaddr) \
		$(use_enable server device) \
		$(use_enable static-libs static) \
		$(use_enable examples samples) \
		$(use_enable tools) \
		$(use_enable webserver)
	# Unspecified default-on options: ssdp, optssdp, soap, gena, scriptsupport
	# Unused default-off options: unspecified_server, open_ssl, postwrite
}

src_install() {
	default

	if use client && use server && use examples; then
		dobin upnp/sample/.libs/tv_{combo,ctrlpt,device}-$(ver_cut 1-2) || die
	fi

	if ! use static-libs ; then
		find "${D}" -name '*.la' -delete || die
	fi
}
