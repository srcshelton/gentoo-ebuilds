# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{9..12} )

inherit cmake fcaps flag-o-matic go-module linux-info python-single-r1 systemd

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/netdata/${PN}.git"
	inherit git-r3
else
	# ... from packaging/ebpf-co-re.version
	EBPF_CORE_VERSION="v1.3.1"
	EBPF_VERSION="v1.3.1"
	LIBBPF_VERSION="1.3.0p_netdata"
	EBPF_CORE_TARBALL="netdata-ebpf-co-re-glibc-${EBPF_CORE_VERSION}.tar.xz"
	EBPF_TARBALL="netdata-kernel-collector-glibc-${EBPF_VERSION}.tar.xz"
	LIBBPF_TARBALL="v${LIBBPF_VERSION}.tar.gz"
	SRC_URI="
		https://github.com/netdata/${PN}/releases/download/v${PV}/${PN}-v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/netdata/ebpf-co-re/releases/download/${EBPF_CORE_VERSION}/${EBPF_CORE_TARBALL}
		https://github.com/netdata/kernel-collector/releases/download/${EBPF_VERSION}/${EBPF_TARBALL}
		https://github.com/netdata/libbpf/archive/${LIBBPF_TARBALL} -> ${PN}-libbpf-${LIBBPF_TARBALL}
		https://github.com/srcshelton/netdata/releases/download/v${PV}/${P}-vendor.tar.xz
	"
	S="${WORKDIR}/${PN}-v${PV}"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv ~x86"
fi

DESCRIPTION="Linux real time system monitoring, done right!"
HOMEPAGE="https://github.com/netdata/netdata https://my-netdata.io/"

LICENSE="GPL-3+ MIT BSD"
SLOT="0"
IUSE="aclk bind bpf cloud +compression cpu_flags_x86_sse2 cups +dbengine dhcp dovecot +go ipmi +jsonc mongodb mysql nfacct nodejs nvme podman postgres prometheus +python sensors systemd tor xen"
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
	virtual/libelf
	bpf? ( dev-libs/libbpf:=[static-libs] )
	cloud? ( dev-libs/protobuf:= )
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
	)
	systemd? ( sys-apps/systemd )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"
BDEPEND="
	|| ( sys-apps/findutils sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	|| ( sys-apps/grep sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	|| ( sys-apps/sed sys-apps/busybox[make-symlinks] app-alternatives/sh[busybox] )
	go? (
		app-arch/unzip
		>=dev-lang/go-1.21
		arm? ( sys-devel/binutils[gold] )
		arm64? ( sys-devel/binutils[gold] )
	)"

PATCHES=(
	"${FILESDIR}"/netdata-1.45.5-PROTOBUF_USE_DLLS.patch
)

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
			"${P}-vendor.tar.xz")
				mkdir -p "${PN}-v${PV}"/src/go/collectors ||
					die
				tar -xa --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${PN}-v${PV}"/src/go/collectors ||
					die
				;;
			"${EBPF_CORE_TARBALL}")
				mkdir -p "${PN}-v${PV}"/src/libnetdata/ebpf ||
					die
				tar -xa --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${PN}-v${PV}"/src/libnetdata/ebpf ||
					die
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
				mkdir -p "${PN}-v${PV}"/externaldeps/libbpf ||
					die
				tar -xz --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${PN}-v${PV}"/externaldeps/libbpf ||
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
	rm src/fluent-bit/Dockerfile && ln -s dockerfiles/Dockerfile src/fluent-bit/

	# From https://gitlab.archlinux.org/archlinux/packaging/packages/netdata/-/blob/main/PKGBUILD
	sed -e "s/CMAKE_CXX_STANDARD 14/CMAKE_CXX_STANDARD 17/" -i CMakeLists.txt

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

		#-DUSE_CXX_11=False
		#-DENABLE_ADDRESS_SANITIZER=False

		-DENABLE_CLOUD=$(usex cloud)
		-DENABLE_ACLK=$(usex aclk)
		#-DENABLE_ML=True
		#-DENABLE_H2O=True
		-DENABLE_DBENGINE=$(usex dbengine)

		#-DENABLE_PLUGIN_APPS=True
		#-DENABLE_PLUGIN_CGROUP_NETWORK=True
		-DENABLE_PLUGIN_CUPS=$(usex cups)
		#-DENABLE_PLUGIN_DEBUGFS=True
		-DENABLE_PLUGIN_EBPF=$(usex bpf)
		-DENABLE_PLUGIN_FREEIPMI=$(usex ipmi)
		#-DENABLE_PLUGIN_GO=True
		#-DENABLE_PLUGIN_LOCAL_LISTENERS=True
		#-DENABLE_PLUGIN_LOGS_MANAGEMENT=True
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

		#-DENABLE_LOGS_MANAGEMENT_TESTS=True

		#-DENABLE_SENTRY=False
		#-DENABLE_WEBRTC=False

	)
	cmake_src_configure
}

src_compile() {
	local libbpf_path="externaldeps/libbpf/libbpf-${LIBBPF_VERSION}"

	[[ -d "${libbpf_path}"/src ]] || die

	emake -C "${libbpf_path}"/src \
			BUILD_STATIC_ONLY=1 \
			OBJDIR=build \
			DESTDIR=.. \
			V=1 \
		install

	cp -r "${libbpf_path}/usr/$(get_libdir)/libbpf.a" \
			externaldeps/libbpf/ ||
		die
	cp -r "${libbpf_path}/usr/include" \
			externaldeps/libbpf/ ||
		die
	cp -r "${libbpf_path}/include/uapi" \
			externaldeps/libbpf/include/ ||
		die

	unset libbpf_path

	default
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

	rmdir -p "${ED}"/var/log "${ED}"/var/cache 2>/dev/null

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
