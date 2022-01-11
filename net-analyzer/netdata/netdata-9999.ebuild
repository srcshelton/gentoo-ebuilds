# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python{3_8,3_9,3_10} )

inherit autotools fcaps flag-o-matic linux-info python-single-r1 systemd toolchain-funcs

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/netdata/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/netdata/${PN}/releases/download/${PV}/${PN}-${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${PV}"
	KEYWORDS="~amd64 ~ppc64 ~x86"
	RESTRICT="mirror"
fi

GIT_COMMIT=""
case "${PV}" in
	1.2.0)	GIT_COMMIT="bb4aa949f5ac825253d8adc6070661299abc1c3b" ;;
	1.3.0)	GIT_COMMIT="b4591e87bd5bf5164eb55c90474bbb9f38f2dad4" ;;
	1.4.0)	GIT_COMMIT="3028b87ee19e8550df6b9decc49733d595e0bd6e" ;;
	1.5.0)	GIT_COMMIT="3bd41a09fccccbc6b095805556d3009b9ebf6213" ;;
	1.6.0)	GIT_COMMIT="f5fa346a188e906a8f2cce3c2cf32a88ce81c666" ;;
	1.7.0)	GIT_COMMIT="4016e2d9e3c2fcf5f6d59827bf5f81083d6645ba" ;;
	1.8.0)	GIT_COMMIT="89ed309252981ddd50f697fde4fe93019cb3e652" ;;
	1.9.0)	GIT_COMMIT="8e3e6627ccd97959d64bbb4df1f377a39c0e753f" ;;
	1.10.0)	GIT_COMMIT="c92349444f88427d8ddef2fb1ac6c4932cf6c8bb" ;;
	1.11.0)	GIT_COMMIT="2b16aab3955dea836a06f580c0e111396916d7ef" ;;
	1.12.0)	GIT_COMMIT="d1ebd8a057a45e6fdbc975fbcc4c8e8f9ffedb20" ;;
	1.12.2)	GIT_COMMIT="01eb819ff49cb918f157c183b7d50c3d925ddb04" ;;
	1.13.0)	GIT_COMMIT="f8e0f3ced35509f608f360823c57c19b19eb6164" ;;
	1.14.0)	GIT_COMMIT="4f64e8edbdb0d4b68b882aa34474a0156b6ba150" ;;
	1.15.0)	GIT_COMMIT="fc8e3bbd451cff1b9dbfee8f213c6e0a5813b5f4" ;;
	1.16.0)	GIT_COMMIT="2c4146832061635273d153a5174c85fb1d967d57" ;;
	1.16.1)	GIT_COMMIT="deb3623fdccde61207bc21753ac0284ecb259d79" ;;
	1.17.0)	GIT_COMMIT="588ce5a7b18999dfa66698cd3a2f005f7a3c31cf" ;;
	1.18.1)	GIT_COMMIT="697f76c32dfd30eab95592ba3bde117f0867e750" ;;
	1.19.0)	GIT_COMMIT="5000257f0171271cb3ee2cf0fe02e8a2154ddf2e" ;;
	1.20.0)	GIT_COMMIT="563284310302c35a700d707b95824d282aebb6e7" ;;
	1.21.0)	GIT_COMMIT="6931cb80778f104518782d91f4c16dec22e566b6" ;;
	1.21.1)	GIT_COMMIT="b450a1e9d0f0dbbeff9e56325b5ba120be8b97b2" ;;
	1.22.0)	GIT_COMMIT="84e38198c6f3f5a318626f7362e4bdefa3289084" ;;
	1.23.0)	GIT_COMMIT="cd19e256d6a0e1338ab09d75bd1e85ede68098d7" ;;
	1.23.1)	GIT_COMMIT="8dcb85464579cdd8ac99aeea97acb431ecc04ec3" ;;
	1.23.2)	GIT_COMMIT="1baa5c2f1afc40ca2652a76f22856801593aaf8c" ;;
	1.24.0)	GIT_COMMIT="96cf2592193cd436f03552bbc114d59a809c205f" ;;
	1.25.0)	GIT_COMMIT="d4ff1ea72c44f11a7debeb157ab09be882373900" ;;
	1.26.0)	GIT_COMMIT="1a09f7fb810b0afd55c1659f3c135f9a122c960f" ;;
	1.27.0)	GIT_COMMIT="00499259c446ea7d080d8254151c9efc6e799bd8" ;;
	1.28.0)	GIT_COMMIT="85ff6af9fae7abfd5a1165c108c98b405389b4bc" ;;
	1.29.0)	GIT_COMMIT="31d68c983d75e7d4e4c1d9e360ac4030d55f1362" ;;
	1.29.1)	GIT_COMMIT="cb5022688a09e702f692253537730cdb6fe8f954" ;;
	1.29.2)	GIT_COMMIT="6053ce9e113bf036fc7e121130ce44686e5ab164" ;;
	1.29.3)	GIT_COMMIT="9580ed4d13125adac01483bac14a18c952afd13e" ;;
	1.30.0)	GIT_COMMIT="fe27fdc389b58b318cf3973bc3d54ebfe3da5b48" ;;
	1.30.1)	GIT_COMMIT="d5ea3cc5cf7256109c4c76148b5ba0d29328b380" ;;
	1.31.0)	GIT_COMMIT="2f130c01aa487d2541a9f3045ff9970f91cc4fc9" ;;
esac

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata https://my-netdata.io/"
#PATCHES=( "${FILESDIR}/${P}-openrc-fixes.patch" )

LICENSE="GPL-3+ MIT BSD"
SLOT="0"
IUSE="caps cloud +compression cpu_flags_x86_sse2 cups +dbengine fping ipmi +jsonc kinesis +lto mongodb mysql nfacct nodejs postgres prometheus +python systemd tor xen"
REQUIRED_USE="
	mysql? ( python )
	python? ( ${PYTHON_REQUIRED_USE} )
	tor? ( python )"

# Most unconditional dependencies are for plugins.d/charts.d.plugin:
RDEPEND="
	acct-group/netdata
	acct-user/netdata
	app-misc/jq
	>=app-shells/bash-4:0
	|| (
		net-analyzer/openbsd-netcat
		net-analyzer/netcat6
		net-analyzer/netcat
	)
	net-analyzer/tcpdump
	net-analyzer/traceroute
	net-libs/libwebsockets
	net-misc/curl
	net-misc/wget
	sys-apps/util-linux
	virtual/awk
	caps? ( sys-libs/libcap )
	cups? ( net-print/cups )
	dbengine? (
		app-arch/lz4
		dev-libs/judy
		dev-libs/openssl:=
	)
	dev-libs/libuv
	compression? ( sys-libs/zlib )
	fping? ( >=net-analyzer/fping-4.0 )
	ipmi? ( sys-libs/freeipmi )
	jsonc? ( dev-libs/json-c:= )
	kinesis? ( dev-libs/aws-sdk-cpp[kinesis] )
	mongodb? ( dev-libs/mongo-c-driver )
	nfacct? (
		net-firewall/nfacct
		net-libs/libmnl
	)
	nodejs? ( net-libs/nodejs )
	prometheus? (
		dev-libs/protobuf:=
		app-arch/snappy
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep 'dev-python/pyyaml[${PYTHON_USEDEP}]')
		dev-python/dnspython
		mysql? ( $(python_gen_cond_dep 'dev-python/mysqlclient[${PYTHON_USEDEP}]') )
		postgres? ( $(python_gen_cond_dep 'dev-python/psycopg:2[${PYTHON_USEDEP}]') )
		tor? ( $(python_gen_cond_dep 'net-libs/stem[${PYTHON_USEDEP}]') )
	)
	xen? (
		app-emulation/xen-tools
		dev-libs/yajl
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

# Check for Kernel-Samepage-Merging (CONFIG_KSM)
CONFIG_CHECK="
	~KSM
"

FILECAPS=(
	'cap_dac_read_search,cap_sys_ptrace+ep' 'usr/libexec/netdata/plugins.d/apps.plugin'
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
	linux-info_pkg_setup
}

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	if use ppc64; then
		# bundled dlib does not support vsx on big-endian
		# https://github.com/davisking/dlib/issues/397
		[[ $(tc-endian) == big ]] && append-flags -mno-vsx
	fi

	econf \
		--localstatedir="${EPREFIX}"/var \
		--with-user=netdata \
		$(use_enable cloud) \
		$(use_with cloud aclk-ng) \
		$(use_enable jsonc) \
		$(use_enable cups plugin-cups) \
		$(use_enable dbengine) \
		$(use_enable nfacct plugin-nfacct) \
		$(use_enable ipmi plugin-freeipmi) \
		$(use_enable kinesis backend-kinesis) \
		$(use_enable lto lto) \
		$(use_enable mongodb backend-mongodb) \
		$(use_enable prometheus backend-prometheus-remote-write) \
		$(use_enable xen plugin-xenstat) \
		$(use_enable cpu_flags_x86_sse2 x86-sse) \
		$(use_with compression zlib)
}

src_compile() {
	emake clean
	default
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

	# netdata includes 'web root owner' settings, but ignores them and fails to
	# serve its pages if netdata:netdata isn't the owner :(
	fowners -Rc netdata:netdata /usr/share/netdata/web ||
		die "Failed settings owners: ${?}"

	insinto /etc/netdata
	doins system/netdata.conf

	#newinitd system/netdata-openrc "${PN}"
	newinitd "${FILESDIR}/${PN}.initd-r1" "${PN}"
	use systemd && systemd_dounit system/netdata.service

	echo "CONFIG_PROTECT=\"${EPREFIX}/usr/$(get_libdir)/netdata/conf.d\"" > 99netdata
	doenvd 99netdata
}

pkg_postinst() {
	fcaps_pkg_postinst

	if use nfacct ; then
		fcaps 'cap_net_admin' 'usr/libexec/netdata/plugins.d/nfacct.plugin'
	fi

	if use xen ; then
		fcaps 'cap_dac_override' 'usr/libexec/netdata/plugins.d/xenstat.plugin'
	fi

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

	if use ipmi ; then
	    fcaps 'cap_dac_override' 'usr/libexec/netdata/plugins.d/freeipmi.plugin'
	fi
}
