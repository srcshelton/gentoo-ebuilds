# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Keep an eye on Fedora's packaging (https://src.fedoraproject.org/rpms/libcap-ng/tree/rawhide) for patches
# Same maintainer in Fedora as upstream
PYTHON_COMPAT=( python3_{10..13} )
inherit autotools flag-o-matic out-of-source-utils python-r1 usr-ldscript

DESCRIPTION="POSIX 1003.1e capabilities"
HOMEPAGE="https://people.redhat.com/sgrubb/libcap-ng/"
SRC_URI="https://people.redhat.com/sgrubb/${PN}/${P}.tar.gz"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x86-linux"
IUSE="python static-libs"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="python? ( ${PYTHON_DEPS} )"
DEPEND="
	${RDEPEND}
	virtual/os-headers
"
BDEPEND="python? ( >=dev-lang/swig-2 )"

PATCHES=(
	"${FILESDIR}"/${P}-python.patch
)

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	use sparc && replace-flags -O? -O0

	local ECONF_SOURCE="${S}"

	local myconf=(
		$(use_enable static-libs static)
		--with-capability_header="${ESYSROOT}"/usr/include/linux/capability.h
	)

	local pythonconf=(
		--without-python3
	)

	# Set up python bindings build(s)
	if use python ; then
		setup_python_flags_configure() {
			pythonconf=(
				--with-python3
			)

			run_in_build_dir econf "${pythonconf[@]}" "${myconf[@]}"
		}

		python_foreach_impl setup_python_flags_configure
	else
		local BUILD_DIR="${WORKDIR}"/build
		run_in_build_dir econf "${pythonconf[@]}" "${myconf[@]}"
	fi
}

src_compile() {
	if use python ; then
		python_foreach_impl run_in_build_dir emake
	else
		local BUILD_DIR="${WORKDIR}"/build
		emake -C "${BUILD_DIR}"
	fi
}

src_test() {
	if [[ "${EUID}" -eq 0 ]] ; then
		ewarn "Skipping tests due to root permissions."
		return
	fi

	if use python ; then
		python_foreach_impl run_in_build_dir emake check
	else
		local BUILD_DIR="${WORKDIR}"/build
		emake -C "${BUILD_DIR}" check
	fi
}

src_install() {
	if use python ; then
		python_foreach_impl run_in_build_dir emake DESTDIR="${D}" install
	else
		local BUILD_DIR="${WORKDIR}"/build
		emake -C "${BUILD_DIR}" DESTDIR="${D}" install
	fi

	if use split-usr ; then
		# need the libs in /
		gen_usr_ldscript -a cap-ng
	fi

	find "${ED}" -name '*.la' -delete || die
}
