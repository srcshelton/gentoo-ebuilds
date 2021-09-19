# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# See https://sourceforge.net/p/squirrelmail/code/14928/log/?path=/trunk/imap_proxy
# ... the last change besides comments was r14637, although Debian patches are
# still being updated.

EAPI=7

WANT_AUTOCONF="2.1"
inherit autotools eutils toolchain-funcs

DESCRIPTION="Proxy IMAP transactions between an IMAP client and an IMAP server"
HOMEPAGE="https://sourceforge.net/projects/squirrelmail/"
SRC_URI="https://sourceforge.net/code-snapshots/svn/s/sq/squirrelmail/code/squirrelmail-code-r${PV#*_p}-trunk.zip"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="kerberos ssl +tcpd"

RDEPEND="sys-libs/ncurses
	kerberos? ( virtual/krb5 )
	ssl? ( dev-libs/openssl )
	tcpd? ( >=sys-apps/tcp-wrappers-7.6 )"
DEPEND="${RDEPEND}
	sys-apps/sed"
BDEPEND="app-arch/unzip"

S="${WORKDIR}/squirrelmail-code-r${PV#*_p}-trunk/imap_proxy"

PATCHES=(
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/fix-egd-ifdef.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/check-dup-return-value.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/fix-missing-definitions.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/fix-size_t-formatters.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/fix-ssl-types.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/fix-socklen_t-types.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/remove-unused-variables.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/openssl-1.1.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/cleanup-names.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/cleanup-readme.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/cleanup-imapproxy_conf.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/configure_imapproxy_conf.patch
	"${FILESDIR}"/debian-1.2.8-svn20171105-2/remove-install-chown.patch
	"${FILESDIR}/${P%_p*}"-tinfo.patch
	"${FILESDIR}/${P%_p*}"-aarch64.patch
	"${FILESDIR}/${P%_p*}"-warnings.patch
)

src_prepare() {
	default

	sed -i \
		-e 's:in\.imapproxyd:imapproxyd:g' \
		README Makefile.in include/imapproxy.h || die

	#buffer oveflow
	#http://lists.andrew.cmu.edu/pipermail/imapproxy-info/2010-June/000874.html
	sed -i \
		-e "/define BUFSIZE/s/4096/8192/" \
		-e "/define MAXPASSWDLEN/s/64/8192/" \
		include/imapproxy.h

	eautoreconf

	mkdir bin
}

src_configure() {
	tc-export CC
	econf \
		$(use_with kerberos krb5) \
		$(use_with ssl openssl) \
		$(use_with tcpd libwrap)
}

src_install() {
	dosbin bin/imapproxyd bin/pimpstat

	insinto /etc
	newins scripts/imapproxy.conf imapproxyd.conf

	newinitd "${FILESDIR}"/imapproxy.initd imapproxy

	dodoc README
	use ssl && dodoc README.ssl

	doman "${FILESDIR}"/*.8
}
