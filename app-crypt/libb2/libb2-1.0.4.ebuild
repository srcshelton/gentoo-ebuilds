# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic toolchain-funcs multilib-minimal

DESCRIPTION="C library providing BLAKE2b, BLAKE2s, BLAKE2bp, BLAKE2sp"
HOMEPAGE="https://github.com/BLAKE2/libb2"
GITHASH="643decfbf8ae600c3387686754d74c84144950d1"
SRC_URI="https://github.com/BLAKE2/libb2/archive/${GITHASH}.tar.gz -> ${P}.tar.gz"

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="-clang native-cflags openmp static-libs"

# We can't call toolchain-funcs.eclass functions here, and we don't know
# whether $CC is gcc or clang (as the USE-flag only sets the runtime
# dependencies), so the least-bad option may be to over-extend the BDEPEND
# requirements and at least not break :o
#
# ... but we can check this later, as we do for openmp/graphite USE flags.
#
BDEPEND="
	clang? (
		llvm-core/clang
		llvm-core/lld
		openmp? ( llvm-runtimes/clang-runtime:*[openmp] )
	)
	!clang? (
		openmp? ( sys-devel/gcc:*[openmp] )
	)
"
RDEPEND="
	openmp? (
		clang? ( llvm-runtimes/openmp:= )
		!clang? ( sys-devel/gcc:*[openmp] )
	)
"

PATCHES=(
	"${FILESDIR}/${P}-m4.patch"
)

S="${WORKDIR}/${PN}-${GITHASH}"

# We don't need these functions given the 'openmp?' BDEPEND stanza above... and
# this form breaks any multi-package merge where 'gcc' is installed with openmp
# support in the same operation as - but prior to - building libb2...
#
#pkg_pretend() {
#	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
#}

pkg_pretend() {
	if tc-is-gcc; then
		if use clang; then
			ewarn "${P} is using clang dependencies but being built with gcc"
		fi
	elif tc-is-clang; then
		if ! use clang; then
			ewarn "${P} is using gcc dependencies but being built with clang"
		fi
	fi
}

pkg_setup() {
	# If we're attempting to build with a non-matching toolchain, then let's
	# see whether we can correct this here: all the dependencies should already
	# be catered-for, we just need to ensure we have the appropriate
	# environment!
	if ! use clang; then
		if ! tc-is-gcc; then
			ewarn "Switching to compiler 'gcc' ..."

			CPP="gcc -E"
			AS="as"
			CC="gcc"
			CXX="g++"
			LD="ld"
			AR="ar"
			NM="nm"
			RANLIB="ranlib"
			OBJCOPY="objcopy"
			OBJDUMP="objdump"
			READELF="readelf"
			STRIP="strip"

			tc-export
			export CPP AS CC CXX LD AR NM OBJCOPY OBJDUMP READELF STRIP RANLIB

			COMMON_FLAGS="-O2 -march=native -pipe$(usex openmp ' -fopenmp' '')" # -flto[=$N]
			CFLAGS="${COMMON_FLAGS}"
			CXXFLAGS="${COMMON_FLAGS}"
			LDFLAGS="-Wl,-O1 -Wl,--as-needed"
		fi
	else # use clang; then
		if ! tc-is-clang; then
			ewarn "Switching to compiler 'clang' ..."

			CPP="clang-cpp" # necessary for at least xorg-server
			AS="clang -c"
			CC="clang"
			CXX="clang++"
			LD="ld.lld"
			AR="llvm-ar"
			NM="llvm-nm"
			OBJCOPY="llvm-objcopy"
			OBJDUMP="llvm-objdump"
			READELF="llvm-readelf"
			STRIP="llvm-strip"
			RANLIB="llvm-ranlib"

			tc-export
			export CPP AS CC CXX LD AR NM OBJCOPY OBJDUMP READELF STRIP RANLIB

			# TODO: Process GCC CFLAGS to build LLVM equivalent: extract -march
			#       or -mcpu, map graphite to polly, change -Ofast to
			#       -O3 -ffast-math.

			COMMON_FLAGS="-O2 -march=native -pipe$(usex openmp ' -fopenmp' '')" # -flto=thin
			# Loop-nest Optimisation - requires out-of-tree sys-devel/polly:
			#COMMON_FLAGS="${COMMON_FLAGS} $( printf '%s\n' \
			#		-fplugin=LLVMPolly.so \
			#		-mllvm=-polly \
			#		-mllvm=-polly-vectorizer=stripmine \
			#		-mllvm=-polly-omp-backend=LLVM \
			#		-mllvm=-polly-parallel \
			#		-mllvm=-polly-num-threads=9 \
			#		-mllvm=-polly-scheduling=dynamic
			#	)
			CFLAGS="${COMMON_FLAGS}"
			CXXFLAGS="${COMMON_FLAGS}"

			LDFLAGS="-Wl,-O2 -Wl,--as-needed"
			# No need to set this, clang-common can handle this based on chosen
			# USE flags...
			#LDFLAGS="${LDFLAGS} -fuse-ld=lld -rtlib=compiler-rt -unwindlib=libunwind -Wl,--as-needed"
		fi
	fi

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
