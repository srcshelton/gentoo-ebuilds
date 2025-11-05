# Copyright 2021-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# The (community-maintained) CMake backend seems broken :(
#inherit cmake
inherit fcaps toolchain-funcs xdg

DESCRIPTION="A monitor of resources"
HOMEPAGE="https://github.com/aristocratos/btop"
SRC_URI="
	https://github.com/aristocratos/btop/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz
"

LICENSE="Apache-2.0 MIT"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 ~loong ~m68k ~mips ~ppc ppc64 ~riscv ~sparc x86"
IUSE="gpu +gui +man +themes video_cards_amdgpu video_cards_nvidia"

BDEPEND="
	man? ( app-text/lowdown )
	video_cards_amdgpu? ( dev-util/rocm-smi )
	video_cards_nvidia? ( x11-drivers/nvidia-drivers )
	sys-apps/coreutils
	sys-apps/sed
"
	#>=dev-build/cmake-3.25

DOCS=( "README.md" "CHANGELOG.md" )

pkg_setup() {
	if [[ "${MERGE_TYPE}" != "binary" ]]; then
		if tc-is-clang ; then
			if [[ "$(clang-major-version)" -lt 16 ]]; then
				die "sys-process/btop requires >=llvm-runtimes/clang-runtime:16 in order to build."
			fi
		elif tc-is-gcc ; then
			if ! has_version -b '>=sys-devel/gcc-11'; then
				die "sys-process/btop requires >=sys-devel/gcc:11 in order to build."
			fi
		else
			die "$(tc-getCXX) is not a supported compiler. Please use sys-devel/gcc or >=llvm-core/clang:16 instead."
		fi
	fi
}

src_prepare() {
	default

	# Only white (actually grey), green, and red foreground colours are
	# defined in src/btop.cpp :(
	sed -e '/ERROR: /s#fg_white#fg_red#' \
		-e '/No UTF-8 locale detected/s#\\n#\\n       #' \
		-i src/btop.cpp || die

	# btop installs README.md to /usr/share/btop by default
	sed -e 's/\\033\[[0-9][^m-]*m//g' \
		-e 's/\\033\[[0-9][^m-]*-/-/g' \
		-e '/^.*cp -p README.md.*$/d' \
		-i Makefile || die
}

# CMake:
#src_configure() {
#	local mycmakeargs=(
#		## Gentoo sets CMAKE_INSTALL_PREFIX to '/usr', but btop still installs to /usr/local - can we fix this?
#		#-DCMAKE_INSTALL_PREFIX:PATH=/usr
#		## ... turns out, we can't :(
#		-DBTOP_GPU:BOOL=$(usex gpu 'true' 'false')
#		-DBTOP_RSMI_STATIC:BOOL=false
#		-DBTOP_STATIC:BOOL=false
#		# These settings can be controlled in make.conf CFLAGS/CXXFLAGS
#		-DBTOP_LTO:BOOL=false
#	)
#	cmake_src_configure
#}

src_compile() {
	# See https://github.com/aristocratos/btop/tree/v1.4.5#with-make
	#
	# Disable btop optimization flags, since we have our flags in CXXFLAGS
	#
	# N.B. Optimisation '-O0 -g' will be applied if 'DEBUG' is defined, even if
	#      set to 'false'
	#
	emake \
			CXX="$(tc-getCXX)" \
			DEBUG= \
			GPU_SUPPORT=$(usex gpu 'true' 'false') \
			OPTFLAGS='-g' \
			RSMI_STATIC=false \
			STATIC=false \
			VERBOSE=true ||
		die
}

src_install() {
	# CMake:
	## Go home cmake, you're drunk (1)...
	#if [[ -x "${BUILD_DIR}/btop" && ! -x "${BUILD_DIR}/bin/btop" ]]; then
	#	mkdir "${BUILD_DIR}/bin"
	#	mv "${BUILD_DIR}/btop" "${BUILD_DIR}/bin/btop"
	#fi
	#
	#default

	emake \
				PREFIX="${EPREFIX}/usr" \
				DESTDIR="${D}" \
			install ||
		die
	fcaps "cap_perfmon=+ep cap_dac_read_search=+ep" usr/bin/btop || die

	# Go home cmake, you're drunk (2)...
	if [[ -d "${ED}"/usr/local/share ]]; then
		dodir /usr/share
		mv "${ED}"/usr/local/share/* "${ED}"/usr/share/
		rmdir --ignore-fail-on-non-empty --parents "${ED}"/usr/local/share
	fi

	use gui ||
		rm -r "${ED}"/usr/share/{applications,icons}
	use themes ||
		rm -r "${ED}"/usr/share/btop/themes

	rmdir -p "${ED}"/usr/share/btop "${ED}"/usr/lib >/dev/null 2>&1
}

pkg_postinst() {
	use gui && xdg_pkg_postinst
}
