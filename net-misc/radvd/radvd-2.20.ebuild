# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools readme.gentoo-r1 systemd toolchain-funcs

DESCRIPTION="Linux IPv6 Router Advertisement Daemon"
HOMEPAGE="https://radvd-project.github.io/"
SRC_URI="https://github.com/radvd-project/radvd/releases/download/v${PV}/${P}.tar.xz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~hppa ppc ppc64 ~riscv sparc x86"
IUSE="selinux systemd test"
RESTRICT="!test? ( test )"

BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig"
DEPEND="test? ( dev-libs/check )"
RDEPEND="
	acct-group/radvd
	acct-user/radvd
	dev-libs/libbsd
	selinux? ( sec-policy/selinux-radvd )"

PATCHES=(
)

src_prepare() {
	default

	# Drop once clang16 patch is in a release
	eautoreconf
}

src_configure() {
	# Needs reentrant functions (yyset_in), bug #884375
	export LEX=flex

	econf --with-pidfile=/var/run/radvd/radvd.pid \
		--with-systemdsystemunitdir=no \
		$(use_with test check)
}

src_compile() {
	emake AR="$(tc-getAR)"
}

src_install() {
	HTML_DOCS=( INTRO.html )
	default
	dodoc radvd.conf.example

	newinitd "${FILESDIR}"/${PN}-2.19.init ${PN}
	newconfd "${FILESDIR}"/${PN}.conf ${PN}

	use systemd && systemd_dounit "${FILESDIR}"/${PN}.service

	DISABLE_AUTOFORMATTING=1
	local DOC_CONTENTS="Please create a configuration file ${EPREFIX}/etc/radvd.conf.
See ${EPREFIX}/usr/share/doc/${PF} for an example.

grsecurity users should allow a specific group to read /proc
and add the radvd user to that group, otherwise radvd may
segfault on startup."
	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog
}
