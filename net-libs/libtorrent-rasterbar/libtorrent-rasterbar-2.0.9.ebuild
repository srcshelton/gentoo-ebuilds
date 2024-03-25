# Copyright 2021-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} )
PARALLEL_MEMORY_MIN=4

inherit cmake flag-o-matic python-single-r1

DESCRIPTION="C++ BitTorrent implementation focusing on efficiency and scalability"
HOMEPAGE="https://libtorrent.org/ https://github.com/arvidn/libtorrent"
SRC_URI="https://github.com/arvidn/libtorrent/releases/download/v${PV}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0/2.0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc ~ppc64 ~riscv ~sparc x86"
IUSE="+dht debug gnutls python ssl test"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"
RESTRICT="!test? ( test )"

DEPEND="
	dev-libs/boost:=
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-libs/boost[python,${PYTHON_USEDEP}]
		')
	)
	ssl? (
		gnutls? ( net-libs/gnutls:= )
		!gnutls? ( dev-libs/openssl:= )
	)
"
RDEPEND="${DEPEND}"
BDEPEND="python? (
		$(python_gen_cond_dep '
			dev-python/setuptools[${PYTHON_USEDEP}]
		')
	)"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_configure() {
	if (( ( $( # <- Syntax
			head /proc/meminfo |
				grep -m 1 '^MemAvailable:' |
				awk '{ print $2 }'
		) / ( 1024 * 1024 ) ) < PARALLEL_MEMORY_MIN ))
	then
		if [[ "${EMERGE_DEFAULT_OPTS:-}" == *-j* ]]; then
			ewarn "make.conf or environment contains parallel build directive,"
			ewarn "memory usage may be increased (or adjust \$EMERGE_DEFAULT_OPTS)"
		fi
		ewarn "Lowering make parallelism for low-memory build-host ..."
		if ! [[ -n "${MAKEOPTS:-}" ]]; then
			export MAKEOPTS='-j1'
		elif ! [[ "${MAKEOPTS}" == *-j* ]]; then
			export MAKEOPTS="-j1 ${MAKEOPTS}"
		else
			export MAKEOPTS="-j1 $( sed 's/-j\s*[0-9]\+//' <<<"${MAKEOPTS}" )"
		fi
		if test-flag-CCLD '-Wl,--no-keep-memory'; then
			ewarn "Instructing 'ld' to use less memory ..."
			append-ldflags '-Wl,--no-keep-memory'
		fi
		ewarn "Disabling LTO support ..."
		filter-lto
	fi

	local mycmakeargs=(
		-DCMAKE_CXX_STANDARD=17
		-DBUILD_SHARED_LIBS=ON
		-Dbuild_examples=OFF
		-Ddht=$(usex dht ON OFF)
		-Dencryption=$(usex ssl ON OFF)
		-Dgnutls=$(usex gnutls ON OFF)
		-Dlogging=$(usex debug ON OFF)
		-Dpython-bindings=$(usex python ON OFF)
		-Dbuild_tests=$(usex test ON OFF)
	)

	# We need to drop the . from the Python version to satisfy Boost's
	# FindBoost.cmake module, bug #793038.
	use python && mycmakeargs+=( -Dboost-python-module-name="${EPYTHON/./}" )

	cmake_src_configure
}

src_test() {
	local myctestargs=(
		# Needs running UPnP server
		-E "test_upnp"
	)

	# Checked out Fedora's test workarounds for inspiration
	# https://src.fedoraproject.org/rpms/rb_libtorrent/blob/rawhide/f/rb_libtorrent.spec#_120
	# -j1 for https://bugs.gentoo.org/854603#c1
	LD_LIBRARY_PATH="${BUILD_DIR}:${LD_LIBRARY_PATH}" cmake_src_test -j1
}
