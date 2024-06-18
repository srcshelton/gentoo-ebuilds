# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module linux-info systemd

DESCRIPTION="Standard networking plugins for container networking"
HOMEPAGE="https://github.com/containernetworking/plugins"
SRC_URI="https://github.com/containernetworking/plugins/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv"
IUSE="hardened systemd"

BDEPEND="sys-apps/sed"
RDEPEND="net-firewall/iptables"

CONFIG_CHECK="
	~BRIDGE_VLAN_FILTERING
	~NETFILTER_XT_MATCH_COMMENT
	~NETFILTER_XT_MATCH_MULTIPORT
"

S="${WORKDIR}/plugins-${PV}"

src_prepare() {
	default

	sed -ri \
		-e 's|([="])/run|\1/var/run|' \
		plugins/ipam/dhcp/main.go \
		plugins/ipam/dhcp/systemd/cni-dhcp.socket \
		plugins/meta/tuning/tuning.go \
		vendor/github.com/godbus/dbus/v5/conn_other.go \
		vendor/github.com/vishvananda/netns/netns_linux.go \
	|| die "'/run' replacement failed: ${?}"
}

src_compile() {
	CGO_LDFLAGS="$(usex hardened '-fno-PIC ' '')" ./build_linux.sh || die
}

src_install() {
	exeinto /opt/cni/bin
	doexe bin/*
	use systemd && systemd_dounit plugins/ipam/dhcp/systemd/cni-dhcp.{service,socket}
	newinitd "${FILESDIR}"/cni-dhcp.initd cni-dhcp
}
