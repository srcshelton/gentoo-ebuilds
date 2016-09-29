# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 0f1d2d1acd128208f5c48ad378392b116b2c4d1f $

EAPI=5

inherit eutils

DESCRIPTION="Displays various tables of DNS traffic on your network"
HOMEPAGE="http://dnstop.measurement-factory.com/"
SRC_URI="http://dnstop.measurement-factory.com/src/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ~arm ~hppa ~ppc x86"
IUSE="ipv6"

RDEPEND="sys-libs/ncurses
	!ipv6? ( net-libs/libpcap )
	ipv6? ( || ( <net-libs/libpcap-1.8.0[ipv6] >=net-libs/libpcap-1.8.0 ) )"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch_user
}

src_configure() {
	econf \
		$(use_enable ipv6)
}

src_install() {
	dobin dnstop
	doman dnstop.8
	dodoc CHANGES
}
