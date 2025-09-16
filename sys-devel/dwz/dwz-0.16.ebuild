# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="DWARF optimization and duplicate removal tool"
HOMEPAGE="https://sourceware.org/dwz"
if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://sourceware.org/git/dwz.git"
	inherit git-r3
else
	SRC_URI="https://sourceware.org/ftp/dwz/releases/${P}.tar.xz"
	S="${WORKDIR}/${PN}"

	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~sparc x86"
fi

LICENSE="GPL-2+ GPL-3+"
SLOT="0"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-libs/elfutils
	dev-libs/xxhash
	elibc_musl? (
		>=sys-libs/error-standalone-2.0
		sys-libs/obstack-standalone
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	sys-devel/binutils
	sys-devel/binutils-config
	virtual/pkgconfig
	test? (
		dev-debug/gdb
		dev-libs/elfutils[utils]
		dev-util/dejagnu
	)
"

PATCHES=(
	"${FILESDIR}/${PN}-0.15-readelf.patch"
)

src_prepare() {
	default

	export LANG=C LC_ALL=C  # grep find nothing for non-ascii locales

	# It seems that sys-devel/dwz can be being built in a situation where
	# sys-devel/binutils-config is not already installed, and if this is the
	# case then even with that package present as a BDEPEND, it can fail to
	# locate an active profile :o
	#
	# This, however, is likely a sandbox violation :(
	#
	#binutils-config latest
	#. /etc/profile

	local current_binutils_path="$(binutils-config -B)" || die
	export READELF="${current_binutils_path}/readelf"

	if ! [[ -x "${READELF}" ]]; then
		die "Usable readelf could not be found"
	fi

	tc-export PKG_CONFIG READELF

	export LIBS="-lelf"
	if use elibc_musl; then
		export CFLAGS="${CFLAGS} $(${PKG_CONFIG} --cflags obstack-standalone error-standalone)"
		export LIBS="${LIBS} $(${PKG_CONFIG} --libs obstack-standalone error-standalone)"
	fi

	tc-export CC
}

src_compile() {
	# These variables are exported, do they need to be repeated here?
	emake CFLAGS="${CFLAGS}" LIBS="${LIBS}" srcdir="${S}" prefix="${EPREFIX}/usr"
}

src_test() {
	emake CFLAGS="${CFLAGS}" LIBS="${LIBS}" srcdir="${S}" prefix="${EPREFIX}/usr" check
}

src_install() {
	# Why are we passing CFLAGS to the 'install' call to make?
	emake DESTDIR="${D}" CFLAGS="${CFLAGS}" LIBS="${LIBS}" srcdir="${S}" prefix="${EPREFIX}/usr" install
}
