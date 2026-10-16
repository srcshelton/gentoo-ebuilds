# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit cmake-multilib crossdev flag-o-matic llvm.org llvm-utils python-any-r1 toolchain-funcs

DESCRIPTION="C++ runtime stack unwinder from LLVM"
HOMEPAGE="https://llvm.org/docs/ExceptionHandling.html"

LICENSE="Apache-2.0-with-LLVM-exceptions || ( UoI-NCSA MIT )"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~loong ~mips ~ppc ppc64 ~riscv ~sparc x86 ~arm64-macos ~x64-macos"
# The USE flag 'cet' is problematic due to overloading: on x86 it simply means
# the Control-Flow Enforcement hardware feature introduced with Intel
# Tiger Lake and AMD Zen 3, supported from gcc 8 and clang 7.  On Intel, 'cet'
# is actually a group term for Indirect Branch Tracking ('ibt') and
# Shadow Stack ('shstk').
#
# Similarly, on arm64 'cet' can mean Pointer Authentication ('pac') and
# Branch Target Identification ('bti') - but these are activated on this
# platform with the same compiler argument ('-fcf-protection=...') and so the
# Gentoo maintainers reasonably enough combined these into the 'cet' USE flag
# which determines the enablement of these platform-specific features - and
# 'cet' is now enabled by default.
#
# The problem, however, is that llvm-runtimes/libunwind takes 'cet' to
# literally mean Intel's 'ibt'/'shstk' implementation, and fails to configure
# if these facilities aren't available.  Which is obviously problematic on
# arm64, where 'cet' is (correctly) enabled by default but where these tests
# cannot pass.
#
# We can gate the feature with:
#
#   REQUIRED_USE="cet? ( || ( amd64 arm arm64 x86 x64-macos ) )"
#
# ... but this still requires the package's USE flags to have 'cet' removed,
# rather than making this support architecture-specific.  And we could ignore
# the 'cet' flag on arm64 (with a warning), but this would still result in a
# build with the 'cet' flag set but no 'cet'-like functionality, potentially
# giving a false sense of security.
#
# Further, there is additional linkage that LLVM/clang (via
# llvm-core/clang-common) needs to be built with 'USE=cet' otherwise this build
# will fail regardless of the hardware.
#
IUSE="cet +clang debug static-libs test"
REQUIRED_USE="test? ( clang )
	cet? ( || ( amd64 x86 x64-macos ) )"
RESTRICT="!test? ( test )"

RDEPEND="
	!sys-libs/libunwind
"
DEPEND="
	llvm-core/llvm:${LLVM_MAJOR}
	llvm-runtimes/compiler-rt:${LLVM_MAJOR}
"
BDEPEND="
	clang? (
		llvm-core/clang:${LLVM_MAJOR}
		llvm-core/clang-linker-config:${LLVM_MAJOR}
		llvm-runtimes/clang-rtlib-config:${LLVM_MAJOR}
	)
	!test? (
		${PYTHON_DEPS}
	)
	test? (
		$(python_gen_any_dep 'dev-python/lit[${PYTHON_USEDEP}]')
	)
"
BDEPEND="${BDEPEND}
	clang? (
		cet? ( llvm-core/clang-common:${LLVM_MAJOR}[cet(-)] )
	)
"

LLVM_COMPONENTS=( runtimes libunwind libcxx llvm/cmake cmake )
LLVM_TEST_COMPONENTS=( libc libcxxabi llvm/utils/llvm-lit )
llvm.org_set_globals

python_check_deps() {
	use test || return 0
	python_has_version "dev-python/lit[${PYTHON_USEDEP}]"
}

test_compiler() {
	target_is_not_host && return
	local compiler=${1}
	shift
	${compiler} ${CFLAGS} ${LDFLAGS} "${@}" -o /dev/null -x c - \
		<<<'int main() { return 0; }' &>/dev/null
}

multilib_src_configure() {
	local libdir="$(get_libdir)" cet='OFF' gcs='OFF'

	use cet && cet='ON'

	if use arm || use arm64; then
		if use clang; then
			if use cet; then
				cet='OFF'
				gcs='ON'
			fi
		fi
	fi

	if use arm64; then
		filter-flags -mbranch-protection=standard

		if use clang || tc-is-clang; then
			# error: value evaluated as 4611686018427387889 is out of range.
			ewarn "Reducing optimisations on ${ARCH} due to build failures ..."

			strip-flags

			filter-flags -ffinite-math-only
			append-flags -fno-finite-math-only

			filter-flags -ffast-math
			append-flags -fno-fast-math

			strip-unsupported-flags
		fi
	fi

	# https://github.com/llvm/llvm-project/issues/56825
	# also separately bug #863917
	filter-lto

	# Workaround for bgo #961153.
	# TODO: Fix the multilib.eclass, so it sets CTARGET properly.
	if ! is_crosspkg; then
		export CTARGET=${CHOST}
	fi

	if use clang; then
		llvm_prepend_path -b "${LLVM_MAJOR}"

		local -x CC=${CTARGET}-clang-${LLVM_MAJOR}
		local -x CXX=${CTARGET}-clang++-${LLVM_MAJOR}
		strip-unsupported-flags

		# The full clang configuration might not be ready yet. Use the partial
		# configuration files that are guaranteed to exist even during initial
		# installations and upgrades.
		local flags=(
			--config="${ESYSROOT}"/etc/clang/"${LLVM_MAJOR}"/gentoo-{rtlib,linker}.cfg
		)
		local -x CFLAGS="${CFLAGS} ${flags[@]}"
		local -x CXXFLAGS="${CXXFLAGS} ${flags[@]}"
		local -x LDFLAGS="${LDFLAGS} ${flags[@]}"
	fi

	# Check whether C compiler runtime is available.
	if ! test_compiler "$(tc-getCC)"; then
		local nolib_flags=( -nodefaultlibs -lc )
		if test_compiler "$(tc-getCC)" "${nolib_flags[@]}"; then
			local -x LDFLAGS="${LDFLAGS} ${nolib_flags[*]}"
			ewarn "${CC} seems to lack runtime, trying with ${nolib_flags[*]}"
		elif test_compiler "$(tc-getCC)" "${nolib_flags[@]}" -nostartfiles; then
			# Avoiding -nostartfiles earlier on for bug #862540,
			# and set available entry symbol for bug #862798.
			nolib_flags+=( -nostartfiles -e main )
			local -x LDFLAGS="${LDFLAGS} ${nolib_flags[*]}"
			ewarn "${CC} seems to lack runtime, trying with ${nolib_flags[*]}"
		fi
	fi
	# Check whether C++ standard library is available,
	local nostdlib_flags=( -nostdlib++ )
	if ! test_compiler "$(tc-getCXX)" &&
		test_compiler "$(tc-getCXX)" "${nostdlib_flags[@]}"
	then
		local -x LDFLAGS="${LDFLAGS} ${nostdlib_flags[*]}"
		ewarn "${CXX} seems to lack runtime, trying with ${nostdlib_flags[*]}"
	fi

	# link to compiler-rt
	# https://github.com/gentoo/gentoo/pull/21516
	local use_compiler_rt=OFF
	[[ $(tc-get-c-rtlib) == compiler-rt ]] && use_compiler_rt=ON

	# Respect upstream build type assumptions (bug #910436) where they do:
	# -DLIBUNWIND_ENABLE_ASSERTIONS=ON =>
	#       -DCMAKE_BUILD_TYPE=DEBUG  => -UNDEBUG
	#       -DCMAKE_BUILD_TYPE!=debug => -DNDEBUG
	# -DLIBUNWIND_ENABLE_ASSERTIONS=OFF =>
	#       -UNDEBUG
	# See also https://github.com/llvm/llvm-project/issues/86#issuecomment-1649668826.
	use debug || append-cppflags -DNDEBUG

	local mycmakeargs=(
		-DLLVM_ROOT="${ESYSROOT}/usr/lib/llvm/${LLVM_MAJOR}"

		-DCMAKE_C_COMPILER_TARGET="${CTARGET}"
		-DCMAKE_CXX_COMPILER_TARGET="${CTARGET}"
		-DPython3_EXECUTABLE="${PYTHON}"
		-DLLVM_ENABLE_RUNTIMES="libunwind"
		-DLLVM_LIBDIR_SUFFIX=${libdir#lib}
		-DLLVM_INCLUDE_TESTS=OFF
		-DLIBUNWIND_ENABLE_CET=${cet}
		-DLIBUNWIND_ENABLE_GCS=${gcs}
		-DLIBUNWIND_ENABLE_ASSERTIONS=$(usex debug)
		-DLIBUNWIND_ENABLE_STATIC=$(usex static-libs)
		-DLIBUNWIND_INCLUDE_TESTS=$(usex test)
		-DLIBUNWIND_INSTALL_HEADERS=ON

		# cross-unwinding increases unwinding footprint (to account
		# for the worst case) and causes some breakage on AArch64
		# https://github.com/llvm/llvm-project/issues/152549
		-DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF

		# avoid dependency on libgcc_s if compiler-rt is used
		-DLIBUNWIND_USE_COMPILER_RT=${use_compiler_rt}
	)
	if is_crosspkg; then
		mycmakeargs+=(
			# Without this, the compiler will compile a test program
			# and fail due to no builtins.
			-DCMAKE_C_COMPILER_WORKS=1
			-DCMAKE_CXX_COMPILER_WORKS=1
			# Install inside the cross sysroot.
			-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/${CTARGET}/usr"
		)
	fi
	if use test; then
		mycmakeargs+=(
			-DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx"
			-DLLVM_EXTERNAL_LIT="${EPREFIX}/usr/bin/lit"
			-DLLVM_LIT_ARGS="$(get_lit_flags)"
			-DLIBUNWIND_LIBCXX_PATH="${WORKDIR}/libcxx"

			-DLIBCXXABI_LIBDIR_SUFFIX=
			-DLIBCXXABI_ENABLE_SHARED=OFF
			-DLIBCXXABI_ENABLE_STATIC=ON
			-DLIBCXXABI_USE_LLVM_UNWINDER=ON
			-DLIBCXXABI_INCLUDE_TESTS=OFF

			-DLIBCXX_LIBDIR_SUFFIX=
			-DLIBCXX_ENABLE_SHARED=OFF
			-DLIBCXX_ENABLE_STATIC=ON
			-DLIBCXX_CXX_ABI=libcxxabi
			-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF
			-DLIBCXX_HAS_MUSL_LIBC=$(llvm_cmake_use_musl)
			-DLIBCXX_HAS_GCC_S_LIB=OFF
			-DLIBCXX_INCLUDE_TESTS=OFF
			-DLIBCXX_INCLUDE_BENCHMARKS=OFF
		)
	fi

	cmake_src_configure
}

multilib_src_test() {
	local -x LIT_PRESERVES_TMP=1
	cmake_build check-unwind
}

multilib_src_install() {
	DESTDIR=${D} cmake_build install-unwind
}
