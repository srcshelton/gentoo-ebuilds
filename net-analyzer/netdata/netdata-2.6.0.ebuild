# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{9..13} )

inherit cmake fcaps flag-o-matic go-module linux-info python-single-r1 systemd toolchain-funcs

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/netdata/${PN}.git"
	inherit git-r3
else
	# ... from packaging/cmake/Modules/NetdataDlib.cmake
	# (Could we use sci-libs/dlib?)
	DLIB_VERSION="19.24.8"
	# ... from packaging/cmake/Modules/NetdataEBPFLegacy.cmake
	EBPF_CO_RE_VERSION="v1.5.1"
	EBPF_VERSION="v1.5.1"
	# ... from _libbpf_tag in packaging/cmake/Modules/NetdataLibBPF.cmake
	LIBBPF_VERSION="1.5.1p_netdata"
	# ... release with last change to src/go/go.sum
	GO_VENDOR_VERSION="2.6.0"

	# netdata's proprietary agent.tar.gz is unversioned :(
	AGENT_ETAG="687f3c7a-901b32"
	AGENT_DATE="20250722"

	DLIB_TARBALL="dlib-${DLIB_VERSION}.tar.gz"
	EBPF_CO_RE_TARBALL="netdata-ebpf-co-re-glibc-${EBPF_CO_RE_VERSION}.tar.xz"
	EBPF_TARBALL="netdata-kernel-collector-glibc-${EBPF_VERSION}.tar.xz"
	LIBBPF_TARBALL="v${LIBBPF_VERSION}.tar.gz"  # N.B. 1.4.5 only lacks an initial 'v' :(
	SRC_URI="
		https://github.com/davisking/dlib/archive/refs/tags/v${DLIB_VERSION}.tar.gz -> ${DLIB_TARBALL}
		https://github.com/netdata/${PN}/releases/download/v${PV}/${PN}-v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/netdata/ebpf-co-re/releases/download/${EBPF_CO_RE_VERSION}/${EBPF_CO_RE_TARBALL}
		https://github.com/netdata/kernel-collector/releases/download/${EBPF_VERSION}/${EBPF_TARBALL}
		https://github.com/netdata/libbpf/archive/${LIBBPF_TARBALL} -> ${PN}-libbpf-${LIBBPF_TARBALL}
		https://github.com/srcshelton/netdata/releases/download/v${GO_VENDOR_VERSION}/${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz
		dashboard? ( https://app.netdata.cloud/agent.tar.gz -> ${PN}-agent-${AGENT_ETAG}-${AGENT_DATE}.tar.gz )
	"
	S="${WORKDIR}/${PN}-v${PV}"
	RESTRICT="mirror"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv ~x86"
fi

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata https://my-netdata.io/"

LICENSE="GPL-3+ MIT BSD dashboard? ( NCUL1 )"
SLOT="0"
IUSE="ap apcups -beanstalkd bind bpf +compression cpu_flags_x86_avx cpu_flags_x86_sse2 cpu_flags_x86_sse4_2 cups +dashboard +dbengine dhcp dovecot +go ipmi +jsonc lto lxc mongodb mysql nfacct nginx nodejs nvme podman postfix postgres prometheus +python qos sensors smart snmp systemd tor xen"
REQUIRED_USE="
	ap? ( go )
	beanstalkd? ( python )
	bind? ( go nodejs )
	dhcp? ( go )
	dovecot? ( go )
	mysql? ( go )
	nvme? ( go )
	python? ( ${PYTHON_REQUIRED_USE} )
	sensors? ( go )
	snmp? ( nodejs )
	tor? ( go )"

# See https://raw.githubusercontent.com/netdata/netdata/refs/tags/v2.6.0/packaging/installer/install-required-packages.sh
# See https://raw.githubusercontent.com/netdata/netdata/refs/tags/v2.6.0/packaging/installer/dependencies/gentoo.sh
#
# USE='beanstalkd' requires python-beanstalkc, which is not packaged on Gentoo
#
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
	dev-libs/protobuf:=[protobuf]
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
	ap? ( net-wireless/iw )
	apcups? ( sys-power/apcupsd )
	bpf? (
		virtual/libelf
		dev-libs/libbpf:=[static-libs]
	)
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
	prometheus? ( app-arch/snappy:= )
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep 'dev-python/dnspython[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/numpy[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/pandas[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/python-ldap[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/requests[${PYTHON_USEDEP}]')
		beanstalkd? ( $(python_gen_cond_dep 'dev-python/pyyaml[${PYTHON_USEDEP}]') )
		mysql? ( $(python_gen_cond_dep 'dev-python/mysqlclient[${PYTHON_USEDEP}]') )
		postgres? ( $(python_gen_cond_dep 'dev-python/psycopg:2[${PYTHON_USEDEP}]') )
		tor? ( $(python_gen_cond_dep 'net-libs/stem[${PYTHON_USEDEP}]') )
	)
	qos? ( sys-apps/iproute2 )
	sensors? ( sys-apps/lm-sensors )
	smart? ( sys-apps/smartmontools )
	systemd? ( >=sys-apps/systemd-221 )
	xen? (
		app-emulation/xen-tools
		dev-libs/yajl
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

# See https://raw.githubusercontent.com/netdata/netdata/refs/tags/v2.6.0/packaging/installer/dependencies/gentoo.sh
BDEPEND="
	>=dev-build/cmake-3.16.0
	<dev-build/cmake-3.31
	sys-devel/bison
	sys-devel/flex
	|| ( sys-apps/findutils sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	|| ( sys-apps/grep sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	|| ( sys-apps/sed sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	go? (
		app-arch/unzip
		>=dev-lang/go-1.24.0
		arm? ( || (
			>=sys-devel/binutils-2.41
			sys-devel/binutils[gold]
		) )
		arm64? ( || (
			>=sys-devel/binutils-2.41
			sys-devel/binutils[gold]
		) )
	)"

PATCHES=(
	"${FILESDIR}"/netdata-1.46.2-PROTOBUF_USE_DLLS.patch
	"${FILESDIR}"/netdata-1.46.3-ebpf.patch
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
	usr/lib*/netdata/plugins.d/ebpf.d/*netdata_ebpf_*.o
"

pkg_setup() {
	if ! tc-is-gcc; then
		eerror "${PN} only supports compilation with gcc"
		eerror "See https://learn.netdata.cloud/docs/developer-and-contributor-corner/install-the-netdata-agent-from-a-git-checkout#nonrepresentable-section-on-output-errors"
		die "active toolchain must be gcc"
	fi

	use python && python-single-r1_pkg_setup

	local CONFIG_CHECK='~KPROBES ~KPROBES_ON_FTRACE ~HAVE_KPROBES'
	use bpf && CONFIG_CHECK+=' ~BPF ~BPF_SYSCALL ~BPF_JIT'

	linux-info_pkg_setup
}

src_unpack() {
	local item=''

	#[[ -n ${A} ]] && unpack ${A}

	for item in ${A}; do
		case "${item}" in
			"${P}.tar.gz")
				unpack "${item}"
				;;
			"${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz")
				tar -xa --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${PN}-v${PV}"/ ||
					die
				;;
			"${DLIB_TARBALL}")
				mkdir -p "${PN}-v${PV}_build" ||
					die
				tar -xz --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${T}" ||
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
			"${PN}-agent-${AGENT_ETAG}-${AGENT_DATE}.tar.gz")
				cp "${DISTDIR}/${item}" \
						"${PN}-v${PV}_build"/dashboard.tar.gz ||
					die
				;;
			*)
				die "Unexpected item '${item}' in src_unpack()"
				#ewarn "Unexpected item '${item}' in src_unpack()"
				#unpack "${item}"
				;;
		esac
	done
}

src_prepare() {
	rm .dockerignore || die
	rm Dockerfile && ln -s packaging/docker/Dockerfile . || die

	# From https://gitlab.archlinux.org/archlinux/packaging/packages/netdata/-/blob/main/PKGBUILD
	sed -e "s/CMAKE_CXX_STANDARD 14/CMAKE_CXX_STANDARD 17/" -i CMakeLists.txt || die

	if use dashboard; then
		sed -e '/message(STATUS "Preparing local agent dashboard code")/,+17d' \
			-i packaging/cmake/Modules/NetdataDashboard.cmake || die
	else
		# ~~https://src.fedoraproject.org/rpms/netdata/blob/rawhide/f/netdata.spec#_228~~
		# Pacakage is orphaned/abaondoned as of 2.2.6 - see last commit at:
		# https://src.fedoraproject.org/rpms/netdata/blob/00ad213ef063bd3be9769812d0d78cf09f03974e/f/netdata.spec#_226
		if [[ -d src/web/gui/v2 ]]; then
			rm -r src/web/gui/v2 || die
			if [[ -f src/web/gui/index.html ]]; then
				rm src/web/gui/index.html || die
			fi
		fi

		# ~~https://src.fedoraproject.org/rpms/netdata/blob/rawhide/f/netdata-remove-web-v2.patch~~
		# Pacakage is orphaned/abaondoned as of 2.2.6 - see last commit at:
		# https://src.fedoraproject.org/rpms/netdata/blob/00ad213ef063bd3be9769812d0d78cf09f03974e/f/netdata-remove-web-v2.patch
		sed -e '/include(NetdataDashboard)/s:^:#:' \
			-e '/bundle_dashboard()/s:^:#:' \
			-i CMakeLists.txt || die
	fi

	sed -e 's/JSON-C/dlib/g' \
		-i packaging/cmake/Modules/NetdataDlib.cmake || die

	# See https://github.com/netdata/netdata/issues/20738
	filter-flags -ffast-math
	replace-flags -Ofast -O3
	append-flags -fno-fast-math

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

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=yes
		#-DFETCHCONTENT_FULLY_DISCONNECTED=yes
		#-DFETCHCONTENT_UPDATES_DISCONNECTED=yes
		-DCMAKE_INSTALL_PREFIX=/  # Default, but breaks if not set :o
		#-DCMAKE_BUILD_TYPE=Release  # Ignored

		-DUSE_SSE2_INSTRUCTIONS=$(usex cpu_flags_x86_sse2)
		-DUSE_SSE4_INSTRUCTIONS=$(usex cpu_flags_x86_sse4_2)
		-DUSE_AVX_INSTRUCTIONS=$(usex cpu_flags_x86_avx)

		# FIXME: Why is this referred to twice with different names?  Are these
		# actually the same?
		-DNETDATA_DLIB_SOURCE_PATH="${T}/dlib-${DLIB_VERSION}"
		-DNETDATA_DLIB_SOURCE_DIR="${T}/dlib-${DLIB_VERSION}"

		#-DUSE_CXX_11=False
		-DUSE_LTO=$(usex lto)

		-DENABLE_ML=False  # True by default
		-DENABLE_DBENGINE=$(usex dbengine)

		-DENABLE_PLUGIN_GO=$(usex go)
		-DENABLE_PLUGIN_PYTHON=$(usex python)

		#-DENABLE_PLUGIN_APPS=yes
		#-DENABLE_PLUGIN_CHARTS=yes
		-DENABLE_PLUGIN_CUPS=$(usex cups)

		-DENABLE_PLUGIN_FREEIPMI=$(usex ipmi)

		#-DENABLE_PLUGIN_CGROUP_NETWORK=yes
		#-DENABLE_PLUGIN_DEBUGFS=yes
		-DENABLE_PLUGIN_EBPF=$(usex bpf)
		-DENABLE_LEGACY_EBPF_PROGRAMS=$(usex bpf 'no' 'yes')
		#-DENABLE_PLUGIN_LOCAL_LISTENERS=yes
		#-DENABLE_PLUGIN_NETWORK_VIEWER=yes
		-DENABLE_PLUGIN_NFACCT=$(usex nfacct)
		#-DENABLE_PLUGIN_OTEL=no  # OpenTelemetry collector
		#-DENABLE_PLUGIN_PERF=yes
		#-DENABLE_PLUGIN_SLABINFO=yes
		-DENABLE_PLUGIN_SYSTEMD_JOURNAL=$(usex systemd)
		-DENABLE_PLUGIN_SYSTEMD_UNITS=$(usex systemd)
		-DENABLE_PLUGIN_XENSTAT=$(usex xen)

		-DENABLE_EXPORTER_PROMETHEUS_REMOTE_WRITE=$(usex prometheus)
		-DENABLE_EXPORTER_MONGODB=$(usex mongodb)

		#-DENABLE_BUNDLED_JSONC=no
		#-DENABLE_BUNDLED_YAML=no
		#-DENABLE_BUNDLED_PROTOBUF=no

		# Experimental...
		#-DENABLE_WEBRTC=no
		#-DENABLE_H2O=no

		# Crash reporting...
		#-DENABLE_SENTRY=no

		-DENABLE_LIBBACKTRACE=no
		#-DDLIB_ENABLE_STACK_TRACE=no
	)

	cmake_src_configure
}

src_install() {
	local obj=''

	cmake_src_install

	insinto "/usr/$(get_libdir)/netdata/plugins.d/ebpf.d"
	doins -r "${T}"/ebpf/*

	# Remove unneeded .keep files
	find "${ED}" -name ".keep" -delete || die

	if [[ -f "${ED}/usr/share/netdata/build-info-cmake-cache.gz" ]]; then
		rm "${ED}/usr/share/netdata/build-info-cmake-cache.gz" || die
	fi

	if ! use dashboard; then
		# ~~https://src.fedoraproject.org/rpms/netdata/blob/rawhide/f/netdata.spec#_356~~
		# Pacakage is orphaned/abaondoned as of 2.2.6 - see last commit at:
		# https://src.fedoraproject.org/rpms/netdata/blob/00ad213ef063bd3be9769812d0d78cf09f03974e/f/netdata.spec#_356
		for obj in /etc/netdata-updater.conf /etc/netdata-updater.sh \
				/usr/libexec/netdata/system /var/lib/netdata/config
		do
			if [[ -e "${ED}/${obj}" ]]; then
				rm "${ED}/${obj}" || die
			fi
		done
	fi

	insinto /etc/cron.d
	doins "${ED}"/usr/lib/netdata/system/cron/netdata-updater-daily || die

	exeinto /etc/netdata
	doexe "${FILESDIR}"/edit-config || die

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

	for obj in log/netdata lib/netdata/registry lib/netdata/cloud.d; do
		keepdir "/var/${obj}" || die
		fowners -Rc netdata:netdata "/var/${obj}" || die
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
