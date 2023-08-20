# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="An HTTP/HTTPS reverse-proxy and load-balancer"
HOMEPAGE="https://github.com/graygnuorg/pound"
SRC_URI="https://github.com/graygnuorg/${PN}/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ~hppa ~ppc x86"

IUSE="-pcre +pcre2"  # test
REQUIRED_USE="?? ( pcre pcre2 )"

RESTRICT='mirror'

DEPEND="
	acct-group/nogroup
	acct-user/nobody
	dev-libs/openssl:=
	pcre? ( dev-libs/libpcre:= )
	pcre2? ( dev-libs/libpcre2:= )
"
# dev-perl/IO-FDPass isn't packaged :(
#	test? ( dev-perl/IO-FDPass dev-perl/IO-Socket-SSL dev-perl/Net-SSLeay )
RDEPEND="${DEPEND}"

DOCS=( README NEWS )

src_configure() {
	local -a args=()

	args+=(
		--enable-pthread-cancel-probe
		#--with-maxbuf=4096
		--with-owner=nobody
		--with-group=nogroup
	)

	if use pcre; then
		args+=( --enable-pcreposix=pcre1 )
	elif use pcre2; then
		args+=( --enable-pcreposix )
	else
		args+=( --disable-pcreposix )
	fi

	econf "${args[@]}"
}

src_install() {
	default

	mv "${ED}"/usr/bin/poundctl "${ED}"/usr/sbin/
	rmdir "${ED}"/usr/bin

	dodir /etc/init.d
	newinitd "${FILESDIR}"/pound.init-1.9 pound

	insinto /etc
	newins "${FILESDIR}"/pound-2.2.cfg pound.cfg
}

pkg_postinst() {
	elog "A sample (localhost:8888 -> localhost:80) configuration for gentoo"
	elog "has been deployed to '/etc/pound.cfg'."
}
