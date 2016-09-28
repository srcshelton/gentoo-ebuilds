# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: cb7eeef2520df429a8c7a11cbd2dada16b5741f6 $

EAPI=5

inherit eutils flag-o-matic

DESCRIPTION="Displays various tables of DNS traffic on your network"
HOMEPAGE="http://dnstop.measurement-factory.com/"
SRC_URI="http://dnstop.measurement-factory.com/src/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~x86"
IUSE="ipv6"

RDEPEND="sys-libs/ncurses:0
	!ipv6? ( net-libs/libpcap )
	ipv6? ( || ( <net-libs/libpcap-1.8.0[ipv6] >=net-libs/libpcap-1.8.0 ) )"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch_user
}

src_configure() {
	if has_version sys-libs/ncurses:0[tinfo] ; then
		append-libs -ltinfo	#bug 595068
	fi
	econf \
		$(use_enable ipv6)
}

src_install() {
	dobin dnstop
	doman dnstop.8
	dodoc CHANGES
}
