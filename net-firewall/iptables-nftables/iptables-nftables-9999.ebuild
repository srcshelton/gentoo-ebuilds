# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4
inherit autotools git-2

#REPO="${PN}"
REPO="iptables"
#BRANCH="master"
BRANCH="nft-compat"

DESCRIPTION="Add nftables rules using {ip,ip6}tables syntax"
HOMEPAGE="http://www.netfilter.org/projects/nftables/"
EGIT_REPO_URI="git://git.netfilter.org/${REPO}.git"
EGIT_MASTER="${BRANCH}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~ppc ~ppc64 x86"
#IUSE=""

#RDEPEND=""
#DEPEND="${RDEPEND}"
DEPEND="net-libs/libpcap"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf \
		--enable-libipq \
		--enable-bpf-compiler \
		--enable-nfsynproxy \
		--enable-devel
}

src_install() {
	default

	prune_libtool_files --all
}
