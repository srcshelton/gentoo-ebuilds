# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4
inherit autotools git-2

DESCRIPTION="nftables aims to replace the existing {ip,ip6,arp,eb}tables framework"
HOMEPAGE="http://www.netfilter.org/projects/nftables/"
EGIT_REPO_URI="git://git.netfilter.org/${PN}.git"
EGIT_MASTER="master"

LICENSE="GPL-2"
SLOT="0"
#KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86"
KEYWORDS=""
IUSE="man pdf"

RDEPEND="
	dev-libs/gmp
	net-libs/libmnl
	net-libs/libnftnl
	sys-libs/readline"
DEPEND="${RDEPEND}
	sys-devel/bison
	sys-devel/flex
	man? ( app-text/docbook2X )
	pdf? ( app-text/docbook-sgml-utils[tetex] )"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf --disable-debug
}

src_install() {
	default

	prune_libtool_files --all
}
