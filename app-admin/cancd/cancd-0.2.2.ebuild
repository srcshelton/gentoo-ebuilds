# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MY_HASH='0f7e764aa8f86a5b4ef0bdafdbc65825ce167de8'
DESCRIPTION="CA NetConsole Daemon"
HOMEPAGE="https://lwn.net/Articles/479674/"
SRC_URI="https://git.kernel.org/pub/scm/linux/kernel/git/joern/cancd.git/snapshot/cancd-${MY_HASH}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

RDEPEND="
	acct-group/cancd
	acct-user/cancd
"

PATCHES=(
	"${FILESDIR}/${P}-cancd.c.patch"
)

S="${WORKDIR}/cancd-${MY_HASH}"

src_prepare() {
	default

	# slight makefile cleanup
	sed \
		-e '/^CFLAGS/s,-g,,' \
		-e '/rm cancd cancd.o/s,rm,rm -f,' \
		-i Makefile || die
	#	-e '/^CFLAGS/s,-O2,-Wall -W -Wextra -Wundef -Wendif-labels -Wshadow -Wpointer-arith -Wbad-function-cast -Wcast-qual -Wcast-align -Wwrite-strings -Wconversion -Wsign-compare -Waggregate-return -Wstrict-prototypes -Wredundant-decls -Wunreachable-code -Wlong-long,' \
}

src_install() {
	dosbin cancd

	newinitd "${FILESDIR}"/cancd-init.d-r1 cancd
	newconfd "${FILESDIR}"/cancd-conf.d-r1 cancd
	newinitd "${FILESDIR}"/netconsole-init.d netconsole
	newconfd "${FILESDIR}"/netconsole-conf.d netconsole
}
