# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="An HTTP/HTTPS reverse-proxy and load-balancer"
HOMEPAGE="https://github.com/graygnuorg/pound"
SRC_URI="https://github.com/graygnuorg/pound/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="amd64 ~hppa ~ppc x86"

RESTRICT='mirror'

DEPEND="
	acct-group/nogroup
	acct-user/nobody
	dev-libs/openssl:=
	dev-libs/libpcre2:=
"
RDEPEND="
	${DEPEND}
	virtual/libcrypt:=
"

QA_CONFIG_IMPL_DECL_SKIP=(
	PCRE2regcomp	# Detecting broken Debian patched PCRE2
)

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myconf=(
		--with-owner=nobody
		--with-group=nogroup
	)
	econf ${myconf[@]}
}

src_install() {
	default

	mv "${ED}"/usr/bin/poundctl "${ED}"/usr/sbin/
	rmdir "${ED}"/usr/bin

	newinitd "${FILESDIR}/pound.init" pound
	insinto /etc
	newins "${FILESDIR}"/pound-2.2.cfg pound.cfg
}

pkg_postinst() {
	elog "A sample (localhost:8888 -> localhost:80) configuration for gentoo"
	elog "has been deployed to '/etc/pound.cfg'."
}
