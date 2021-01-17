# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools eutils flag-o-matic ltprune

DESCRIPTION="A Portable Open Source UPnP Development Kit"
HOMEPAGE="http://pupnp.sourceforge.net/"
SRC_URI="mirror://sourceforge/pupnp/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ppc ppc64 sparc x86 ~amd64-linux"
IUSE="+client debug doc examples ipv6 +server static-libs +tools +webserver"
REQUIRED_USE="!server? ( !webserver )"

DOCS="NEWS README ChangeLog"

PATCHES=(
	"${FILESDIR}"/${PN}-1.6.19-docs-install.patch
	"${FILESDIR}"/${PN}-1.6.21-cflags.patch
	"${FILESDIR}"/${P}-suse.patch
)

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
		$(use_enable debug) \
		$(use_enable ipv6) \
		$(use_enable server device) \
		$(use_enable static-libs static) \
		$(use_enable tools) \
		$(use_enable webserver) \
		$(use_with doc documentation "${EPREFIX}/usr/share/doc/${PF}")
}

src_install() {
	default
	use client && use server && use examples && dobin upnp/sample/.libs/tv_{combo,ctrlpt,device}
	use static-libs || prune_libtool_files
}
