# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake-multilib usr-ldscript

DESCRIPTION="A JSON implementation in C"
HOMEPAGE="https://github.com/json-c/json-c/wiki"

if [[ ${PV} == 9999 ]] ; then
	EGIT_REPO_URI="https://github.com/json-c/json-c.git"
	inherit git-r3
else
	SRC_URI="https://s3.amazonaws.com/json-c_releases/releases/${P}.tar.gz"

	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos"
fi

LICENSE="MIT"
# .1 is a fudge factor for 0.18 fixing compat w/ 0.16, drop on next
# SONAME change.
SLOT="0/5.1"
IUSE="cpu_flags_x86_rdrand doc static-libs test threads"
RESTRICT="!test? ( test )"

BDEPEND="doc? ( >=app-text/doxygen-1.8.13 )"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/json-c/config.h
)

PATCHES=( "${FILESDIR}/0.18.0-cmake4.patch" )

multilib_src_configure() {
	# Tests use Valgrind automagically otherwise (bug #927027)
	export USE_VALGRIND=0

	local mycmakeargs=(
		# apps are not installed, so disable unconditionally.
		# https://github.com/json-c/json-c/blob/json-c-0.17-20230812/apps/CMakeLists.txt#L119...L121
		-DBUILD_APPS=OFF
		-DBUILD_STATIC_LIBS=$(usex static-libs)
		-DDISABLE_EXTRA_LIBS=ON
		-DDISABLE_WERROR=ON
		-DENABLE_RDRAND=$(usex cpu_flags_x86_rdrand)
		-DENABLE_THREADING=$(usex threads)
		-DBUILD_TESTING=$(usex test)
	)

	cmake_src_configure
}

multilib_src_compile() {
	cmake_src_compile
	if use doc && multilib_is_native_abi; then
		cmake_build doc
	fi
}

multilib_src_test() {
	multilib_is_native_abi && cmake_src_test
}

multilib_src_install() {
	cmake_src_install

	if multilib_is_native_abi; then
		use doc && HTML_DOCS=( "${BUILD_DIR}"/doc/html )
		einstalldocs
	fi
}

multilib_src_install_all() {
	if multilib_is_native_abi; then
		gen_usr_ldscript -a json-c
	fi
}
