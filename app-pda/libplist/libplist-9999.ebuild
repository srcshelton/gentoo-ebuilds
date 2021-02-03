# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"
PYTHON_COMPAT=( python3_{7..9} )
inherit autotools git-r3 python-r1

DESCRIPTION="Support library to deal with Apple Property Lists (Binary & XML)"
HOMEPAGE="http://www.libimobiledevice.org/"
#SRC_URI="http://www.libimobiledevice.org/downloads/${P}.tar.bz2"
EGIT_REPO_URI="https://github.com/libimobiledevice/libplist.git"
#EGIT_MASTER="master"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0/3.1.0" # based on SONAME of libplist.so
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86 ~amd64-fbsd"
IUSE="python static-libs"

RDEPEND="python? ( ${PYTHON_DEPS} )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	python? ( >=dev-python/cython-0.17[${PYTHON_USEDEP}] )"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DOCS=( NEWS README )

BUILD_DIR="${S}_build"

MAKEOPTS+=" -j1" #406365

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	local ECONF_SOURCE=${S}
	local myeconfargs=( $(use_enable static-libs static) )

	do_configure() {
		mkdir -p "${BUILD_DIR}" || die
		pushd "${BUILD_DIR}" >/dev/null || die
		econf "${myeconfargs[@]}" "${@}"
		popd >/dev/null || die
	}

	do_configure_python() {
		PYTHON_LDFLAGS="$(python_get_LIBS)" do_configure "$@"
	}

	do_configure --without-cython
	use python && python_foreach_impl do_configure_python
}

src_compile() {
	python_compile() {
		emake -C "${BUILD_DIR}"/cython -j1 \
			VPATH="${S}/cython:${native_builddir}/cython" \
			plist_la_LIBADD="${native_builddir}/src/libplist.la"
	}

	local native_builddir=${BUILD_DIR}
	pushd "${BUILD_DIR}" >/dev/null || die
	emake -j1
	use python && python_foreach_impl python_compile
	popd >/dev/null || die
}

src_install() {
	python_install() {
		emake -C "${BUILD_DIR}/cython" -j1 \
			VPATH="${S}/cython:${native_builddir}/cython" \
			DESTDIR="${D}" install
	}

	local native_builddir=${BUILD_DIR}
	pushd "${BUILD_DIR}" >/dev/null || die
	emake -j1 DESTDIR="${D}" install
	use python && python_foreach_impl python_install
	popd >/dev/null || die

	einstalldocs

	if use python ; then
		insinto /usr/include/plist/cython
		doins cython/plist.pxd
	fi
	prune_libtool_files --all
}
