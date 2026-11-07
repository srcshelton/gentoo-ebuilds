# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

GO_VENDOR_VERSION="0.40.11"
ROCM_VERSION="7.2.1"
inherit cmake flag-o-matic go-module systemd

DESCRIPTION="Get up and running with Llama 3, Mistral, Gemma, and other language models"
HOMEPAGE="https://ollama.com"

LLAMA_CPP_tag="b12111"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/ollama/ollama.git"
else
	SRC_URI="
		https://github.com/ollama/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/srcshelton/ollama/releases/download/v${GO_VENDOR_VERSION}/${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz
		https://github.com/ggml-org/llama.cpp/archive/refs/tags/${LLAMA_CPP_tag}.tar.gz -> llama.cpp-${LLAMA_CPP_tag}.tar.gz"
		#https://github.com/gentoo-golang-dist/${PN}/releases/download/v${PV}/${P}-deps.tar.xz
	KEYWORDS="~amd64 ~arm64"
fi

LICENSE="MIT"
SLOT="0"

IUSE="+debug"
RESTRICT="mirror test"

DEPEND="
	>=sci-ml/ggml-0.28.0:=
"

BDEPEND="
	>=dev-build/cmake-3.31.2
	>=dev-lang/go-1.26.10
	dev-libs/stb
"

RDEPEND="${DEPEND}
	acct-group/${PN}
	acct-user/${PN}
	net-misc/curl:=
"

PATCHES=(
	"${FILESDIR}"/${PN}-0.31.1-ggml.patch
	"${FILESDIR}"/${PN}-0.34.2-cmake.patch
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
				unpack "${item}" || die
				;;
			"${PN}-${GO_VENDOR_VERSION}-vendor.tar.xz")
				tar -xa --no-same-owner \
						-f "${DISTDIR}/${item}" \
						-C "${P}"/ ||
					die
				;;
			"llama.cpp-${LLAMA_CPP_tag}.tar.gz")
				unpack "${item}" || die

				mkdir -p "${WORKDIR}/${P}_build/_deps" || die
				ln -s "${WORKDIR}/llama.cpp-${LLAMA_CPP_tag}" \
						"${WORKDIR}/${P}_build/_deps/llama_cpp-src" ||
					die
				pushd "${WORKDIR}/llama.cpp-${LLAMA_CPP_tag}" >/dev/null
				eapply "${FILESDIR}/llama.cpp-b11963-git.patch" || die
				popd >/dev/null
				;;
			*)
				die "Unexpected item '${item}' in src_unpack()"
				;;
		esac
	done
}

src_prepare() {
	cmake_src_prepare

	local llama_src="${BUILD_DIR}/_deps/llama_cpp-src"
	local llama_patch_dir="${WORKDIR}/${P}/llama/compat"

	# Switch to the llama.cpp source directory
	pushd "${llama_src}" > /dev/null || die
	eapply "${llama_patch_dir}"/*.patch \
		"${FILESDIR}"/${PN}-0.31.1-gcc17.patch

	# Remove vendored
	cmake_comment_add_subdirectory -f vendor stb
	rm -r vendor/stb || die
	sed -i \
		-e "s|vendor::stb ||" \
		tools/mtmd/CMakeLists.txt \
		|| die
	popd > /dev/null || die

	if use !debug; then
		sed -e '/var mode string = gin\./{s/gin\.DebugMode/gin.ReleaseMode/}' \
			-e '/mode = gin\./{s/gin\.DebugMode/gin.ReleaseMode/}' \
			-i server/routes.go || die
	fi
}

src_configure() {
	# Configure Embedded local Server
	local llama_src="${BUILD_DIR}/_deps/llama_cpp-src"
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${BUILD_DIR}"
		-DOLLAMA_RUNNER_DIR=""
		-DFETCHCONTENT_SOURCE_DIR_LLAMA_CPP="${llama_src}"
		-DOLLAMA_LLAMA_CPP_SKIP_COMPAT_PATCH=ON
		-DBUILD_SHARED_LIBS=ON
		-DLLAMA_USE_SYSTEM_GGML=ON

		-DLLAMA_BUILD_NUMBER=0
		-DLLAMA_BUILD_COMMIT="${LLAMA_CPP_tag}"

		-Wno-dev
	)
	local CMAKE_USE_DIR="${S}/llama/server"
	local BUILD_DIR="${BUILD_DIR}/llama-server-local"

	cmake_src_configure
}

src_compile() {
	local SAVE_BUILD_DIR="${BUILD_DIR}"

	# Compile Embedded Local Server
	local BUILD_DIR="${BUILD_DIR}"/llama-server-local
	local cmake_src_compile_opts=(
		--target llama-server
		--target llama-quantize
	)
	cmake_src_compile

	# Install/Stage Local Server Component
	"${CMAKE_BINARY}" \
			--install "${BUILD_DIR}" \
			--prefix "${SAVE_BUILD_DIR}" \
			--component llama-server ||
		die "Failed to stage server component"

	# Expose CGO to Go and establish compiler optimization paths
	export CGO_ENABLED=1

	# Replicate the linker flags dynamically from your ebuild version
	local mygoldflags="-X github.com/ollama/ollama/version.Version=${PV} \
		-X github.com/ollama/ollama/server.mode=release"

	# Call the Go build engine natively with standard Gentoo flags
	ego build \
			-trimpath \
			-ldflags "${mygoldflags}" \
			-o "${BUILD_DIR}/ollama" \
			. ||
		die "Go build failed"
}

src_install() {
	dobin "${BUILD_DIR}"/llama-server-local/ollama
	insinto usr
	doins -r "${BUILD_DIR}"/lib
	local libdir="/usr/lib/ollama"
	fperms -R +x ${libdir}

	# Symlink system GGML libraries into Ollama's expected path
	# Bug 983804
	for lib in "${EPREFIX}"/usr/$(get_libdir)/libggml*.so; do
		local libname=$(basename "${lib}")
		dosym ../../$(get_libdir)/${libname} /usr/lib/ollama/${libname}
	done

	einstalldocs

	newinitd "${FILESDIR}/ollama.init" "${PN}"
	newconfd "${FILESDIR}/ollama.confd" "${PN}"

	use systemd && systemd_dounit "${FILESDIR}/ollama.service"
}

pkg_preinst() {
	keepdir /var/log/ollama
	fperms 750 /var/log/ollama
	fowners "${PN}:${PN}" /var/log/ollama
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]] ; then
		einfo "Quick guide:"
		einfo "\tollama serve"
		einfo "\tollama run llama3:70b"
		einfo
		einfo "See available models at https://ollama.com/library"
	fi

	einfo
	einfo "Ollama binds 127.0.0.1 port 11434 by default."
	einfo "Change the bind address with the OLLAMA_HOST environment variable."
	einfo "See https://docs.ollama.com/faq for more info"
	einfo
}
