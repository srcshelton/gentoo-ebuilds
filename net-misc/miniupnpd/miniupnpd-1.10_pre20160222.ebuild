# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 061fa32c24ec85a2229bcd27b1f1a8d90d0ba5b2 $

EAPI=6

inherit eutils toolchain-funcs versionator flag-o-matic

MY_PV=$(get_version_component_range 3)
MY_PV=1.9.${MY_PV#pre}
MY_P="${PN}-${MY_PV}"

DESCRIPTION="MiniUPnP IGD Daemon"
HOMEPAGE="http://miniupnp.free.fr/"
SRC_URI="http://miniupnp.free.fr/files/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="igd2 ipv6 +leasefile -nftables pcp-peer portinuse strict"

RDEPEND="|| ( >=net-firewall/iptables-1.4.6:0=[ipv6?] net-firewall/iptables-nftables )
	net-libs/libnfnetlink:=
	net-libs/libmnl:=
	dev-libs/gmp:0=
	sys-apps/util-linux
	dev-libs/openssl:0="
DEPEND="${RDEPEND}
	sys-apps/lsb-release"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}/${PN}-1.10_pre20160222-build.patch"
)

pkg_setup() {
	if use nftables; then
		eerror "Sorry, but this version does not yet support features"
		eerror "that you requested:  nftables"
		eerror "Please mask ${PF} for now and check back later:"
		eerror " # echo '=${CATEGORY}/${PF}' >> /etc/portage/package.mask"
		die "This version of MiniUPnP does not yet have all previous functionality enabled"
	fi
}

src_prepare() {
	default
	if use nftables; then
		mv Makefile.linux_nft Makefile || die
	else
		mv Makefile.linux Makefile || die
	fi
	sed -i \
		-e '/V6SOCKETS_ARE_V6ONLY/s:/usr/sbin/sysctl:sysctl:' \
		   genconfig.sh ||
	die "genconfig.sh fix failed"
}

src_configure() {
	local -a opts
	opts=(
		--vendorcfg
		$(use igd2 && printf -- '--igd2\n')
		$(use ipv6 && printf -- '--ipv6\n')
		$(use leasefile && printf -- '--leasefile\n')
		$(use portinuse && printf -- '--portinuse\n')
		$(use pcp-peer && printf -- '--pcp-peer\n')
		$(use strict && printf -- '--strict\n')
	)

	emake CONFIG_OPTIONS="${opts[*]}" config.h
}

src_compile() {
	# By default, it builds a bunch of unittests that are missing wrapper
	# scripts in the tarball
	emake CC="$(tc-getCC)" \
		STRIP=true \
		LDLIBS_IPV6="$(use ipv6 && printf -- '-lip6tc')" \
		miniupnpd
}

src_install() {
	emake PREFIX="${ED}" STRIP=true install

	exeinto /etc/miniupnpd
	newexe "${FILESDIR}"/iptables_init.sh-r1 iptables_init.sh
	newexe "${FILESDIR}"/iptables_removeall.sh-r1 iptables_removeall.sh
	doexe "${FILESDIR}"/ip6tables_init.sh
	doexe "${FILESDIR}"/ip6tables_removeall.sh

	newinitd "${FILESDIR}"/${PN}-init.d-r1 ${PN}
	newconfd "${FILESDIR}"/${PN}-conf.d-r1 ${PN}
}

pkg_postinst() {
	elog "Please correct the external interface in the top of the two"
	elog "scripts in /etc/miniupnpd and edit the config file in there too"
}
