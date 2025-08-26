# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GO_VENDOR_VERSION="${PV}"
ROCM_VERSION=6.3.3
inherit cmake cuda flag-o-matic go-module rocm systemd toolchain-funcs

DESCRIPTION="Get up and running with Llama 3, Mistral, Gemma, and other language models."
HOMEPAGE="https://ollama.com"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/ollama/ollama.git"
else
	SRC_URI="
		https://github.com/ollama/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/srcshelton/ollama/releases/download/v${GO_VENDOR_VERSION}/${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz"
	KEYWORDS="~amd64 ~arm64"
fi

LICENSE="MIT"
SLOT="0"

X86_CPU_FLAGS=(
	avx
	f16c
	avx2
	fma3
	avx512f
	avx512vbmi
	avx512_vnni
	avx512_bf16
	avx_vnni
	amx_tile
	amx_int8
)
CPU_FLAGS=("${X86_CPU_FLAGS[@]/#/cpu_flags_x86_}")
IUSE="${CPU_FLAGS[*]} blas cuda +debug minimal mkl multiarch rocm"  # opencl vulkan
REQUIRED_USE="
	?? ( minimal multiarch )
	minimal? ( amd64 )
	mkl? ( amd64 )
	multiarch? ( amd64 )
"

DEPEND="
	cuda? (
		dev-util/nvidia-cuda-toolkit:=
	)
	blas? (
		!mkl? (
			virtual/blas
		)
		mkl? (
			sci-libs/mkl
		)
	)
	rocm? (
		>=sci-libs/hipBLAS-${ROCM_VERSION}:=[${ROCM_USEDEP}]
	)
"

BDEPEND="
	>=dev-build/cmake-3.31.2
	>=dev-lang/go-1.24.0
"

RDEPEND="
	${DEPEND}
	acct-group/${PN}
	acct-user/${PN}
"

PATCHES=(
	"${FILESDIR}/${PN}-0.5.11-OMP_NUM_THREADS.patch"
)

src_unpack() {
	#[[ -n ${A} ]] && unpack ${A}

	# TODO: Switch to 'go-module_src_unpack'/'go-module_live_vendor'?
	# FIXME: go-module_src_unpack results in:
	#        Directory '.../ml-apps/ollama-0.5.11/work/ollama-0.5.11/vendor' was not created

	local item=''

	for item in ${A}; do
		case "${item}" in
			"${P}.tar.gz")
				unpack "${item}"
				;;
			"${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz")
				tar -xa --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${P}"/ ||
					die
				;;
			*)
				ewarn "Unexpected item '${item}' in src_unpack()"
				unpack "${item}"
				;;
		esac
	done
}

src_prepare() {
	local -a archs=()
	local arch=''

	archs=( sandybridge haswell skylakex icelake alderlake sapphirerapids )

	cmake_src_prepare

	sed -e '/set(GGML_CCACHE/{s/ON/OFF/g}' -i CMakeLists.txt || die

	if use !debug; then
		sed -e '/var mode string = gin\./{s/gin\.DebugMode/gin.ReleaseMode}/' \
			-e '/mode = gin\./{s/gin\.DebugMode/gin.ReleaseMode/}' \
			-i server/routes.go || die
	fi

	# See ml/backend/ggml/ggml/src/CMakeLists.txt
	if ! use amd64; then
		sed -e '/set(GGML_CPU_ALL_VARIANTS/{s/ON/OFF/g}' -i CMakeLists.txt ||
			die
	else  # ^ use !amd64 | use amd64 v
		local -A keep_backends=()
		local backend=''

		if use cpu_flags_x86_avx; then
			if use cpu_flags_x86_f16c && use cpu_flags_x86_avx2 &&
					use cpu_flags_x86_fma3
			then
				if ! use cpu_flags_x86_avx512f; then
					if use cpu_flags_x86_avx_vnni; then
						# AVX F16C AVX2 FMA AVX_VNNI
						keep_backends['alderlake']=1
						[[ -z "${backend:-}" ]] && backend='alderlake'
					fi
				else
					if use cpu_flags_x86_avx512vbmi &&
								use cpu_flags_x86_avx512_vnni
					then
						if use cpu_flags_x86_avx512_bf16 &&
								use cpu_flags_x86_amx_tile &&
								use cpu_flags_x86_amx_int8
						then
							# AVX F16C AVX2 FMA AVX512 AVX512_VBMI AVX512_VNNI
							# AVX512_BF16 AMX_TILE AMX_INT8
							keep_backends['sapphirerapids']=1
							[[ -z "${backend:-}" ]] && backend='sapphirerapids'
						fi
						# AVX F16C AVX2 FMA AVX512 AVX512_VBMI AVX512_VNNI
						keep_backends['icelake']=1
						[[ -z "${backend:-}" ]] && backend='icelake'
					fi
					# AVX F16C AVX2 FMA AVX512
					keep_backends['skylakex']=1
					[[ -z "${backend:-}" ]] && backend='skylakex'
				fi
				# AVX F16C AVX2 FMA
				keep_backends['haswell']=1
				[[ -z "${backend:-}" ]] && backend='haswell'
			fi
			# AVX
			keep_backends['sandybridge']=1
			[[ -z "${backend:-}" ]] && backend='sandybridge'
		fi

		# USE='minimal'   - install best-fit backend for build host;
		# USE='multiarch' - install all backends;
		# ... otherwise   - install all backends up to build host best-fit.
		#
		if use multiarch; then
			for arch in "${archs[@]}"; do
				einfo "Enabling optimised support for '${arch}'" \
					"architecture ..."
			done
		else  # ^ use multiarch | use !multiarch v
			if [[ -z "${backend:-}" ]]; then
				ewarn "Disabling optimised support for all architectures ..."
			sed \
					-e '/set(GGML_CPU_ALL_VARIANTS/{s/ON/OFF/g}' \
					-i CMakeLists.txt ||
				die
			else  # ^ -z "${backend:-}" | -n "${backend:-}" v
				if use minimal; then
					for arch in "${archs[@]}"; do
						if [[ "${arch}" == "${backend:-}" ]]; then
							einfo "Enabling optimised support for '${arch}'" \
								"architecture ..."
						else
							ewarn "Disabling optimised support for '${arch}'" \
								"architecture ..."
							sed -e "/ggml_add_cpu_backend_variant(${arch}/{s/^/# /g}" \
								-i ml/backend/ggml/ggml/src/CMakeLists.txt || die
						fi
					done
				else  # ^ use minimal | use !minimal v
					for arch in "${archs[@]}"; do
						if [[ -n "${keep_backends["${arch}"]:-}" ]]; then
							einfo "Enabling optimised support for '${arch}'" \
								"architecture ..."
						else
							ewarn "Disabling optimised support for '${arch}'" \
								"architecture ..."
							sed -e "/ggml_add_cpu_backend_variant(${arch}/{s/^/# /g}" \
								-i ml/backend/ggml/ggml/src/CMakeLists.txt || die
						fi
					done
				fi   # use !minimal
			fi  # -n "${backend:-}"
		fi  # use !multiarch
	fi  # use amd64

	if use cuda; then
		cuda_src_prepare
	fi

	if use rocm; then
		# --hip-version gets appended to the compile flags which isn't a known
		# flag.  This causes rocm builds to fail because
		# -Wunused-command-line-argument is turned on.
		#
		find "${S}" -name ".go" \
				-exec sed -i "s/ -Wunused-command-line-argument / -Wno-unused-command-line-argument /g" {} + ||
			die
	fi
}

src_configure() {
	# See https://github.com/ggerganov/llama.cpp/pull/7154#issuecomment-2144542197
	#
	# N.B. -mdaz-ftz is x86-specific...
	#
	filter-flags -ffast-math -ffinite-math-only -fno-math-errno
	replace-flags -Ofast -O3
	append-flags -fno-fast-math -fno-finite-math-only -fmath-errno
	if use amd64; then
		append-flags -mdaz-ftz
	fi

	# https://github.com/nlohmann/json/issues/4116
	#
	# LTO should likely be disabled because of these issues, but since they
	# seem to be limited to the JSON parser (where errors would presumably be
	# obvious), let's first try to see whether we can get by with LTO and
	# fatal errors disabled...
	#
	filter-flags -Werror=odr -Werror=lto-type-mismatch

	local mycmakeargs=(
		-DGGML_CCACHE="no"

		-DGGML_BLAS="$(usex blas)"
		# -DGGML_CUDA="$(usex cuda)"
		# -DGGML_HIP="$(usex rocm)"

		# -DGGML_METAL="yes" # apple
		# missing from ml/backend/ggml/ggml/src/
		# -DGGML_CANN="yes"
		# -DGGML_MUSA="yes"
		# -DGGML_RPC="yes"
		# -DGGML_SYCL="yes"
		# -DGGML_KOMPUTE="$(usex kompute)"
		# -DGGML_OPENCL="$(usex opencl)"
		# -DGGML_VULKAN="$(usex vulkan)"
	)

	if use blas; then
		if use mkl; then
			mycmakeargs+=( -DGGML_BLAS_VENDOR="Intel" )
		else
			mycmakeargs+=( -DGGML_BLAS_VENDOR="Generic" )
		fi
	fi

	if use cuda; then
		local -x CUDAHOSTCXX CUDAHOSTLD
		CUDAHOSTCXX="$(cuda_gccdir)"
		CUDAHOSTLD="$(tc-getCXX)"

		cuda_add_sandbox -w
	else
		mycmakeargs+=( -DCMAKE_CUDA_COMPILER="NOTFOUND" )
	fi

	if use rocm; then
		mycmakeargs+=( -DCMAKE_HIP_PLATFORM="amd" )
		local -x HIP_ARCHS="$(get_amdgpu_flags)"
		local -x HIP_PATH="${EPREFIX}/usr"

		check_amdgpu
	else
		mycmakeargs+=( -DCMAKE_HIP_COMPILER="NOTFOUND" )
	fi

	cmake_src_configure

	# if ! use cuda && ! use rocm; then
	# 	# to configure and build only CPU variants
	# 	set -- cmake --preset Default "${mycmakeargs[@]}"
	# fi

	# if use cuda; then
	# 	# to configure and build only CUDA
	# 	set -- cmake --preset CUDA "${mycmakeargs[@]}"
	# fi

	# if use rocm; then
	# 	# to configure and build only ROCm
	# 	set -- cmake --preset ROCm "${mycmakeargs[@]}"
	# fi

	# echo "$@" >&2
	# "$@" || die -n "${*} failed"
}

src_compile() {
	ego build

	cmake_src_compile

	# if ! use cuda && ! use rocm; then
	# 	# to configure and build only CPU variants
	# 	set -- cmake --build --preset Default -j16
	# fi

	# if use cuda; then
	# 	# to configure and build only CUDA
	# 	set -- cmake --build --preset CUDA -j16
	# fi

	# if use rocm; then
	# 	# to configure and build only ROCm
	# 	set -- cmake --build --preset ROCm -j16
	# fi

	# echo "$@" >&2
	# "$@" || die -n "${*} failed"
}

src_install() {
	cmake_src_install

	dobin ollama

	if use cuda; then
		# remove the copied cuda files...
		#
		# Update: This may no longer be necessary?
		rm -f "${ED}/usr/lib/ollama"/cuda_*/libcu*.so*
	fi

	doinitd "${FILESDIR}"/ollama.init
	use systemd && systemd_dounit "${FILESDIR}"/ollama.service
}

pkg_postinst() {
	einfo "Quick guide:"
	einfo "  ollama serve"
	einfo "  ollama run llama3:70b"
	einfo
	einfo "See available models at https://ollama.com/library"
}
