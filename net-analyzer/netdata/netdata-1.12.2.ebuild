# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_7 )

inherit autotools fcaps linux-info python-r1 systemd user

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/netdata/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/netdata/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	RESTRICT="mirror"
fi

GIT_COMMIT=""
case "${PV}" in
	1.2.0)
		GIT_COMMIT="bb4aa949f5ac825253d8adc6070661299abc1c3b"
		;;
	1.3.0)
		GIT_COMMIT="b4591e87bd5bf5164eb55c90474bbb9f38f2dad4"
		;;
	1.4.0)
		GIT_COMMIT="3028b87ee19e8550df6b9decc49733d595e0bd6e"
		;;
	1.5.0)
		GIT_COMMIT="3bd41a09fccccbc6b095805556d3009b9ebf6213"
		;;
	1.6.0)
		GIT_COMMIT="f5fa346a188e906a8f2cce3c2cf32a88ce81c666"
		;;
	1.7.0)
		GIT_COMMIT="4016e2d9e3c2fcf5f6d59827bf5f81083d6645ba"
		;;
	1.8.0)
		GIT_COMMIT="89ed309252981ddd50f697fde4fe93019cb3e652"
		;;
	1.9.0)
		GIT_COMMIT="8e3e6627ccd97959d64bbb4df1f377a39c0e753f"
		;;
	1.10.0)
		GIT_COMMIT="c92349444f88427d8ddef2fb1ac6c4932cf6c8bb"
		;;
	1.11.0)
		GIT_COMMIT="2b16aab3955dea836a06f580c0e111396916d7ef"
		;;
	1.12.0)
		GIT_COMMIT="d1ebd8a057a45e6fdbc975fbcc4c8e8f9ffedb20"
		;;
	1.12.2)
		GIT_COMMIT="01eb819ff49cb918f157c183b7d50c3d925ddb04"
		;;
esac

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata https://my-netdata.io/"

LICENSE="GPL-3+ MIT BSD"
SLOT="0"
IUSE="caps +compression fping ipmi mysql nfacct nodejs postgres +python systemd tor cpu_flags_x86_sse2"
REQUIRED_USE="
	mysql? ( python )
	python? ( ${PYTHON_REQUIRED_USE} )
	tor? ( python )"

# Most unconditional dependencies are for plugins.d/charts.d.plugin:
RDEPEND="
	>=app-shells/bash-4:0
	|| (
		net-analyzer/openbsd-netcat
		net-analyzer/netcat6
		net-analyzer/netcat
	)
	net-analyzer/tcpdump
	net-analyzer/traceroute
	net-misc/curl
	net-misc/wget
	sys-apps/util-linux
	virtual/awk
	caps? ( sys-libs/libcap )
	compression? ( sys-libs/zlib )
	fping? ( >=net-analyzer/fping-4.0 )
	ipmi? ( sys-libs/freeipmi )
	nfacct? (
		net-firewall/nfacct
		net-libs/libmnl
	)
	nodejs? ( net-libs/nodejs )
	python? (
		${PYTHON_DEPS}
		dev-python/pyyaml[${PYTHON_USEDEP}]
		virtual/python-dnspython
		virtual/python-ipaddress
		mysql? (
			|| (
				dev-python/mysqlclient[${PYTHON_USEDEP}]
				dev-python/mysql-python[${PYTHON_USEDEP}]
			)
		)
		postgres? ( dev-python/psycopg:2[${PYTHON_USEDEP}] )
		tor? ( net-libs/stem[${PYTHON_USEDEP}] )
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

	eautoreconf
}

src_configure() {
	econf \
		--localstatedir="${EPREFIX}"/var \
		--with-user="${NETDATA_USER}" \
		$(use_enable nfacct plugin-nfacct) \
		$(use_enable ipmi plugin-freeipmi) \
		$(use_enable cpu_flags_x86_sse2 x86-sse) \
		$(use_with compression zlib)
}

src_install() {
	default

	# Remove unneeded .keep files
	find "${ED}" -name ".keep" -delete || die

	#newdoc "${ED}"/usr/libexec/netdata/charts.d/README.md charts.md
	#newdoc "${ED}"/usr/libexec/netdata/plugins.d/README.md plugins.md

	if ! [[ -s "${ED}"/usr/share/netdata/web/version.txt && "$( < "${ED}"/usr/share/netdata/web/version.txt )" != '0' ]]; then
		if [[ -n "${GIT_COMMIT:-}" ]]; then
			einfo "Replacing packaged version '$( < "${ED}"/usr/share/netdata/web/version.txt )' with version '${GIT_COMMIT}'"
			echo "${GIT_COMMIT}" > "${ED}"/usr/share/netdata/web/version.txt
		else
			ewarn "Removing packaged version file '/usr/share/netdata/web/version.txt' with version '$( < "${ED}"/usr/share/netdata/web/version.txt )'"
			rm "${ED}"/usr/share/netdata/web/version.txt
		fi
	fi

	if ! use nodejs; then
		rm -r "${ED}"/usr/libexec/netdata/node.d
		rm "${ED}"/usr/libexec/netdata/plugins.d/node.d.plugin
	fi

	rm -r "${ED}"/usr/share/netdata/web/old
	rm 2>/dev/null \
		"${ED}"/usr/libexec/netdata/charts.d/README.md \
		"${ED}"/usr/libexec/netdata/node.d/README.md \
		"${ED}"/usr/libexec/netdata/plugins.d/README.md
	rmdir -p "${ED}"/var/log/netdata "${ED}"/var/cache/netdata 2>/dev/null

	# Moved to init script
	#fowners -Rc ${NETDATA_USER}:${NETDATA_GROUP} /var/log/netdata
	#fowners -Rc ${NETDATA_USER}:${NETDATA_GROUP} /var/lib/netdata

	fowners -Rc root:"${NETDATA_GROUP}" /usr/share/netdata/web ||
		die "Failed settings owners: ${?}"

	insinto /etc/netdata
	doins system/netdata.conf

	#newinitd system/netdata-openrc "${PN}"
	newinitd "${FILESDIR}"/"${PN}.initd" "${PN}"
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

	if ! use prefix; then
		# This should be handled by FILECAPS, but wasn't... plus we want a
		# fallback.
		setcap cap_dac_read_search,cap_sys_ptrace+ep "${EROOT%/}"/usr/libexec/netdata/plugins.d/apps.plugin ||
		chmod 4755 "${EROOT%/}"/usr/libexec/netdata/plugins.d/apps.plugin ||
		eerror "Cannot set capabilities or SUID on '/usr/libexec/netdata/plugins.d/apps.plugin'"
	fi
}
