# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit edo flag-o-matic toolchain-funcs

MY_P=${P/_beta/-b}
DESCRIPTION="Multipurpose relay (SOcket CAT)"
HOMEPAGE="http://www.dest-unreach.org/socat/ https://repo.or.cz/socat.git"
SRC_URI="http://www.dest-unreach.org/socat/download/${MY_P}.tar.bz2"
S="${WORKDIR}/${MY_P}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos"
IUSE="doc ipv6 readline ssl tcpd tools"

DEPEND="
	acct-group/socat
	ssl? ( >=dev-libs/openssl-3:= )
	readline? ( sys-libs/readline:= )
	tcpd? ( sys-apps/tcp-wrappers )
"
RDEPEND="${DEPEND}"

DOCS=( EXAMPLES SECURITY )

src_configure() {
	# bug #293324
	filter-flags '-Wno-error*'

	tc-export AR

	local myeconfargs=(
		$(use_enable ssl openssl)
		$(use_enable readline)
		$(use_enable ipv6 ip6)
		$(use_enable tcpd libwrap)
	)

	econf "${myeconfargs[@]}"
}

src_test() {
	# Most tests are skipped because they need network access or a TTY
	# Some are for /dev permissions probing (bug #940740)
	# 518 519 need extra permissions
	edo ./test.sh -v --expect-fail 13,15,87,217,311,313,370,388,410,466,478,518,519,528
}

src_install() {
	default

	if use doc; then
		docinto html
		dodoc doc/*.html doc/*.css
	fi

	fowners :socat /usr/bin/socat
	fperms 0750 /usr/bin/socat

	use tools || rm "${ED}/usr/bin/filan" "${ED}/usr/bin/procan"

	if use elibc_musl; then
		QA_CONFIG_IMPL_DECL_SKIP=( getprotobynumber_r )
	fi
}

# vi: set diffopt=filler,iwhite:
