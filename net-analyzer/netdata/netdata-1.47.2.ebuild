# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{9..12} )

inherit cmake fcaps flag-o-matic go-module linux-info python-single-r1 systemd

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/netdata/${PN}.git"
	inherit git-r3
else
	# ... from packaging/cmake/Modules/NetdataEBPFLegacy.cmake
	EBPF_CO_RE_VERSION="v1.4.5.1"
	EBPF_VERSION="v1.4.5.1"
	LIBBPF_VERSION="1.4.5p_netdata"
	GO_VENDOR_VERSION="1.47.1"
	EBPF_CO_RE_TARBALL="netdata-ebpf-co-re-glibc-${EBPF_CO_RE_VERSION}.tar.xz"
	EBPF_TARBALL="netdata-kernel-collector-glibc-${EBPF_VERSION}.tar.xz"
	LIBBPF_TARBALL="${LIBBPF_VERSION}.tar.gz"  # N.B. 1.4.5 only lacks an initial 'v' :(
	SRC_URI="
		https://github.com/netdata/${PN}/releases/download/v${PV}/${PN}-v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/netdata/ebpf-co-re/releases/download/${EBPF_CO_RE_VERSION}/${EBPF_CO_RE_TARBALL}
		https://github.com/netdata/kernel-collector/releases/download/${EBPF_VERSION}/${EBPF_TARBALL}
		https://github.com/netdata/libbpf/archive/${LIBBPF_TARBALL} -> ${PN}-libbpf-${LIBBPF_TARBALL}
		https://github.com/srcshelton/netdata/releases/download/v${GO_VENDOR_VERSION}/${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz
	"
	S="${WORKDIR}/${PN}-v${PV}"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv ~x86"
fi

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata https://my-netdata.io/"

LICENSE="GPL-3+ MIT BSD"
SLOT="0"
IUSE="aclk ap apcups bind bpf cloud +compression cpu_flags_x86_sse2 cups +dbengine dhcp dovecot +go ipmi +jsonc lxc mongodb mysql nfacct nginx nodejs nvme podman postfix postgres prometheus +python qos sensors smart systemd tor xen"
REQUIRED_USE="
	ap? ( go )
	bind? ( go )
	dhcp? ( go )
	dovecot? ( go )
	mysql? ( go )
	nvme? ( go )
	python? ( ${PYTHON_REQUIRED_USE} )
	sensors? ( python )
	tor? ( go )"

# See https://raw.githubusercontent.com/netdata/netdata/master/packaging/installer/install-required-packages.sh
# Most unconditional dependencies are for plugins.d/charts.d.plugin:
RDEPEND="
	acct-group/netdata
	acct-user/netdata[podman?]
	app-admin/sysstat
	app-admin/ulogd
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
	net-firewall/firehol
	net-firewall/ipset
	net-firewall/iptables
	net-libs/libwebsockets
	net-misc/bridge-utils
	net-misc/curl
	net-misc/wget
	sys-apps/coreutils
	sys-apps/logwatch
	sys-apps/util-linux
	sys-libs/libcap
	sys-libs/zlib
	sys-process/iotop
	virtual/libelf
	ap? ( net-wireless/iw )
	apcups? ( sys-power/apcupsd )
	bpf? ( dev-libs/libbpf:=[static-libs] )
	cloud? ( dev-libs/protobuf:=[protobuf] )
	cups? ( net-print/cups )
	dbengine? (
		app-arch/brotli:=
		app-arch/lz4:=
		app-arch/zstd:=
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
	lxc? ( app-containers/lxc )
	mongodb? ( dev-libs/mongo-c-driver )
	mysql? (
		acct-group/mysql
		acct-user/mysql
	)
	nginx? ( www-servers/nginx )
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
	nvme? ( sys-apps/nvme-cli[json] )
	podman? ( app-containers/podman )
	postfix? ( mail-mta/postfix )
	prometheus? (
		app-arch/snappy:=
		dev-libs/protobuf:=[protobuf]
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep 'dev-python/dnspython[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/numpy[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/pandas[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/python-ldap[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/pyyaml[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/requests[${PYTHON_USEDEP}]')
		mysql? ( $(python_gen_cond_dep 'dev-python/mysqlclient[${PYTHON_USEDEP}]') )
		postgres? ( $(python_gen_cond_dep 'dev-python/psycopg:2[${PYTHON_USEDEP}]') )
		tor? ( $(python_gen_cond_dep 'net-libs/stem[${PYTHON_USEDEP}]') )
	)
	qos? ( sys-apps/iproute2 )
	sensors? ( sys-apps/lm-sensors )
	smart? ( sys-apps/smartmontools )
	systemd? ( sys-apps/systemd )
	xen? (
		app-emulation/xen-tools
		dev-libs/yajl
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig"
BDEPEND="
	|| ( sys-apps/findutils sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	|| ( sys-apps/grep sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	|| ( sys-apps/sed sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	go? (
		app-arch/unzip
		>=dev-lang/go-1.22
		arm? ( sys-devel/binutils[gold] )
		arm64? ( sys-devel/binutils[gold] )
	)"

PATCHES=(
	"${FILESDIR}"/netdata-1.46.2-PROTOBUF_USE_DLLS.patch
	"${FILESDIR}"/netdata-1.46.3-ebpf.patch
	"${FILESDIR}"/netdata-1.47-pipe_path.patch
	"${FILESDIR}"/netdata-1.47-no_external_libbpf.patch
)

FILECAPS=(
	'cap_dac_read_search,cap_sys_ptrace+ep'
	'usr/libexec/netdata/plugins.d/apps.plugin'
	'usr/libexec/netdata/plugins.d/debugfs.plugin'

	--

	'cap_net_raw'
		'usr/libexec/netdata/plugins.d/go.d.plugin'
)

QA_WX_LOAD="
	usr/lib/netdata/plugins.d/ebpf.d/[pr]netdata_ebpf_*.o
	usr/lib32/netdata/plugins.d/ebpf.d/[pr]netdata_ebpf_*.o
	usr/libx32/netdata/plugins.d/ebpf.d/[pr]netdata_ebpf_*.o
	usr/lib64/netdata/plugins.d/ebpf.d/[pr]netdata_ebpf_*.o
"

pkg_setup() {
	use python && python-single-r1_pkg_setup

	local CONFIG_CHECK='~KPROBES ~KPROBES_ON_FTRACE ~HAVE_KPROBES'
	use bpf && CONFIG_CHECK+='BPF BPF_SYSCALL BPF_JIT'

	linux-info_pkg_setup
}

src_unpack() {
	#[[ -n ${A} ]] && unpack ${A}

	local item=''

	for item in ${A}; do
		case "${item}" in
			"${P}.tar.gz")
				unpack "${item}"
				;;
			"${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz")
				tar -xa --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${PN}-v${PV}"/src/ ||
					die
				;;
			"${EBPF_CO_RE_TARBALL}")
				mkdir -p "${PN}-v${PV}_build"/ebpf-co-re-prefix/src ||
					die
				cp "${DISTDIR}/${item}" \
					"${PN}-v${PV}_build"/ebpf-co-re-prefix/src/
				;;
			"${EBPF_TARBALL}")
				mkdir -p "${T}"/ebpf ||
					die
				tar -xa --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${T}"/ebpf ||
					die
				;;
			"${PN}-libbpf-${LIBBPF_TARBALL}")
				mkdir -p "${PN}-v${PV}_build" ||
					die
				tar -xz --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${T}" ||
					die
				mv "${T}/libbpf-${LIBBPF_VERSION}" \
						"${PN}-v${PV}_build"/libbpf ||
					die
				;;
			*)
				ewarn "Unexpected item '${item}' in src_unpack()"
				unpack "${item}"
				;;
		esac
	done
}

src_prepare() {
	rm .dockerignore
	rm Dockerfile && ln -s packaging/docker/Dockerfile .

	# From https://gitlab.archlinux.org/archlinux/packaging/packages/netdata/-/blob/main/PKGBUILD
	sed -e "s/CMAKE_CXX_STANDARD 14/CMAKE_CXX_STANDARD 17/" -i CMakeLists.txt

	# Awkwardly, if we want to avoid a configure-time failure or having to
	# disable sandboxing and run 'git' against an internet repo, we need to
	# have netdata's fork of libbpf already built and available within the main
	# netdata source tree... and the only way we can really do that is by
	# buliding it here :(
	#
	# We need ${WORKDIR}/${PN}-v${PV}_build/libbpf/usr/lib64/libbpf.a to be
	# present _before_ running cmake_src_configure()
	#
	pushd "${WORKDIR}/${PN}-v${PV}_build/libbpf" ||
		die "libbpf src directory missing"
	mkdir -pv src/build
	emake -C src BUILD_STATIC_ONLY=1 OBJDIR=build V=1 all ||
		die "libbpf 'emake' failed: ${?}"
	emake -C src BUILD_STATIC_ONLY=1 OBJDIR=build DESTDIR=.. V=1 install ||
		die "libbpf 'emake install' failed: ${?}"
	[[ -f "${WORKDIR}/${PN}-v${PV}_build/libbpf/usr/lib64/libbpf.a" ]] ||
		die "libbpf failed to create static library during src_prepare"
	popd

	#[[ -f "${WORKDIR}/${PN}-v${PV}_build/ebpf-co-re-prefix/src/netdata-ebpf-co-re-glibc-${EBPF_CO_RE_VERSION}.tar.xz" ]] ||
	#	die "netdata-ebpf-co-re missing"

	cmake_src_prepare
}

src_configure() {
	# -Werror=strict-aliasing
	# https://bugs.gentoo.org/927174
	# https://github.com/netdata/netdata/issues/17321
	#
	# Do not trust with LTO either.
	append-flags -fno-strict-aliasing
	filter-lto

	local mycmakeargs=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=TRUE
		-DCMAKE_INSTALL_PREFIX=/
		-DCMAKE_BUILD_TYPE=Release

		#-DUSE_CXX_11=False

		-DENABLE_CLOUD=$(usex cloud)
		-DENABLE_ACLK=$(usex aclk)

		#-DENABLE_ML=True
		-DENABLE_DBENGINE=$(usex dbengine)

		#-DENABLE_PLUGIN_GO=True
		#-DENABLE_PLUGIN_PYTHON=True

		#-DENABLE_PLUGIN_APPS=True
		#-DENABLE_PLUGIN_CHARTS=True
		-DENABLE_PLUGIN_CUPS=$(usex cups)

		-DENABLE_PLUGIN_FREEIPMI=$(usex ipmi)

		#-DENABLE_PLUGIN_CGROUP_NETWORK=True
		#-DENABLE_PLUGIN_DEBUGFS=True
		-DENABLE_PLUGIN_EBPF=$(usex bpf 'yes' 'no')
		-DENABLE_LEGACY_EBPF_PROGRAMS=$(usex bpf 'no' 'yes')
		#-DENABLE_PLUGIN_LOCAL_LISTENERS=True
		#-DENABLE_PLUGIN_NETWORK_VIEWER=True
		-DENABLE_PLUGIN_NFACCT=$(usex nfacct)
		#-DENABLE_PLUGIN_PERF=True
		#-DENABLE_PLUGIN_SLABINFO=True
		-DENABLE_PLUGIN_SYSTEMD_JOURNAL=$(usex systemd)
		-DENABLE_PLUGIN_XENSTAT=$(usex xen)

		-DENABLE_EXPORTER_PROMETHEUS_REMOTE_WRITE=$(usex prometheus)
		-DENABLE_EXPORTER_MONGODB=$(usex mongodb)

		#-DENABLE_BUNDLED_JSONC=False
		#-DENABLE_BUNDLED_YAML=False
		#-DENABLE_BUNDLED_PROTOBUF=False

		# Experimental...
		#-DENABLE_WEBRTC=False
		#-DENABLE_H2O=True

		# Crash reporting...
		#-DENABLE_SENTRY=False

	)

	#export VERBOSE=1

	cmake_src_configure
}

src_install() {
	cmake_src_install

	insinto "/usr/$(get_libdir)/netdata/plugins.d/ebpf.d"
	doins -r "${T}"/ebpf/*

	# Remove unneeded .keep files
	find "${ED}" -name ".keep" -delete || die

	insinto /etc/cron.d
	#doins "${ED}"/usr/$(get_libdir)/netdata/system/cron/netdata-updater-daily
	doins "${ED}"/usr/lib/netdata/system/cron/netdata-updater-daily

	insinto /etc/netdata
	doexe "${FILESDIR}"/edit-config

	#rm -r "${ED}"/usr/share/netdata/web/old
	rm \
		"${ED}"/usr/libexec/netdata/charts.d/README.md \
		"${ED}"/usr/libexec/netdata/node.d/README.md \
		"${ED}"/usr/libexec/netdata/plugins.d/README.md

	if ! use nodejs; then
		rm -r "${ED}"/usr/libexec/netdata/node.d
		rm "${ED}"/usr/libexec/netdata/plugins.d/node.d.plugin
	fi

	# netdata includes 'web root owner' settings, but ignores them and
	# fails to serve its pages if netdata:netdata isn't the owner :(
	#fowners -Rc netdata:netdata /usr/share/netdata/web ||
	#	die "Failed settings owners: ${?}"

	rmdir -p \
			"${ED}"/var/cache/netdata \
			"${ED}"/var/log/netdata \
			"${ED}"/var/run/netdata \
		2>/dev/null

	for dir in log/netdata lib/netdata/registry $(usex cloud 'lib/netdata/cloud.d' ''); do
		keepdir "/var/${dir}" || die
		fowners -Rc netdata:netdata "/var/${dir}" || die
	done
	fowners -Rc netdata:netdata /var/lib/netdata || die

	fowners -Rc root:netdata /usr/share/netdata || die
	#newinitd "${ED}/usr/lib/netdata/system/openrc/init.d/netdata" "${PN}"
	#newconfd "${ED}/usr/lib/netdata/system/openrc/conf.d/netdata" "${PN}"
	newinitd "${FILESDIR}/${PN}.initd-r1" "${PN}"
	newconfd "${FILESDIR}/${PN}.confd" "${PN}"
	if use systemd; then
		systemd_newunit "${ED}/usr/lib/netdata/system/systemd/netdata.service.v235" netdata.service
		systemd_dounit "${ED}/usr/lib/netdata/system/systemd/netdata-updater.service"
		systemd_dounit "${ED}/usr/lib/netdata/system/systemd/netdata-updater.timer"
	fi
	insinto /etc/netdata
	doins system/netdata.conf

	echo "CONFIG_PROTECT=\"${EPREFIX}/usr/libexec/netdata/conf.d\"" > \
		"${T}"/99netdata
	doenvd "${T}"/99netdata

	rm -r "${ED}"/usr/lib/netdata/system
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
