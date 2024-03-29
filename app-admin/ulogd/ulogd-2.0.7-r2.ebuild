# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic linux-info readme.gentoo-r1 systemd

DESCRIPTION="A userspace logging daemon for netfilter/iptables related logging"
HOMEPAGE="https://netfilter.org/projects/ulogd/index.html"
SRC_URI="https://www.netfilter.org/projects/ulogd/files/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ia64 ppc x86"
IUSE="dbi doc json mysql nfacct +nfct +nflog pcap postgres selinux sqlite systemd ulog"

DEPEND="
	|| ( net-firewall/iptables net-firewall/nftables )
	>=net-libs/libnfnetlink-1.0.1
	dbi? ( dev-db/libdbi )
	json? ( dev-libs/jansson )
	nfacct? (
		>=net-libs/libmnl-1.0.4
		>=net-libs/libnetfilter_acct-1.0.3
	)
	nfct? ( >=net-libs/libnetfilter_conntrack-1.0.6 )
	nflog? ( >=net-libs/libnetfilter_log-1.0.1 )
	mysql? ( dev-db/mysql-connector-c:= )
	pcap? ( net-libs/libpcap )
	postgres? ( dev-db/postgresql:= )
	sqlite? ( dev-db/sqlite:3 )
"
RDEPEND="
	${DEPEND}
	acct-user/ulogd
	acct-group/ulogd
	selinux? ( sec-policy/selinux-ulogd )
"
BDEPEND="
	doc? (
		app-text/linuxdoc-tools
		app-text/texlive-core
		dev-texlive/texlive-fontsrecommended
		virtual/latex-base
	)
"

DISABLE_AUTOFORMATTING=1
DOC_CONTENTS="
	You must have at least one logging stack enabled to make ulogd work.
	Please edit the example configuration located at '${EPREFIX}/etc/ulogd.conf'.
"

PATCHES=( "${FILESDIR}"/patches/ulogd.patch )

pkg_setup() {
	linux-info_pkg_setup

	if kernel_is lt 2 6 14; then
		die "${PN} requires a kernel >= 2.6.14."
	fi

	if kernel_is lt 2 6 18; then
		ewarn "You are using kernel < 2.6.18: Some ulogd features may be unavailable."
	fi

	if use nfacct && kernel_is lt 3 3 0; then
		ewarn "NFACCT input plugin requires a kernel >= 3.3."
	fi

	if use ulog && kernel_is ge 3 17 0; then
		ewarn "ULOG target has been removed in the 3.17 kernel release."
		ewarn "Consider enabling NFACCT, NFCT, or NFLOG support instead."
	fi
}

src_prepare() {
	default

	# Change default settings to:
	# - keep log files in /var/log/ulogd instead of /var/log;
	# - create sockets in /var/run instead of /tmp.
	sed -i \
		-e "s|var/log|var/log/${PN}|g" \
		-e 's|tmp|var/run|g' \
		ulogd.conf.in || die 'sed on ulogd.conf.in failed'
}

src_configure() {
	append-lfs-flags
	local myeconfargs=(
		$(use_with dbi)
		$(use_with json jansson)
		$(use_enable nfacct)
		$(use_enable nfct)
		$(use_enable nflog)
		$(use_with mysql)
		$(use_with pcap)
		$(use_with postgres pgsql)
		$(use_with sqlite)
		$(use_enable ulog)
	)
	econf "${myeconfargs[@]}"
}

src_compile() {
	default_src_compile

	if use doc; then
		# Prevent access violations from bitmap font files generation.
		export VARTEXFONTS="${T}/fonts"
		emake -C doc
	fi
}

src_install() {
	use doc && HTML_DOCS=( doc/${PN}.html )

	default_src_install
	find "${ED}" -name '*.la' -delete || die

	readme.gentoo_create_doc
	doman ${PN}.8

	use doc && dodoc doc/${PN}.{dvi,ps,txt}
	use mysql && dodoc doc/mysql-*.sql
	use postgres && dodoc doc/pgsql-*.sql
	use sqlite && dodoc doc/sqlite3.table

	insinto /etc
	doins ${PN}.conf
	fowners root:ulogd /etc/${PN}.conf
	fperms 640 /etc/${PN}.conf

	newinitd "${FILESDIR}/${PN}.init" ${PN}
	use systemd && systemd_dounit "${FILESDIR}/${PN}.service"

	insinto /etc/logrotate.d
	newins "${FILESDIR}/${PN}.logrotate" ${PN}

	diropts -o ulogd -g ulogd
	keepdir /var/log/ulogd
}

pkg_postinst() {
	readme.gentoo_print_elog
}
