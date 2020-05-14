# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs

DESCRIPTION="MiniUPnP IGD Daemon"
HOMEPAGE="http://miniupnp.free.fr/"
SRC_URI="http://miniupnp.free.fr/files/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="igd2 ipv6 +leasefile nftables pcp-peer portinuse strict"

RDEPEND="
	dev-libs/gmp:0=
	sys-apps/util-linux:=
	dev-libs/openssl:0=
	!nftables? (
		>=net-firewall/iptables-1.4.6:0=[ipv6?]
		net-libs/libnfnetlink:=
		net-libs/libmnl:=
	)
	nftables? (
		net-firewall/nftables
		net-libs/libnftnl:=
		net-libs/libmnl:=
	)"
DEPEND="${RDEPEND}
	sys-apps/lsb-release"

src_prepare() {
	default

	# Prevent overriding CFLAGS.
	sed -i -e '/^CFLAGS =/d' Makefile.linux_nft || die

	mv "Makefile.linux$(usex nftables _nft '')" Makefile || die

	sed -i \
		-e '/V6SOCKETS_ARE_V6ONLY/s:/usr/sbin/sysctl:sysctl:' \
		   genconfig.sh ||

	# Prevent gzipping manpage.
	sed -i -e '/gzip/d' Makefile || die
}

src_configure() {
	local -a opts
	opts=(
		--vendorcfg
		$(usex igd2 '--igd2' '')
		$(usex ipv6 '--ipv6' '')
		$(usex leasefile '--leasefile' '')
		$(usex portinuse '--portinuse' '')
		$(usex pcp-peer '--pcp-peer' '')
		$(usex strict '--strict' '')
	)

	CONFIG_OPTIONS="${opts[*]}" emake config.h
}

src_compile() {
	# By default, it builds a bunch of unittests that are missing wrapper
	# scripts in the tarball
	emake CC="$(tc-getCC)" STRIP=true miniupnpd
}

src_install() {
	emake PREFIX="${ED}" STRIP=true install

	exeinto /etc/miniupnpd
	newexe "${FILESDIR}"/iptables_init.sh-1.12 iptables_init.sh
	newexe "${FILESDIR}"/iptables_removeall.sh-1.11 iptables_removeall.sh
	newexe "${FILESDIR}"/ip6tables_init.sh-1.3 ip6tables_init.sh
	newexe "${FILESDIR}"/ip6tables_removeall.sh-1.2 ip6tables_removeall.sh
	insinto /etc/miniupnpd
	newins "${FILESDIR}"/miniupnpd_functions.sh-1.3 functions.sh
	rm "${ED}"/etc/miniupnpd/miniupnpd_functions.sh

	local confd_seds=()
	if use nftables; then
		confd_seds+=( -e 's/^iptables_scripts=/#&/' )
	else
		confd_seds+=( -e 's/^nftables_scripts=/#&/' )
	fi
	if ! use ipv6 || use nftables; then
		confd_seds+=( -e 's/^ip6tables_scripts=/#&/' )
	fi

	newinitd "${FILESDIR}"/${PN}-init.d-r2 ${PN}
	newconfd - ${PN} < <(sed "${confd_seds[@]}" \
		"${FILESDIR}"/${PN}-conf.d-r2 || die)
}

pkg_postinst() {
	elog "Please correct the external interface in the top of the two"
	elog "scripts in /etc/miniupnpd and edit the config file in there too"
}
