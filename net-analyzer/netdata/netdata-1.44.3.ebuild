# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{10..11} )
GO_OPTIONAL=1

inherit autotools fcaps flag-o-matic go-module linux-info python-single-r1 systemd toolchain-funcs

# cf. https://github.com/netdata/netdata/blob/v${PV}/packaging/go.d.version
GO_D_PLUGIN_PV="0.58.0"
GO_D_PLUGIN_PN="go.d.plugin"
GO_D_PLUGIN_P="${GO_D_PLUGIN_PN}-${GO_D_PLUGIN_PV}"

go-module_set_globals

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/netdata/${PN}.git"
	inherit git-r3
else
	SRC_URI="
		https://github.com/netdata/${PN}/releases/download/v${PV}/${PN}-v${PV}.tar.gz -> ${P}.tar.gz
		go? (
			https://github.com/netdata/${GO_D_PLUGIN_PN}/archive/refs/tags/v${GO_D_PLUGIN_PV}.tar.gz -> ${GO_D_PLUGIN_PN}-v${GO_D_PLUGIN_PV}.tar.gz
			https://github.com/netdata/${GO_D_PLUGIN_PN}/releases/download/v${GO_D_PLUGIN_PV}/${GO_D_PLUGIN_PN}-vendor-v${GO_D_PLUGIN_PV}.tar.gz -> ${GO_D_PLUGIN_PN}-v${GO_D_PLUGIN_PV}-vendor.tar.gz
		)"
	S="${WORKDIR}/${PN}-v${PV}"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv ~x86"
	GO_D_PLUGIN_S="${WORKDIR}/${GO_D_PLUGIN_P}"
	RESTRICT="mirror"
fi

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata
	https://github.com/netdata/go.d.plugin
	https://my-netdata.io/"

LICENSE="GPL-3+ Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
IUSE="bind cloud +compression cpu_flags_x86_sse2 cups +dbengine dhcp dovecot +go ipmi +jsonc mongodb mysql nfacct nodejs nvme podman postgres prometheus +python sensors systemd tor xen"
REQUIRED_USE="
	bind? ( go )
	dhcp? ( go )
	dovecot? ( python )
	mysql? ( go )
	nvme? ( go )
	python? ( ${PYTHON_REQUIRED_USE} )
	sensors? ( python )
	tor? ( python )"

# Most unconditional dependencies are for plugins.d/charts.d.plugin:
RDEPEND="
	acct-group/netdata
	acct-user/netdata[podman?]
	app-alternatives/awk
	app-misc/jq
	>=app-shells/bash-4:0
	dev-libs/libuv:=
	dev-libs/libyaml
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
	sys-libs/libcap
	sys-libs/zlib
	cloud? ( dev-libs/protobuf:= )
	cups? ( net-print/cups )
	dbengine? (
		app-arch/lz4:=
		dev-libs/judy
		dev-libs/openssl:=
	)
	dhcp? (
		acct-group/dhcp
		acct-user/dhcp
	)
	dovecot? (
		acct-group/dovecot
		acct-group/dovenull
		acct-user/dovecot
	)
	ipmi? ( sys-libs/freeipmi )
	jsonc? ( dev-libs/json-c:= )
	mongodb? ( dev-libs/mongo-c-driver )
	mysql? (
		acct-group/mysql
		acct-user/mysql
	)
	bind? (
		acct-group/named
		net-dns/bind
	)
	nfacct? (
		net-firewall/nfacct
		net-libs/libmnl:=
		net-libs/libnetfilter_acct
	)
	nodejs? ( net-libs/nodejs )
	nvme? (
		sys-apps/nvme-cli[json]
	)
	podman? (
		app-containers/podman
	)
	prometheus? (
		app-arch/snappy:=
		dev-libs/protobuf:=
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep 'dev-python/pyyaml[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/dnspython[${PYTHON_USEDEP}]')
		mysql? ( $(python_gen_cond_dep 'dev-python/mysqlclient[${PYTHON_USEDEP}]') )
		postgres? ( $(python_gen_cond_dep 'dev-python/psycopg:2[${PYTHON_USEDEP}]') )
		tor? ( $(python_gen_cond_dep 'net-libs/stem[${PYTHON_USEDEP}]') )
	)
	sensors? ( sys-apps/lm-sensors )
	xen? (
		app-emulation/xen-tools
		dev-libs/yajl
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig"
BDEPEND="
	sys-apps/sed
	go? (
		app-arch/unzip
		>=dev-lang/go-1.21
		arm? ( sys-devel/binutils[gold] )
		arm64? ( sys-devel/binutils[gold] )
	)"

FILECAPS=(
	'cap_dac_read_search,cap_sys_ptrace+ep'
		'usr/libexec/netdata/plugins.d/apps.plugin'
		'usr/libexec/netdata/plugins.d/debugfs.plugin'

	--

	'cap_net_raw'
		'usr/libexec/netdata/plugins.d/go.d.plugin'
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
	linux-info_pkg_setup
}

src_unpack() {
	local -x GO_MODULE_SOURCE_DIR="${GO_D_PLUGIN_S}"
	#local -x NONFATAL_VERIFY='nonfatal'

	if use go; then
		go-module_src_unpack
	else
		default
	fi
}

src_prepare() {
	default

	# go.d.plugin uses /usr/lib/netdata, whereas netdata itself uses
	# /usr/lib64/netdata (on amd64 platforms) :(
	if use go; then
		pushd "${GO_D_PLUGIN_S}" >/dev/null
		#eapply "${FILESDIR}/${PN}-go-mod-badhash.patch"
		sed -e "/[/]usr[/]lib[/]netdata[/]/s|/lib/|/$(get_libdir)/|" \
			-i Dockerfile.dev cmd/godplugin/main.go examples/simple/main.go ||
				die "go.d.plugin library path update failed: ${?}"
		popd >/dev/null
	fi
	# /etc/netdata/edit_config also uses /usr/lib/netdata...
	sed -e "/[/]usr[/]lib[/]netdata[/]/s|/lib/|/$(get_libdir)/|" \
		-i system/edit-config ||
			die "edit-config library path update failed: ${?}"

	eautoreconf
}

src_configure() {
	if use ppc64; then
		# bundled dlib does not support vsx on big-endian
		# https://github.com/davisking/dlib/issues/397
		[[ $(tc-endian) == big ]] && append-flags -mno-vsx
	fi

	# --enable-lto only appends -flto
	econf \
		--localstatedir="${EPREFIX}"/var \
		--with-user=netdata \
		--without-bundled-protobuf \
		$(use_enable cloud) \
		$(use_enable jsonc) \
		$(use_enable cups plugin-cups) \
		$(use_enable dbengine) \
		$(use_enable nfacct plugin-nfacct) \
		$(use_enable ipmi plugin-freeipmi) \
		--disable-exporting-kinesis \
		--disable-lto \
		$(use_enable mongodb exporting-mongodb) \
		$(use_enable prometheus exporting-prometheus-remote-write) \
		$(use_enable xen plugin-xenstat) \
		$(use_enable cpu_flags_x86_sse2 x86-sse)
}

src_compile() {
	default

	if use go; then
		local -x TRAVIS_TAG="v${GO_D_PLUGIN_PV}"
		local -x LDFLAGS="-w -s -X main.version=${GO_D_PLUGIN_PV}-gentoo"
		pushd "${GO_D_PLUGIN_S}" >/dev/null
		ego build -ldflags "${LDFLAGS}" \
			"github.com/netdata/go.d.plugin/cmd/godplugin"
		popd >/dev/null
	fi
}

src_test() {
	if use go; then
		pushd "${GO_D_PLUGIN_S}" >/dev/null
		ego test ./... -race -cover -covermode=atomic
		popd >/dev/null
	fi
}

src_install() {
	local dir=''

	default

	if use go; then
		pushd "${GO_D_PLUGIN_S}" >/dev/null

		einstalldocs

		exeinto /usr/libexec/netdata/plugins.d
		newexe godplugin go.d.plugin
		insinto /usr/$(get_libdir)/netdata/conf.d
		doins -r config/go.d

		popd >/dev/null
	fi

	# Remove unneeded .keep files
	find "${ED}" -name ".keep" -delete || die

	insinto /etc/cron.d
	doins "${ED}"/usr/$(get_libdir)/netdata/system/cron/netdata-updater-daily

	#rm -r "${ED}"/usr/share/netdata/web/old
	rm \
		"${ED}"/usr/libexec/netdata/charts.d/README.md \
		"${ED}"/usr/libexec/netdata/node.d/README.md \
		"${ED}"/usr/libexec/netdata/plugins.d/README.md

	if ! use nodejs; then
		rm -r "${ED}"/usr/libexec/netdata/node.d
		rm "${ED}"/usr/libexec/netdata/plugins.d/node.d.plugin
	fi

	rm -r \
		"${ED}"/usr/$(get_libdir)/netdata/system

	# netdata includes 'web root owner' settings, but ignores them and
	# fails to serve its pages if netdata:netdata isn't the owner :(
	#fowners -Rc netdata:netdata /usr/share/netdata/web ||
	#	die "Failed settings owners: ${?}"

	rmdir -p "${ED}"/var/log "${ED}"/var/cache 2>/dev/null

	for dir in log/netdata lib/netdata/registry $(usex cloud 'lib/netdata/cloud.d' ''); do
		keepdir "/var/${dir}" || die
		fowners -Rc netdata:netdata "/var/${dir}" || die
	done
	fowners -Rc netdata:netdata /var/lib/netdata || die

	fowners -Rc root:netdata /usr/share/netdata || die

	#newinitd system/openrc/init.d/netdata ${PN}
	#newconfd system/openrc/conf.d/netdata ${PN}
	newinitd "${FILESDIR}/${PN}.initd-r1" "${PN}"
	newconfd "${FILESDIR}/${PN}.confd" "${PN}"
	if use systemd; then
		systemd_dounit system/systemd/netdata.service
		systemd_dounit system/systemd/netdata-updater.service
		systemd_dounit system/systemd/netdata-updater.timer
	fi
	insinto /etc/netdata
	doins system/netdata.conf

	echo "CONFIG_PROTECT=\"${EPREFIX}/usr/libexec/netdata/conf.d\"" > \
		"${T}"/99netdata
	doenvd "${T}"/99netdata
}

pkg_postinst() {
	fcaps_pkg_postinst

	if use nfacct ; then
		fcaps 'cap_net_admin' 'usr/libexec/netdata/plugins.d/nfacct.plugin'
	fi

	if use xen ; then
		fcaps 'cap_dac_override' 'usr/libexec/netdata/plugins.d/xenstat.plugin'
	fi

	if use ipmi ; then
	    fcaps 'cap_dac_override' 'usr/libexec/netdata/plugins.d/freeipmi.plugin'
	fi
}

# vi: set diffopt=filler,iwhite:
