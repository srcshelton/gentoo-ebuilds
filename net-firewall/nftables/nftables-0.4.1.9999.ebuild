# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools git-r3 linux-info

DESCRIPTION="nftables aims to replace the existing {ip,ip6,arp,eb}tables framework"
HOMEPAGE="http://netfilter.org/projects/nftables/"
EGIT_REPO_URI="git://git.netfilter.org/${PN}.git"
EGIT_BRANCH="next-4.1"

LICENSE="GPL-2"
SLOT="0"
#KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86"
KEYWORDS=""
IUSE="debug +doc pdf +readline"

RDEPEND=">=net-libs/libmnl-1.0.3
	>=net-libs/libnftnl-1.0.2
	dev-libs/gmp
	readline? ( sys-libs/readline )"
DEPEND="${RDEPEND}
	doc? ( >=app-text/docbook2X-0.8.8-r4 )
	pdf? ( app-text/dblatex app-text/docbook-sgml-utils[tetex] )
	sys-devel/bison
	sys-devel/flex"

pkg_setup() {
	if kernel_is ge 3 13; then
		CONFIG_CHECK="~NF_TABLES"
		linux-info_pkg_setup
	else
		eerror "This package requires kernel version 3.13 or newer to work properly."
	fi
}

src_prepare() {
	epatch_user
	eautoreconf
}

src_configure() {
	econf \
		--sbindir="${EPREFIX}"/sbin \
		$(use_enable debug) \
		$(use_with readline cli)
}

src_install() {
	default

	prune_libtool_files --all

	if ! use doc; then
		newman "${FILESDIR}"/man-pages/"${PN}"-0.4.1-nftables.8 nft.8
	fi
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	newinitd "${FILESDIR}"/${PN}.init ${PN}
	keepdir /var/lib/nftables
}
