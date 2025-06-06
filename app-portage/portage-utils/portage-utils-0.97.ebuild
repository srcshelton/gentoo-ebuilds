# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic toolchain-funcs

DESCRIPTION="Small and fast Portage helper tools written in C"
HOMEPAGE="https://wiki.gentoo.org/wiki/Portage-utils"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3 autotools
	EGIT_REPO_URI="https://anongit.gentoo.org/git/proj/portage-utils.git"
else
	SRC_URI="https://dev.gentoo.org/~grobian/distfiles/${P}.tar.xz"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="clang openmp +qmanifest static"

COMMON_DEPEND="
	qmanifest? (
		!static? (
			app-crypt/gpgme:=
			app-crypt/libb2:=
			sys-libs/zlib:=
		)
	)"
BDEPEND="
	virtual/pkgconfig
	openmp? (
		clang? ( llvm-core/clang-runtime:*[openmp] )
		!clang? ( sys-devel/gcc:*[openmp] )
	)"
DEPEND="${COMMON_DEPEND}
	virtual/os-headers
	qmanifest? (
		static? (
			app-crypt/gpgme[static-libs]
			app-crypt/libb2[static-libs]
			sys-libs/zlib[static-libs]
		)
	)"
RDEPEND="${COMMON_DEPEND}
	openmp? (
		clang? ( llvm-runtimes/openmp )
		!clang? ( sys-devel/gcc:*[openmp] )
	)"

# bug #898362, gnulib explicit checks
QA_CONFIG_IMPL_DECL_SKIP=(
	"MIN"
	"unreachable"
	"alignof"
	"static_assert"
)

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_prepare() {
	default
	[[ ${PV} == *9999 ]] && eautoreconf
}

src_configure() {
	use static && append-ldflags -static

	econf \
		--disable-maintainer-mode \
		--with-eprefix="${EPREFIX}" \
		$(use_enable qmanifest) \
		$(use_enable openmp)
}
