# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_OPTIONAL=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )

inherit distutils-r1 usr-ldscript multilib-minimal

DESCRIPTION="High level interface to Linux seccomp filter"
HOMEPAGE="https://github.com/seccomp/libseccomp"

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/seccomp/libseccomp.git"
	PRERELEASE="2.6.0"
	inherit autotools git-r3
else
	SRC_URI="https://github.com/seccomp/libseccomp/releases/download/v${PV}/${P}.tar.gz"
	KEYWORDS="-* amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 x86 ~amd64-linux ~x86-linux"
fi

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="python static-libs test"
RESTRICT="!test? ( test )"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

# We need newer kernel headers; we don't keep strict control of the exact
# version here, just be safe and pull in the latest stable ones. bug #551248
RDEPEND="python? ( ${PYTHON_DEPS} )"
DEPEND="${RDEPEND}
	virtual/os-headers:51500"
BDEPEND="${RDEPEND}
	dev-util/gperf
	python? (
		${DISTUTILS_DEPS}
		dev-python/cython[${PYTHON_USEDEP}]
	)
"

PATCHES=(
	"${FILESDIR}"/libseccomp-2.6.0-python-shared.patch
	"${FILESDIR}"/libseccomp-2.5.3-skip-valgrind.patch
	"${FILESDIR}"/${P}-drop-bogus-test.patch
	"${FILESDIR}"/${P}-aliasing.patch
	"${FILESDIR}"/${P}-bounds.patch
)

src_prepare() {
	default

	if [[ ${PV} == *9999 ]] ; then
		sed -i -e "s/0.0.0/${PRERELEASE}/" configure.ac || die

		eautoreconf
	fi
}

multilib_src_configure() {
	local myeconfargs=(
		$(use_enable static-libs static)
		--disable-python
	)

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_compile() {
	emake

	if multilib_is_native_abi && use python ; then
		# setup.py expects libseccomp.so to live in "../.libs"
		# Copy the python files to the right place for this.
		rm -r "${BUILD_DIR}"/src/python || die
		cp -r "${S}"/src/python "${BUILD_DIR}"/src/python || die
		local -x CPPFLAGS="-I\"${BUILD_DIR}/include\" -I\"${S}/include\" ${CPPFLAGS}"

		# setup.py reads VERSION_RELEASE from the environment
		local -x VERSION_RELEASE=${PRERELEASE-${PV}}

		pushd "${BUILD_DIR}/src/python" >/dev/null || die
		distutils-r1_src_compile
		popd >/dev/null || die
	fi
}

multilib_src_test() {
	emake -Onone check
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	if multilib_is_native_abi ; then
		if use python ; then
			distutils-r1_src_install
		fi

		if use split-usr; then
			# need the libs in /
			gen_usr_ldscript -a seccomp
		fi
	fi
}

multilib_src_install_all() {
	find "${ED}" -type f -name "${PN}.la" -delete || die

	einstalldocs
}
