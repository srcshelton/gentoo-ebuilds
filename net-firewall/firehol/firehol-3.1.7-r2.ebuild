# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info systemd

DESCRIPTION="iptables firewall generator"
HOMEPAGE="https://firehol.org/ https://github.com/firehol/firehol"
SRC_URI="https://github.com/firehol/firehol/releases/download/v${PV}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
IUSE="doc +firehol +fireqos ipset ipv6 link-balancer systemd"
KEYWORDS="amd64 arm ~arm64 ~ppc ~x86"

# Set the dependency versions to aid cross-compiling. Keep them at their
# minimums as the configure script merely checks whether they are sufficient.
MY_BASH_VERSION=4.0
MY_IPRANGE_VERSION=1.0.2

RDEPEND="
	>=app-shells/bash-${MY_BASH_VERSION}:0
	net-analyzer/traceroute
	net-firewall/iptables
	>=net-misc/iprange-${MY_IPRANGE_VERSION}:0
	net-misc/iputils[ipv6(+)?]
	sys-apps/iproute2[-minimal,ipv6(+)?]
	sys-apps/kmod[tools]
	firehol? (
		net-firewall/nfacct
		virtual/pager
	)
	fireqos? (
		net-analyzer/tcpdump
	)
	ipset? (
		app-arch/gzip
		net-firewall/ipset
	)
	link-balancer? (
		app-misc/jq
		app-misc/screen
		net-misc/whois
	)
"
BDEPEND="${RDEPEND}
	|| ( sys-apps/util-linux[logger] app-admin/sysklogd[logger] )
	app-arch/gzip
	virtual/logger
"

pkg_setup() {
	local CONFIG_CHECK=" \
		~IP_NF_FILTER \
		~IP_NF_IPTABLES \
		~IP_NF_MANGLE \
		~IP_NF_TARGET_MASQUERADE
		~IP_NF_TARGET_REDIRECT \
		~IP_NF_TARGET_REJECT \
		~NETFILTER_XT_CONNMARK \
		~NETFILTER_XT_MATCH_HELPER \
		~NETFILTER_XT_MATCH_LIMIT \
		~NETFILTER_XT_MATCH_OWNER \
		~NETFILTER_XT_MATCH_STATE \
		~NF_CONNTRACK \
		~NF_CONNTRACK_MARK \
		~NF_NAT \
		~NF_NAT_FTP \
		~NF_NAT_IRC \
	"

	if kernel_is -lt 4 19; then
		CONFIG_CHECK+=" ~NF_CONNTRACK_IPV4"
	fi

	linux-info_pkg_setup
}

src_configure() {
	if use fireqos; then
		export ac_cv_path_TCPDUMP="/usr/sbin/tcpdump"
	fi

	# This erroneously checks for BASH_VERSION_PATH rather than BASH_VERSION.
	BASH_VERSION_PATH=${MY_BASH_VERSION} \
	IPRANGE_VERSION=${MY_IPRANGE_VERSION} \
	econf \
		--disable-vnetbuild \
		$(use_enable doc) \
		$(use_enable firehol) \
		$(use_enable firehol firehol-wizard) \
		$(use_enable fireqos) \
		$(use_enable ipset update-ipsets) \
		$(use_enable ipv6) \
		$(use_enable link-balancer) \
		--runstatedir="/var/run"
}

src_install() {
	default

	if use firehol; then
		newconfd "${FILESDIR}"/firehol.confd firehol
		newinitd "${FILESDIR}"/firehol.initd firehol
		use systemd && systemd_dounit contrib/firehol.service
	fi
	if use fireqos; then
		newconfd "${FILESDIR}"/fireqos.confd fireqos
		newinitd "${FILESDIR}"/fireqos.initd fireqos
		use systemd && systemd_dounit contrib/fireqos.service
	fi
}
