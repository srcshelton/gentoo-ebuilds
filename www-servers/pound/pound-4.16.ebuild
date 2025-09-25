# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="An HTTP/HTTPS reverse-proxy and load-balancer"
HOMEPAGE="https://github.com/graygnuorg/pound"
SRC_URI="https://github.com/graygnuorg/pound/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="amd64 ~hppa x86"
IUSE="tcmalloc test"

RESTRICT="mirror
	!test? ( test )"

DEPEND="
	acct-group/nogroup
	acct-user/nobody
	dev-libs/libpcre2:=
	dev-libs/openssl:=
	tcmalloc? ( dev-util/google-perftools )
"
RDEPEND="
	${DEPEND}
	virtual/libcrypt:=
"
BDEPEND="
	test? (
		dev-lang/perl
		dev-perl/IO-FDPass
		dev-perl/IO-Socket-SSL
		dev-perl/JSON
		dev-perl/Net-SSLeay
	)
"

src_configure() {
	local myconf=(
		--disable-dynamic-backends
		--disable-hoard
		--enable-pcre
		$(use_enable tcmalloc)
		--with-owner=nobody
		--with-group=nogroup
	)
	econf "${myconf[@]}"
}

src_install() {
	default

	mv "${ED}"/usr/bin/poundctl "${ED}"/usr/sbin/
	rmdir "${ED}"/usr/bin

	newinitd "${FILESDIR}/pound.init" pound
	insinto /etc
	newins "${FILESDIR}/pound-2.2.cfg" pound.cfg
}

pkg_postinst() {
	elog "A sample (localhost:8888 -> localhost:80) configuration for gentoo"
	elog "has been deployed to '/etc/pound.cfg'."
}
