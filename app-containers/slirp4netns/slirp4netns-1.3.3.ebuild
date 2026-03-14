# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools linux-info

DESCRIPTION="User-mode networking for unprivileged network namespaces"
HOMEPAGE="https://github.com/rootless-containers/slirp4netns"
SRC_URI="https://github.com/rootless-containers/slirp4netns/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~riscv"
RESTRICT="mirror test"

DEPEND="
	dev-libs/glib:2=
	dev-libs/libpcre:=
	>=net-libs/libslirp-4.9.1:=
	>=sys-libs/libseccomp-2.5.3:=
	sys-libs/libcap:=
"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/${PN}-1.2.1-varrun.patch"
)

pkg_setup() {
	local CONFIG_CHECK="~TUN"
	local ERROR_TUN="CONFIG_TUN: is mandatory"

	linux-info_pkg_setup
}

src_prepare() {
	default

	# Respect AR variable for bug 722162.
	sed -e 's|^AC_PROG_CC$|AC_DEFUN([AC_PROG_AR], [AC_CHECK_TOOL(AR, ar, :)])\nAC_PROG_AR\n\0|' \
		-i configure.ac || die
	eautoreconf
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "You need to have the 'tun' kernel module loaded in order for"
		elog "slirp4netns to work"
	fi
}
