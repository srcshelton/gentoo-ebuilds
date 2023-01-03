# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit pam toolchain-funcs

DESCRIPTION="Create per-user private temporary directories during login"
HOMEPAGE="http://www.openwall.com/pam/"
SRC_URI="http://www.openwall.com/pam/modules/${PN}/${P}.tar.gz"

LICENSE="BSD-2" # LICENSE file says "heavily cut-down 'BSD license'"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="+prevent-removal selinux"

RDEPEND="sys-libs/pam
	selinux? ( sys-libs/libselinux )"

DEPEND="${RDEPEND}
	prevent-removal? ( sys-kernel/linux-headers )"

src_prepare() {
	default
	eapply "${FILESDIR}"/${P}-e2fsprogs-libs.patch

	# #define PRIVATE_PREFIX	"/tmp/.private"
	sed -i pam_mktemp.c \
		-e '/define PRIVATE_PREFIX/s|".*"|"/var/tmp/.private"|' ||
	die "sed failed: ${?}"
}

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS} -fPIC" \
		LDFLAGS="${LDFLAGS} --shared -Wl,--version-script,\$(MAP)" \
		USE_SELINUX="$(use selinux && echo 1 || echo 0)" \
		USE_APPEND_FL="$(use prevent-removal && echo 1 || echo 0)"
}

src_install() {
	dopammod pam_mktemp.so
	dodoc README
}
