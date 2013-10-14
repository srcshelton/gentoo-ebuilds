# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit git-r3 autotools

DESCRIPTION="iPhone USB Ethernet Driver for Linux pairing helper"
HOMEPAGE="http://giagio.com/wiki/moin.cgi/iPhoneEthernetDriver"
EGIT_REPO_URI="git://github.com/dgiagio/ipheth.git/"
EGIT_PROJECT="ipheth"

EGIT_PATCHES="${FILESDIR}/Makefile.patch"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="app-pda/libimobiledevice"
DEPEND="${RDEPEND}"

src_compile() {
	emake -C ipheth-pair || die
}

src_install() {
	emake -C ipheth-pair DESTDIR="${D}" install || die
}

pkg_postinst() {
	udevadm control --reload-rules && udevadm trigger
}
