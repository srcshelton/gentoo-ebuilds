# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 044cc0369ff133502aa9feae18c89899f88bb891 $

EAPI=6
inherit pam systemd

DESCRIPTION="a utility for monitoring and managing daemons or similar programs running on a Unix system"
HOMEPAGE="http://mmonit.com/monit/"
SRC_URI="http://mmonit.com/monit/dist/${P}.tar.gz"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="amd64 ppc ~ppc64 x86 ~amd64-linux"
IUSE="libressl pam ssl systemd"

RDEPEND="
	ssl? (
		!libressl? ( dev-libs/openssl:0= )
		libressl? ( dev-libs/libressl:0= )
	)"
DEPEND="${RDEPEND}
	sys-devel/flex
	sys-devel/bison
	pam? ( virtual/pam )"

src_prepare() {
	default

	sed -i -e '/^INSTALL_PROG/s/-s//' Makefile.in || die "sed failed in Makefile.in"
}

src_configure() {
	econf $(use_with ssl) $(use_with pam) --enable-optimized
}

src_install() {
	default

	dodoc README

	insinto /etc; insopts -m600; doins monitrc
	newinitd "${FILESDIR}"/monit.initd-5.0-r1 monit
	use systemd && systemd_dounit "${FILESDIR}"/${PN}.service

	use pam && newpamd "${FILESDIR}"/${PN}.pamd ${PN}
}

pkg_postinst() {
	elog "Sample configurations are available at:"
	elog "http://mmonit.com/monit/documentation/"
}
