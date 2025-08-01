# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic systemd

DESCRIPTION="Powerful replacement for inetd"
HOMEPAGE="https://github.com/xinetd-org/xinetd https://github.com/openSUSE/xinetd"
SRC_URI="https://github.com/openSUSE/xinetd/releases/download/${PV}/${P}.tar.xz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="perl rpc selinux systemd tcpd"

DEPEND="
	rpc? ( net-libs/libtirpc:= )
	selinux? ( sys-libs/libselinux )
	tcpd? ( >=sys-apps/tcp-wrappers-7.6-r2 )
"
RDEPEND="
	${DEPEND}
	perl? ( dev-lang/perl )
"
BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}"/${PN}-2.3.15.4-0001-configure.ac-use-AC_USE_SYSTEM_EXTENSIONS.patch
	"${FILESDIR}"/${PN}-2.3.15.4-0002-redirect-drop-deprecated-sys-signal.h-include.patch
)

src_prepare() {
	default

	sed -i \
		-e 's:/usr/bin/kill:/bin/kill:' \
		"contrib/${PN}.service" || die

	# Crashes with "Illegal instruction" error...
	filter-flags -fisolate-erroneous-paths-attribute

	eautoreconf
}

src_configure() {
	# bug #943856
	append-cflags -std=gnu17

	econf \
		$(use_with tcpd libwrap) \
		$(use_with selinux labeled-networking) \
		$(use_with rpc) \
		--with-loadavg
}

src_install() {
	default

	use perl || rm -f "${ED}"/usr/sbin/xconv.pl

	newinitd "${FILESDIR}"/xinetd.rc6 xinetd
	newconfd "${FILESDIR}"/xinetd.confd xinetd
	use systemd && systemd_dounit "contrib/${PN}.service"

	newdoc contrib/xinetd.conf xinetd.conf.dist.sample
	dodoc README.md CHANGELOG
}
