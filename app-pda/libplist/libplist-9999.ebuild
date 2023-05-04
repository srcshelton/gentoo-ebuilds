# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..11} )
inherit autotools git-r3 python-r1 toolchain-funcs

DESCRIPTION="Support library to deal with Apple Property Lists (Binary & XML)"
HOMEPAGE="https://www.libimobiledevice.org/"
EGIT_REPO_URI="https://github.com/libimobiledevice/libplist.git"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0/2.0-3"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="python"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="python? ( ${PYTHON_DEPS} )"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	python? ( >=dev-python/cython-0.17[${PYTHON_USEDEP}] )
"

DOCS=( NEWS )

BUILD_DIR="${S}_build"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local ECONF_SOURCE="${S}"

	do_configure() {
		mkdir -p "${BUILD_DIR}" || die
		pushd "${BUILD_DIR}" >/dev/null || die
		econf --disable-static "${@}"
		popd >/dev/null || die
	}

	do_configure_python() {
		local -x PYTHON_LDFLAGS="$(python_get_LIBS)"
		do_configure "$@"
	}

	# Don't prefer clang.
	tc-export CC CXX

	do_configure --without-cython
	use python && python_foreach_impl do_configure_python
}

src_compile() {
	local native_builddir=${BUILD_DIR}
	ln -s "${native_builddir}/src/libplist-2.0.la" \
		"${native_builddir}/src/libplist.la" || die

	python_compile() {
		emake -C "${BUILD_DIR}"/cython \
			VPATH="${S}/cython:${native_builddir}/cython" \
			plist_la_LIBADD="${native_builddir}/src/libplist-2.0.la"
	}

	pushd "${BUILD_DIR}" >/dev/null || die
	emake
	use python && python_foreach_impl python_compile
	popd >/dev/null || die
}

src_test() {
	emake -C "${BUILD_DIR}" check
}

src_install() {
	python_install() {
		emake -C "${BUILD_DIR}/cython" \
			VPATH="${S}/cython:${native_builddir}/cython" \
			DESTDIR="${D}" install
	}

	local native_builddir=${BUILD_DIR}
	pushd "${BUILD_DIR}" >/dev/null || die
	emake DESTDIR="${D}" install
	use python && python_foreach_impl python_install
	popd >/dev/null || die

	einstalldocs

	if use python ; then
		insinto /usr/include/plist/cython
		doins cython/plist.pxd
	fi

	find "${ED}" -name '*.la' -delete || die
}
