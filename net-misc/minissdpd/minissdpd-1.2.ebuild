# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/minissdpd/Attic/minissdpd-1.2.ebuild,v 1.2 2012/12/25 21:03:11 blueness dead $

EAPI="4"
inherit eutils toolchain-funcs

DESCRIPTION="MiniSSDP Daemon"
SRC_URI="http://miniupnp.free.fr/files/${P}.tar.gz"
HOMEPAGE="http://miniupnp.free.fr/"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="sys-apps/net-tools
	|| ( net-misc/miniupnpd net-libs/miniupnpc )"

src_prepare() {
	epatch "${FILESDIR}/${P}-respect-CC.patch"
	epatch "${FILESDIR}/${PN}-1.1.20120410-remove-initd.patch"
}

src_compile() {
	emake CC="$(tc-getCC)"
}

src_install () {
	einstall PREFIX="${D}"
	newinitd "${FILESDIR}/${PN}.initd" ${PN}
	newconfd "${FILESDIR}/${PN}.confd" ${PN}
	dodoc Changelog.txt README
	doman minissdpd.1
}
