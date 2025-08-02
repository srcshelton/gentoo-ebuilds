# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake toolchain-funcs

SIMDJSON_DATA_HASH="a5b13babe65c1bba7186b41b43d4cbdc20a5c470"
CPM_SIMDJSON_DATA_HASH="3a55454e9d9a7133903378c28fb053f478f24537"
CPM_VERSION="0.40.2"
DESCRIPTION="SIMD accelerated C++ JSON library"
HOMEPAGE="
	https://simdjson.org/
	https://github.com/simdjson/simdjson
"
SRC_URI="
	https://github.com/${PN}/${PN}/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz
	https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_VERSION}/CPM.cmake -> CPM_${CPM_VERSION}.cmake
	https://github.com/${PN}/${PN}-data/archive/${SIMDJSON_DATA_HASH}.tar.gz -> ${PN}-data-${SIMDJSON_DATA_HASH}.tar.gz
"

LICENSE="Apache-2.0 Boost-1.0 BSD MIT"
SLOT="0/26"
KEYWORDS="amd64 arm arm64 ~loong ppc64 ~riscv x86"
IUSE="all-impls cpu_flags_arm_neon cpu_flags_arm_v8 cpu_flags_ppc_altivec cpu_flags_ppc_vsx cpu_flags_ppc_vsx2 cpu_flags_ppc_vsx3 cpu_flags_x86_avx2 cpu_flags_x86_avx512dq cpu_flags_x86_avx512f cpu_flags_x86_avx512_vbmi2 cpu_flags_x86_avx512vl cpu_flags_x86_sse4_2 test tools"

BDEPEND="
	app-shells/bash
	sys-apps/file
	sys-apps/grep
	virtual/pkgconfig
"
DEPEND="
	tools? ( >=dev-libs/cxxopts-3.2:= )
"

REQUIRED_USE="test? ( tools )"
RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}/simdjson-1.0.0-install-tools.patch"
	"${FILESDIR}/simdjson-3.10.1-tests.patch"
)

DOCS=(
	HACKING.md
	README.md
)

src_prepare() {
	# Need to make sure that CPM finds the data package
	mkdir "${WORKDIR}/cpm" "${WORKDIR}/${PN}-data" || die
	cp "${DISTDIR}/CPM_${CPM_VERSION}.cmake" "${WORKDIR}/cpm/CPM_${CPM_VERSION}.cmake" || die
	ln -s "../${PN}-data-${SIMDJSON_DATA_HASH}" "${WORKDIR}/${PN}-data/${CPM_SIMDJSON_DATA_HASH}" || die

	sed -e 's:-Werror ::' -i cmake/developer-options.cmake || die
	sed -e '/Werror/d' -i tests/ondemand/compilation_failure_tests/CMakeLists.txt || die
	sed -e "s:^c++ :$(tc-getCXX) :" -i singleheader/README.md || die
	mv tools/{,simd}jsonpointer.cpp || die
	cmake_src_prepare
}

src_configure() {
	local -a mycmakeargs=(
		-DSIMDJSON_ENABLE_THREADS=ON
		-DSIMDJSON_ENABLE_FUZZING=OFF
		-DCPM_SOURCE_CACHE="${WORKDIR}"
		-Wno-dev
	)
	# Definition added in patches...
	use test && mycmakeargs+=(
		-DSIMDJSON_TESTS=ON
	)

	if use tools; then
		mycmakeargs+=(
			-DSIMDJSON_DEVELOPER_MODE=ON
			-DSIMDJSON_ALLOW_DOWNLOADS=OFF
			-DSIMDJSON_GOOGLE_BENCHMARKS=OFF
			-DSIMDJSON_COMPETITION=OFF

			# Definition added in patches...
			-DSIMDJSON_TOOLS=ON
		)
	elif ! use test; then
		mycmakeargs+=(
			-DSIMDJSON_DEVELOPER_MODE=OFF
		)
	fi

	if ! use all-impls; then
		local -a impls=()
		if use amd64; then
			#impls+=("westmere" "haswell" "icelake")
			if use cpu_flags_x86_avx512f && use cpu_flags_x86_avx512_vbmi2 &&
				use cpu_flags_x86_avx512dq && use cpu_flags_x86_avx512vl
			then
				impls+=("icelake")
			elif use cpu_flags_x86_avx2; then
				impls+=("haswell")
			elif use cpu_flags_x86_sse4_2; then
				impls+=("westmere")
			else
				impls+=("fallback")
			fi
		elif use arm64; then
			#impls+=("arm64")
			if use cpu_flags_arm_neon && use cpu_flags_arm_v8; then
				impls+=("arm64")
			else
				impls+=("fallback")
			fi
		elif use loong; then
			impls+=("lasx" "lsx" "fallback")
		elif use ppc64; then
			#impls+=("ppc64")
			if use cpu_flags_ppc_altivec && { use cpu_flags_ppc_vsx ||
				use cpu_flags_ppc_vsx2 || cpu_flags_ppc_vsx3 ; }
			then
				impls+=("ppc64")
			else
				impls+=("fallback")
			fi
		fi

		einfo "Selected implementations: '$(printf '%s;' "${impls[@]}" | sed 's/;$//')'"
		mycmakeargs+=(
			-DSIMDJSON_IMPLEMENTATION=$(printf '%s;' "${impls[@]}" | sed 's/;$//')
		)
	fi

	cmake_src_configure
}
