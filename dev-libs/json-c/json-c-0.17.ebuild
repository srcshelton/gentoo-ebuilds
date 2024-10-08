# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake-multilib usr-ldscript

DESCRIPTION="A JSON implementation in C"
HOMEPAGE="https://github.com/json-c/json-c/wiki"
SRC_URI="https://s3.amazonaws.com/json-c_releases/releases/${P}.tar.gz"

LICENSE="MIT"
SLOT="0/5"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="cpu_flags_x86_rdrand doc static-libs threads"

BDEPEND="doc? ( >=app-doc/doxygen-1.8.13 )"

DOCS=(
	README.md
	ChangeLog
)

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/json-c/config.h
)

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
	)

	cmake_src_configure
}

multilib_src_test() {
	multilib_is_native_abi && cmake_src_test
}

multilib_src_install_all() {
	if multilib_is_native_abi; then
		gen_usr_ldscript -a json-c
	fi

	use doc && HTML_DOCS=( "${S}"/doc/html/. )
	einstalldocs
}
