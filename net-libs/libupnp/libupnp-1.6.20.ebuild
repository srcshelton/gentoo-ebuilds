# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: c589c65c4df22e0d30c1427bd0f658d2eafe0a19 $

EAPI=5

inherit autotools eutils flag-o-matic

DESCRIPTION="A Portable Open Source UPnP Development Kit"
HOMEPAGE="http://pupnp.sourceforge.net/"
SRC_URI="mirror://sourceforge/pupnp/${P}.tar.bz2"
RESTRICT="mirror"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux"
IUSE="+client debug doc examples ipv6 static-libs +tools +server +webserver"
REQUIRED_USE="!server? ( !webserver )"

DOCS="NEWS README ChangeLog"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.8.0-POST.patch \
		"${FILESDIR}"/${P}-suse.patch \
		"${FILESDIR}"/${PN}-1.6.19-docs-install.patch

	# fix tests
	chmod +x ixml/test/test_document.sh || die

	eautoreconf
}

src_configure() {
	use x86-fbsd &&	append-flags -O1
	# w/o docdir to avoid sandbox violations
	econf \
		$(use_enable client) \
		$(use_enable debug) \
		$(use_enable ipv6) \
		$(use_enable server device) \
		$(use_enable static-libs static) \
		$(use_enable tools) \
		$(use_enable webserver) \
		$(use_with doc documentation "${EPREFIX}/usr/share/doc/${PF}")
}

src_install () {
	default
	use client && use server && use examples && dobin upnp/sample/.libs/tv_{combo,ctrlpt,device}
	use static-libs || prune_libtool_files
}

pkg_postinst() {
	ewarn "Please remember to run revdep-rebuild when upgrading"
	ewarn "from libupnp 1.4.x to libupnp 1.6.x , so packages"
	ewarn "are linked with the new library."
	echo ""
	ewarn "The revdep-rebuild script is part of the"
	ewarn "app-portage/gentoolkit package."
}
