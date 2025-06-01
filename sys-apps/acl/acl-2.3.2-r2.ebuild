# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic libtool usr-ldscript multilib-minimal

DESCRIPTION="Access control list utilities, libraries, and headers"
HOMEPAGE="https://savannah.nongnu.org/projects/acl"
SRC_URI="mirror://nongnu/${PN}/${P}.tar.xz"

LICENSE="LGPL-2.1+ GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"
IUSE="nls static-libs"

RDEPEND="
	>=sys-apps/attr-2.4.47-r1[${MULTILIB_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="nls? ( sys-devel/gettext )"

src_prepare() {
	default

	# bug #580792
	elibtoolize
}

multilib_src_configure() {
	# Filter out -flto flags as they break getfacl/setfacl binaries (bug #667372)
	filter-lto

	if use amd64 || use x86 || use amd64-linux || use x86-linux; then
		# With -z,max-page-size=0x200000 set (for x86_64), tiny binaries bloat
		# to 6.1MB each :o
		#
		filter-ldflags *-z,max-page-size=*
	fi

	local myeconfargs=(
		--bindir="${EPREFIX}"/bin
		--libexecdir="${EPREFIX}"/usr/$(get_libdir)
		--enable-largefile
		$(use_enable static-libs static)
		$(use_enable nls)
	)

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_test() {
	# Tests call native binaries with an LD_PRELOAD wrapper
	# bug #772356
	multilib_is_native_abi && default
}

multilib_src_install() {
	default

	# Move shared libs to /
	gen_usr_ldscript -a acl
}

multilib_src_install_all() {
	if ! use static-libs ; then
		find "${ED}" -type f -name "*.la" -delete || die
	fi
}
