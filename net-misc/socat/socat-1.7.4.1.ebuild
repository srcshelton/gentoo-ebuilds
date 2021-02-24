# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic toolchain-funcs

MY_P=${P/_beta/-b}
DESCRIPTION="Multipurpose relay (SOcket CAT)"
HOMEPAGE="http://www.dest-unreach.org/socat/ https://repo.or.cz/socat.git"
SRC_URI="http://www.dest-unreach.org/socat/download/${MY_P}.tar.bz2"
S="${WORKDIR}/${MY_P}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~m68k ~mips ppc ppc64 ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos"
IUSE="bindist doc ipv6 libressl readline ssl tcpd tools"

DEPEND="
	acct-group/socat
	ssl? (
		!libressl? ( dev-libs/openssl:0= )
		libressl? ( dev-libs/libressl:= )
	)
	readline? ( sys-libs/readline:= )
	tcpd? ( sys-apps/tcp-wrappers )
"
RDEPEND="${DEPEND}"

# Tests are a large bash script
# Hard to disable individual tests needing network or privileges
RESTRICT="
	test
	ssl? ( readline? ( bindist ) )
"

DOCS=( EXAMPLES SECURITY )

pkg_setup() {
	# bug #587740
	if use readline && use ssl; then
		elog "You are enabling both readline and openssl USE flags, the licenses"
		elog "for these packages conflict. You may not be able to legally"
		elog "redistribute the resulting binary."
	fi
}

src_configure() {
	filter-flags '-Wno-error*' #293324
	tc-export AR

	econf \
		$(use_enable ssl openssl) \
		$(use_enable readline) \
		$(use_enable ipv6 ip6) \
		$(use_enable tcpd libwrap)
}

src_install() {
	default

	fowners :socat /usr/bin/socat
	fperms 0750 /usr/bin/socat

	use tools || rm "${ED}/usr/bin/filan" "${ED}/usr/bin/procan"

	if use doc; then
		docinto html
		dodoc doc/*.html doc/*.css
	fi
}

# vi: set diffopt=iwhite,filler:
