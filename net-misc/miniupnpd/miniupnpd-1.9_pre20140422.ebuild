# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/miniupnpd/miniupnpd-1.9_pre20140422.ebuild,v 1.1 2014/05/10 09:25:26 gurligebis Exp $

EAPI="5"

inherit eutils toolchain-funcs

MY_PV=1.8.20140422
MY_P="${PN}-${MY_PV}"

DESCRIPTION="MiniUPnP IGD Daemon"
HOMEPAGE="http://miniupnp.free.fr/"
SRC_URI="http://miniupnp.free.fr/files/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

RDEPEND="|| ( >=net-firewall/iptables-1.4.6 net-firewall/iptables-nftables )
	net-libs/libnfnetlink"
DEPEND="${RDEPEND}
	sys-apps/util-linux
	sys-apps/lsb-release"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.9-cleanup.patch
	epatch "${FILESDIR}"/${PN}-1.9-build.patch
	epatch "${FILESDIR}"/${PN}-1.9-sysctl.patch
	mv Makefile.linux Makefile || die
}

src_configure() {
	tc-export CC
	export STRIP=true

	emake config.h
	sed -i -r \
		-e '/#define ENABLE_LEASEFILE/s:(/[*]|[*]/)::g' \
		config.h || die
}

src_compile() {
	# By default, it builds a bunch of unittests we don't run.
	emake CC="$(tc-getCC)" miniupnpd
}

src_install() {
	emake install PREFIX="${ED}"

	newinitd "${FILESDIR}"/${PN}-init.d ${PN}
	newconfd "${FILESDIR}"/${PN}-conf.d ${PN}
}

pkg_postinst() {
	elog "Please correct the external interface in the top of the two"
	elog "scripts in /etc/miniupnpd and edit the config file in there too"
}
