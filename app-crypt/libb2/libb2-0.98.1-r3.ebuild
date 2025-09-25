# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic toolchain-funcs multilib-minimal

DESCRIPTION="C library providing BLAKE2b, BLAKE2s, BLAKE2bp, BLAKE2sp"
HOMEPAGE="https://github.com/BLAKE2/libb2"
GITHASH="73d41c8255a991ed2adea41c108b388d9d14b449"
SRC_URI="https://github.com/BLAKE2/libb2/archive/${GITHASH}.tar.gz -> ${P}.tar.gz"

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="-clang native-cflags openmp static-libs"

# We can't call toolchain-funcs.eclass functions here, and we don't know
# whether $CC is gcc or clang (as the USE-flag only sets the runtime
# dependencies), so the least-bad option may be to over-extend the BDEPEND
# requirements and at least not break :o
#
# ... but we can check this later, as we do for openmp/graphite USE flags.
#
BDEPEND="
	openmp? (
		clang? ( llvm-runtimes/clang-runtime:*[openmp] )
		!clang? ( >=sys-devel/gcc-4.2:*[openmp] )
	)
"
#BDEPEND="
#	openmp? ( || (
#		sys-devel/gcc:*[openmp]
#		llvm-runtimes/clang-runtime:*[openmp]
#	) )
#"
RDEPEND="
	openmp? (
		clang? ( llvm-runtimes/openmp:= )
		!clang? ( >=sys-devel/gcc-4.2:*[openmp] )
	)
"

S="${WORKDIR}/${PN}-${GITHASH}"

PATCHES=( "${FILESDIR}/${P}-distcc.patch" )

# We don't need these functions given the 'openmp?' BDEPEND stanza above... and
# this form breaks any multi-package merge where 'gcc' is installed with openmp
# support in the same operation as - but prior to - building libb2...
#
#pkg_pretend() {
#	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
#}

pkg_pretend() {
	if [[ "${MERGE_TYPE:-}" != 'binary' ]]; then
		if tc-is-gcc; then
			if use clang; then
				die "${P} is using clang dependencies but being built with gcc"
			fi
		elif tc-is-clang; then
			if ! use clang; then
				die "${P} is using gcc dependencies but being built with clang"
			fi
		fi
	fi
}

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_prepare() {
	default

	# fix bashism
	sed -i -e 's/ == / = /' configure.ac || die

	# https://github.com/BLAKE2/libb2/pull/28
	echo 'libb2_la_LDFLAGS = -no-undefined' >> src/Makefile.am || die

	# make memset_s available
	[[ ${CHOST} == *-solaris* ]] && append-cppflags -D__STDC_WANT_LIB_EXT1__=1

	eautoreconf  # upstream doesn't make releases
}

multilib_src_configure() {
	ECONF_SOURCE=${S} \
	econf \
		$(use_enable static-libs static) \
		$(use_enable native-cflags native) \
		$(use_enable openmp)
}

do_make() {
	# respect our CFLAGS when native-cflags is not in effect
	local openmp=$(use openmp && echo -fopenmp)
	emake $(use native-cflags && echo no)CFLAGS="${CFLAGS} ${openmp}" "$@"
}

multilib_src_compile() {
	do_make
}

multilib_src_test() {
	do_make check
}

multilib_src_install_all() {
	einstalldocs
	find "${ED}" -name '*.la' -type f -delete || die
}
