# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MODULES_OPTIONAL_IUSE="+modules"
inherit flag-o-matic linux-mod-r1

XTABLES_MODULES=(
	account chaos delude dhcpmac dnetmap 'echo' ipmark logmark proto sysrq
	tarpit asn condition fuzzy geoip gradm iface ipp2p ipv4options length2
	lscan pknock psd quota2
)

MODULES_KERNEL_MIN=5.4

DESCRIPTION="iptables extensions not yet accepted in the main kernel"
HOMEPAGE="
	https://inai.de/projects/xtables-addons/
	https://codeberg.org/jengelh/xtables-addons/
"
SRC_URI="https://inai.de/files/xtables-addons/${P}.tar.xz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="${XTABLES_MODULES[*]/#/xtables_addons_}"

XTABLES_SCRIPTS_DEPEND="
	app-alternatives/gzip
	app-arch/unzip
	dev-perl/Net-CIDR-Lite
	dev-perl/Text-CSV_XS
	virtual/perl-Getopt-Long
"
DEPEND=">net-firewall/iptables-1.6.0:="
RDEPEND="${DEPEND}
	xtables_addons_asn? ( ${XTABLES_SCRIPTS_DEPEND} )
	xtables_addons_geoip? ( ${XTABLES_SCRIPTS_DEPEND} )
"
BDEPEND="virtual/pkgconfig"

pkg_setup() {
	local CONFIG_CHECK="NF_CONNTRACK NF_CONNTRACK_MARK"

	if use xtables_addons_ipp2p; then
		CONFIG_CHECK+=" ~TEXTSEARCH_BM"
		local ERROR_TEXTSEARCH_BM="CONFIG_TEXTSEARCH_BM: is not set but is needed to use xt_ipp2p"
	fi

	if use xtables_addons_pknock; then
		CONFIG_CHECK+=" ~CONNECTOR"
		local ERROR_CONNECTOR="CONFIG_CONNECTOR: is not set but is needed to receive userspace
		notifications from pknock through netlink/connector"
	fi

	linux-mod-r1_pkg_setup
}

src_prepare() {
	default

	local mod=''
	local -a modules=()

	mapfile -t modules < <(sed -En 's/^build_(.+)=.*/\L\1/p' mconfig || die)
	[[ ${modules[*]} == "${XTABLES_MODULES[*]}" ]] ||
		die "XTABLES_MODULES needs to be updated to: '${modules[*]}'"

	for mod in "${modules[@]}"; do
		use xtables_addons_${mod} || sed -i "/^build_${mod}=/Id" mconfig || die
	done
}

src_configure() {
	# Uses CFLAGS for tools, and it may mismatch with the kernel's CC
	#use modules && CC=${KERNEL_CC} strip-unsupported-flags

	local econfargs=(
		--libdir="${EPREFIX%/}/usr/$(get_libdir)"
		--libexecdir="${EPREFIX%/}/usr/libexec"
		$(usex modules --with-kbuild="${KV_OUT_DIR}" --without-kbuild)

		# Needed for cross-compiling and to avoid a clash with the
		# Gentoo ARCH.
		ARCH="$(tc-arch-kernel)"
	)

	econf "${econfargs[@]}"
}

src_compile() {
	use modules || MODULES_MAKEARGS=()

	emake "${MODULES_MAKEARGS[@]}"
}

src_install() {
	MODULES_MAKEARGS+=(
		DESTDIR="${D}"
		INSTALL_MOD_DIR=xtables_addons
	)

	emake "${MODULES_MAKEARGS[@]}" install
	modules_post_process

	dodoc -r README.rst doc/.

	use xtables_addons_asn ||
		find "${ED}" -type f -name '*_asn*' -delete || die
	use xtables_addons_geoip ||
		find "${ED}" -type f -name '*_geoip*' -delete || die

	[[ "$(get_libdir)" == 'lib' ]] ||
		rmdir -p "${ED%/}/usr/lib"
	find "${ED}" -type f -name '*.la' -delete || die
}
