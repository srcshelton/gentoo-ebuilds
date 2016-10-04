# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 47ad4c8ac66909f0f0fa37266bcc2e5ddd2999ce $

EAPI=6
PYTHON_COMPAT=( python{2_7,3_3,3_4,3_5} )

inherit fcaps linux-info python-r1 systemd user

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://github.com/firehol/${PN}.git"
	inherit git-r3 autotools
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="https://firehol.org/download/${PN}/releases/v${PV}/${P}.tar.xz"
	KEYWORDS="amd64 x86"
	RESTRICT="mirror"
fi

GIT_COMMIT=""
case "${PV}" in
	1.2.0)
		GIT_COMMIT="bb4aa949f5ac825253d8adc6070661299abc1c3b"
		;;
esac

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/firehol/netdata https://my-netdata.io/"

LICENSE="GPL-3+ MIT BSD"
SLOT="0"
IUSE="+compression mysql nfacct nodejs +python systemd"
REQUIRED_USE="
	mysql? ( python )
	python? ( ${PYTHON_REQUIRED_USE} )"
# Most unconditional dependencies are for plugins.d/charts.d.plugin:
RDEPEND="
	>=app-shells/bash-4:0
	net-misc/curl
	net-misc/wget
	virtual/awk
	net-libs/libmnl
	|| ( net-analyzer/netcat6 net-analyzer/netcat )
	net-analyzer/tcpdump
	net-analyzer/traceroute
	compression? ( sys-libs/zlib )
	python? (
		${PYTHON_DEPS}
		dev-python/pyyaml[${PYTHON_USEDEP}]
		mysql? (
			|| ( dev-python/mysqlclient[${PYTHON_USEDEP}] dev-python/mysql-python[${PYTHON_USEDEP}] )
		)
	)
	nfacct? (
		net-firewall/nfacct
		net-libs/libmnl
	)
	nodejs? (
		net-libs/nodejs
	)"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

# Check for Kernel-Samepage-Merging (CONFIG_KSM)
CONFIG_CHECK="
	~KSM
"

: ${NETDATA_USER:=${PN}}
: ${NETDATA_GROUP:=${PN}}

FILECAPS=(
	'cap_dac_read_search,cap_sys_ptrace+ep' 'usr/libexec/netdata/plugins.d/apps.plugin'
)

pkg_setup() {
	linux-info_pkg_setup

	enewgroup "${NETDATA_GROUP}"
	enewuser "${NETDATA_USER}" -1 -1 / "${NETDATA_USER}"
}

src_prepare() {
	default
	[[ ${PV} == "9999" ]] && eautoreconf
}

src_configure() {
	econf \
		--localstatedir="/var" \
		--with-user="${NETDATA_USER}" \
		$(use_enable nfacct plugin-nfacct) \
		$(use_with compression zlib)
}

src_install() {
	default

	cat >> "${T}"/"${PN}"-sysctl <<- EOF
	kernel.mm.ksm.run = 1
	kernel.mm.ksm.sleep_millisecs = 1000
	EOF

	dodoc "${T}"/"${PN}"-sysctl
	newdoc "${ED}"/usr/libexec/netdata/charts.d/README.md charts.md
	newdoc "${ED}"/usr/libexec/netdata/plugins.d/README.md plugins.md

	if ! [[ -s "${ED}"/usr/share/netdata/web/version.txt && "$( < "${ED}"/usr/share/netdata/web/version.txt )" != '0' ]]; then
		if [[ -n "${GIT_COMMIT:-}" ]]; then
			einfo "Replacing packaged version '$( < "${ED}"/usr/share/netdata/web/version.txt )' with version '${GIT_COMMIT}'"
			echo "${GIT_COMMIT}" > "${ED}"/usr/share/netdata/web/version.txt
		else
			ewarn "Removing packaged version file '/usr/share/netdata/web/version.txt' with version '$( < "${ED}"/usr/share/netdata/web/version.txt )'"
			rm "${ED}"/usr/share/netdata/web/version.txt
		fi
	fi

	use nodejs || rm -r "${ED}"/usr/libexec/netdata/node.d

	rm -r "${ED}"/usr/share/netdata/web/old
	rm 2>/dev/null \
		"${ED}"/var/log/netdata/.keep "${ED}"/var/cache/netdata/.keep \
		"${ED}"/usr/libexec/netdata/charts.d/README.md \
		"${ED}"/usr/libexec/netdata/node.d/README.md \
		"${ED}"/usr/libexec/netdata/plugins.d/README.md
	rmdir -p "${ED}"/var/log/netdata "${ED}"/var/cache/netdata 2>/dev/null

	fowners -R "${NETDATA_USER}":"${NETDATA_GROUP}" /usr/share/"${PN}" || die

	#newinitd system/netdata-openrc "${PN}"
	newinitd "${FILESDIR}"/"${PN}".initd "${PN}"
	use systemd && systemd_dounit system/netdata.service
}

pkg_postinst() {
	if [[ -e "/sys/kernel/mm/ksm/run" ]]; then
		if [[ "$( < /sys/kernel/mm/ksm/run )" != '1' ]]; then
			elog "INFORMATION:"
			echo
			elog "I see you have kernel memory de-duper (called Kernel Same-page Merging,"
			elog "or KSM) available, but it is not currently enabled."
			echo
			elog "To enable it run:"
			echo
			elog "echo 1 >/sys/kernel/mm/ksm/run"
			elog "echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs"
			echo
			elog "If you enable it, you will save 20-60% of netdata memory."
			echo
			elog "You may copy /usr/share/doc/${PF}/${PN}-sysctl to"
			elog "/etc/sysctl.d/${PN}.conf in order to activate this change"
			elog "automatically upon reboot."
		fi
	else
		elog "INFORMATION:"
		echo
		elog "I see you do not have kernel memory de-duper (called Kernel Same-page"
		elog "Merging, or KSM) available."
		echo
		elog "To enable it, you need a kernel built with CONFIG_KSM=y"
		echo
		elog "If you can have it, you will save 20-60% of netdata memory."
	fi

}
