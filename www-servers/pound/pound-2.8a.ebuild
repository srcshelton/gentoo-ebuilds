# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

COMMIT_HASH='b846569efca0b0258ad6ba8041624489e9048e6b'
DESCRIPTION="A http/https reverse-proxy and load-balancer"
HOMEPAGE="http://www.apsis.ch/pound/"
SRC_URI="https://github.com/zevenet/pound/archive/${COMMIT_HASH}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha amd64 ~hppa ~mips ~ppc ~sparc x86"
IUSE="libressl"

DEPEND="dev-libs/libpcre
	!libressl? ( dev-libs/openssl:0 )
	libressl? ( dev-libs/libressl )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}-${COMMIT_HASH}"

PATCHES=(
	"${FILESDIR}/${P}-waf.patch"
)

src_prepare() {
	default

	rm waf.c
}

src_install() {
	dodir /usr/sbin
	cp "${S}"/pound "${D}"/usr/sbin/
	cp "${S}"/poundctl "${D}"/usr/sbin/

	doman pound.8
	doman poundctl.8
	dodoc README.md FAQ

	dodir /etc/init.d
	newinitd "${FILESDIR}"/pound.init-1.9 pound

	insinto /etc
	newins "${FILESDIR}"/pound-2.2.cfg pound.cfg
}

pkg_postinst() {
	elog "No demo-/sample-configfile is included in the distribution -"
	elog "read the man-page for more info."
	elog "A sample (localhost:8888 -> localhost:80) for gentoo is given in \"/etc/pound.cfg\"."
	echo
	ewarn "You will have to upgrade you configuration file, if you are"
	ewarn "upgrading from a version <= 2.0."
	echo
	ewarn "The 'WebDAV' config statement is no longer supported!"
	ewarn "Please adjust your configuration, if necessary."
	echo
}
