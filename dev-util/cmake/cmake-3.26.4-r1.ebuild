# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Generate using https://github.com/thesamesam/sam-gentoo-scripts/blob/main/niche/generate-cmake-docs
# Set to 1 if prebuilt, 0 if not
# (the construct below is to allow overriding from env for script)
: ${CMAKE_DOCS_PREBUILT:=1}

CMAKE_DOCS_PREBUILT_DEV=sam
#CMAKE_DOCS_VERSION=$(ver_cut 1-3)
CMAKE_DOCS_VERSION=${PV}
# Default to generating docs (inc. man pages) if no prebuilt; overridden later
# See bug #784815
CMAKE_DOCS_USEFLAG="+doc"

# TODO RunCMake.LinkWhatYouUse fails consistently w/ ninja
# ... but seems fine as of 3.22.3?
# TODO ... but bootstrap sometimes(?) fails with ninja now. bug #834759.
CMAKE_MAKEFILE_GENERATOR="emake"
CMAKE_REMOVE_MODULES_LIST=( none )
inherit bash-completion-r1 cmake elisp-common flag-o-matic multiprocessing toolchain-funcs virtualx xdg-utils

MY_P="${P/_/-}"

DESCRIPTION="Cross platform Make"
HOMEPAGE="https://cmake.org/"
if [[ ${PV} == 9999 ]] ; then
	CMAKE_DOCS_PREBUILT=0

	EGIT_REPO_URI="https://gitlab.kitware.com/cmake/cmake.git"
	inherit git-r3
else
	SRC_URI="https://cmake.org/files/v$(ver_cut 1-2)/${MY_P}.tar.gz"

	if [[ ${CMAKE_DOCS_PREBUILT} == 1 ]] ; then
		SRC_URI+=" !doc? ( https://dev.gentoo.org/~${CMAKE_DOCS_PREBUILT_DEV}/distfiles/${CATEGORY}/${PN}/${PN}-${CMAKE_DOCS_VERSION}-docs.tar.xz )"
	fi

	if [[ ${PV} != *_rc* ]] ; then
		VERIFY_SIG_OPENPGP_KEY_PATH="${BROOT}"/usr/share/openpgp-keys/bradking.asc
		inherit verify-sig

		SRC_URI+=" verify-sig? (
			https://github.com/Kitware/CMake/releases/download/v$(ver_cut 1-3)/${MY_P}-SHA-256.txt
			https://github.com/Kitware/CMake/releases/download/v$(ver_cut 1-3)/${MY_P}-SHA-256.txt.asc
		)"

		KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"

		BDEPEND="verify-sig? ( sec-keys/openpgp-keys-bradking )"
	fi
fi

[[ ${CMAKE_DOCS_PREBUILT} == 1 ]] && CMAKE_DOCS_USEFLAG="doc"

S="${WORKDIR}/${MY_P}"

LICENSE="CMake"
SLOT="0"
IUSE="doc emacs ncurses qt5 test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=app-arch/libarchive-3.3.3:=
	app-crypt/rhash
	>=dev-libs/expat-2.0.1
	>=dev-libs/jsoncpp-1.9.2-r2:0=
	>=dev-libs/libuv-1.10.0:=
	>=net-misc/curl-7.21.5[ssl]
	sys-libs/zlib
	virtual/pkgconfig
	emacs? ( >=app-editors/emacs-23.1:* )
	ncurses? ( sys-libs/ncurses:0= )
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtwidgets:5
	)
"
DEPEND="${RDEPEND}"
BDEPEND+="
	doc? (
		dev-python/requests
		dev-python/sphinx
	)
	test? ( app-arch/libarchive[zstd] )
"

SITEFILE="50${PN}-gentoo.el"

PATCHES=(
	# Prefix
	"${FILESDIR}"/${PN}-3.16.0_rc4-darwin-bundle.patch
	"${FILESDIR}"/${PN}-3.14.0_rc3-prefix-dirs.patch
	"${FILESDIR}"/${PN}-3.19.1-darwin-gcc.patch

	# Handle gentoo packaging in find modules
	"${FILESDIR}"/${PN}-3.17.0_rc1-FindBLAS.patch
	# Next patch needs to be reworked
	#"${FILESDIR}"/${PN}-3.17.0_rc1-FindLAPACK.patch
	"${FILESDIR}"/${PN}-3.5.2-FindQt4.patch

	# Respect python eclasses
	"${FILESDIR}"/${PN}-2.8.10.2-FindPythonLibs.patch
	"${FILESDIR}"/${PN}-3.9.0_rc2-FindPythonInterp.patch

	"${FILESDIR}"/${PN}-3.18.0-filter_distcc_warning.patch # bug 691544

	# upstream fixes (can usually be removed with a version bump)
)

cmake_src_bootstrap() {
	# disable running of cmake in bootstrap command
	sed -i \
		-e '/"${cmake_bootstrap_dir}\/cmake"/s/^/#DONOTRUN /' \
		bootstrap || die "sed failed"

	# execinfo.h on Solaris isn't quite what it is on Darwin
	if [[ ${CHOST} == *-solaris* ]] ; then
		sed -i -e 's/execinfo\.h/blablabla.h/' \
			Source/kwsys/CMakeLists.txt || die
	fi

	# bootstrap script isn't exactly /bin/sh compatible
	tc-env_build ${CONFIG_SHELL:-sh} ./bootstrap \
		--prefix="${T}/cmakestrap/" \
		--parallel=$(makeopts_jobs "${MAKEOPTS}" "$(get_nproc)") \
		|| die "Bootstrap failed"
}

src_unpack() {
	if [[ ${PV} == 9999 ]] ; then
		git-r3_src_unpack
	elif [[ ${PV} == *_rc* ]] || ! use verify-sig ; then
		default
	else
		cd "${DISTDIR}" || die

		# See https://mgorny.pl/articles/verify-sig-by-example.html#verifying-using-a-checksum-file-with-a-detached-signature
		verify-sig_verify_detached ${MY_P}-SHA-256.txt{,.asc}
		verify-sig_verify_unsigned_checksums ${MY_P}-SHA-256.txt sha256 ${MY_P}.tar.gz

		cd "${WORKDIR}" || die

		default
	fi
}

src_prepare() {
	cmake_src_prepare

	if [[ ${CHOST} == *-darwin* ]] ; then
		# Disable Xcode hooks, bug #652134
		sed -i -e 's/cm\(\|Global\|Local\)XCode[^.]\+\.\(cxx\|h\)//' \
			Source/CMakeLists.txt || die
		sed -i -e '/define CMAKE_USE_XCODE/s/XCODE/NO_XCODE/' \
			-e '/cmGlobalXCodeGenerator.h/d' \
			Source/cmake.cxx || die

		# Disable isysroot usage with GCC, we've properly instructed
		# where things are via GCC configuration and ldwrapper
		sed -i -e '/cmake_gnu_set_sysroot_flag/d' \
			Modules/Platform/Apple-GNU-*.cmake || die
		# Disable isysroot usage with clang as well
		sed -i -e '/_SYSROOT_FLAG/d' \
			Modules/Platform/Apple-Clang.cmake || die
		# Don't set a POSIX standard, system headers don't like that, #757426
		sed -i -e 's/^#if !defined(_WIN32) && !defined(__sun)/& \&\& !defined(__APPLE__)/' \
			Source/cmLoadCommandCommand.cxx \
			Source/cmStandardLexer.h \
			Source/cmSystemTools.cxx \
			Source/cmTimestamp.cxx
		sed -i -e 's/^#if !defined(_POSIX_C_SOURCE) && !defined(_WIN32) && !defined(__sun)/& \&\& !defined(__APPLE__)/' \
			Source/cmStandardLexer.h
	fi

	# Add gcc libs to the default link paths
	sed -i \
		-e "s|@GENTOO_PORTAGE_GCCLIBDIR@|${EPREFIX}/usr/${CHOST}/lib/|g" \
		-e "$(usex prefix-guest "s|@GENTOO_HOST@||" "/@GENTOO_HOST@/d")" \
		-e "s|@GENTOO_PORTAGE_EPREFIX@|${EPREFIX}/|g" \
		Modules/Platform/{UnixPaths,Darwin}.cmake || die "sed failed"

	if ! has_version -b ">=${CATEGORY}/${PN}-3.13" || ! cmake --version &>/dev/null ; then
		CMAKE_BINARY="${S}/Bootstrap.cmk/cmake"
		cmake_src_bootstrap
	fi
}

src_configure() {
	# Fix linking on Solaris
	[[ ${CHOST} == *-solaris* ]] && append-ldflags -lsocket -lnsl

	# ODR warnings, bug #858335
	# https://gitlab.kitware.com/cmake/cmake/-/issues/20740
	filter-lto

	local mycmakeargs=(
		-DCMAKE_USE_SYSTEM_LIBRARIES=ON
		-DCMAKE_DOC_DIR=/share/doc/${PF}
		-DCMAKE_MAN_DIR=/share/man
		-DCMAKE_DATA_DIR=/share/${PN}
		-DSPHINX_MAN=$(usex doc)
		-DSPHINX_HTML=$(usex doc)
		-DBUILD_CursesDialog="$(usex ncurses)"
		-DBUILD_TESTING=$(usex test)
	)
	use qt5 && mycmakeargs+=( -DBUILD_QtDialog=ON )

	cmake_src_configure

	if use amd64 && [[ ${ABI} == "x32" ]]; then
		# Try to fix-up lib(x)32 paths...
		if [[ -n "${LIBDIR_x32}" && "${LIBDIR_x32}" != 'libx32' ]]; then
			ebegin "Updating 'x32' library paths to use '${LIBDIR_x32}'"
			local file
			local -i counter=0
			while read -r file; do
				if [[ -s "${file}" ]]; then
					einfo "Attempting to update file '${file}' ..."
					sed -i \
						-e "s|libx32|${LIBDIR_x32}|g" \
						"${file}" || die "sed failed: ${?}"
					(( counter ++ ))
				else
					ewarn "File '${file}' could not be read"
				fi
			#done <<<"$( find . -type f -exec grep -H libx32 {} + | grep -v 'matches$' | cut -d':' -f 1 | sort | uniq )"
			done <<<"$( find . -type f -exec grep -l libx32 {} + )"

			sed -i \
				-e "s|this->AddArchitecturePaths(\"x32\");|this->AddArchitecturePaths(\"${LIBDIR_x32#lib}\");|" \
				Source/cmFindLibraryCommand.cxx || die "sed failed: ${?}"
			(( counter ++ ))
			einfo "Updated ${counter} files"
			eend 0
		fi

		# Try to ensure that we search for libraries from the specified LIBDIR
		# first...
		local file
		while read -r file; do
			einfo "Attempting to correct order in file '${file}' ..."
			sed -i \
			    -e "s|lib64\(.*\)${LIBDIR_x32}|${LIBDIR_x32}\1lib64|g" \
			    "${file}" || die "sed failed: ${?}"
			    #-e 's|/lib64/|/lib64-ignore/|g' \
		#done <<<"$( find . -type f -exec grep -H lib64 {} + | grep -v 'matches$' | cut -d':' -f 1 )"
		done <<<"$( find . -type f -exec grep -l lib64 {} + )"
	fi
}

src_compile() {
	cmake_src_compile
	use emacs && elisp-compile Auxiliary/cmake-mode.el
}

src_test() {
	# Fix OutDir and SelectLibraryConfigurations tests
	# these are altered thanks to our eclass
	sed -i -e 's:^#_cmake_modify_IGNORE ::g' \
		"${S}"/Tests/{OutDir,CMakeOnly/SelectLibraryConfigurations}/CMakeLists.txt \
		|| die

	pushd "${BUILD_DIR}" > /dev/null || die

	# Excluded tests:
	#    BootstrapTest: we actualy bootstrap it every time so why test it.
	#    BundleUtilities: bundle creation broken
	#    CMakeOnly.AllFindModules: pthread issues
	#    CTest.updatecvs: which fails to commit as root
	#    Fortran: requires fortran
	#    RunCMake.CompilerLauncher: also requires fortran
	#    RunCMake.CPack_RPM: breaks if app-arch/rpm is installed because
	#        debugedit binary is not in the expected location
	#    RunCMake.CPack_DEB: breaks if app-arch/dpkg is installed because
	#        it can't find a deb package that owns libc
	#    TestUpload, which requires network access
	#    RunCMake.CMP0125, known failure reported upstream (bug #829414)
	local myctestargs=(
		--output-on-failure
		-E "(BootstrapTest|BundleUtilities|CMakeOnly.AllFindModules|CompileOptions|CTest.UpdateCVS|Fortran|RunCMake.CompilerLauncher|RunCMake.CPack_(DEB|RPM)|TestUpload|RunCMake.CMP0125)" \
	)

	virtx cmake_src_test
}

src_install() {
	cmake_src_install

	# If USE=doc, there'll be newly generated docs which we install instead.
	if ! use doc && [[ ${CMAKE_DOCS_PREBUILT} == 1 ]] ; then
		doman "${WORKDIR}"/${PN}-${CMAKE_DOCS_VERSION}-docs/man*/*.[0-8]
	fi

	if use emacs; then
		elisp-install ${PN} Auxiliary/cmake-mode.el Auxiliary/cmake-mode.elc
		elisp-site-file-install "${FILESDIR}/${SITEFILE}"
	fi

	insinto /usr/share/vim/vimfiles/syntax
	doins Auxiliary/vim/syntax/cmake.vim

	insinto /usr/share/vim/vimfiles/indent
	doins Auxiliary/vim/indent/cmake.vim

	insinto /usr/share/vim/vimfiles/ftdetect
	doins "${FILESDIR}/${PN}.vim"

	dobashcomp Auxiliary/bash-completion/{${PN},ctest,cpack}
}

pkg_postinst() {
	use emacs && elisp-site-regen

	if use qt5; then
		xdg_icon_cache_update
		xdg_desktop_database_update
		xdg_mimeinfo_database_update
	fi
}

pkg_postrm() {
	use emacs && elisp-site-regen

	if use qt5; then
		xdg_icon_cache_update
		xdg_desktop_database_update
		xdg_mimeinfo_database_update
	fi
}
