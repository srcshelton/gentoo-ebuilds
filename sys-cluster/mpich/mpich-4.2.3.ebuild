# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

FORTRAN_NEEDED=fortran
FORTRAN_STANDARD="77 90"

# Defaults to '3', reduce for a quicker build...
EBUILD_MPICH_YAKSA_DEPTH='2'

inherit autotools fortran-2 flag-o-matic multilib-minimal

MY_PV=${PV/_/}
DESCRIPTION="A high performance and portable MPI implementation"
HOMEPAGE="https://www.mpich.org/"
SRC_URI="https://www.mpich.org/static/downloads/${PV}/${P}.tar.gz
	https://raw.githubusercontent.com/pmodels/mpich/refs/tags/v${PV}/README.vin -> ${P}.README.vin"
S="${WORKDIR}"/${PN}-${MY_PV}

LICENSE="mpich2"
SLOT="0"
KEYWORDS="amd64 arm64 ~hppa ~ppc ppc64 ~riscv x86 ~amd64-linux ~x86-linux"
IUSE="+cxx debug doc fortran mpi-threads +romio threads valgrind"
REQUIRED_USE="mpi-threads? ( threads )"

COMMON_DEPEND="
	>=dev-libs/libaio-0.3.109-r5[${MULTILIB_USEDEP}]
	>=sys-apps/hwloc-2.0.2:=[${MULTILIB_USEDEP}]
	romio? ( net-fs/nfs-utils )
"

BDEPEND="
	app-shells/bash
	sys-libs/libunwind:=[${MULTILIB_USEDEP}]
"
DEPEND="
	${COMMON_DEPEND}
	dev-lang/perl
	dev-build/libtool
	valgrind? ( dev-debug/valgrind )
"
RDEPEND="
	${COMMON_DEPEND}
	app-shells/bash
	sys-devel/gcc
	!sys-cluster/mpich2
	!sys-cluster/openmpi
	!sys-cluster/nullmpi
"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/mpicxx.h
	/usr/include/mpi.h
	/usr/include/opa_config.h
)

#PATCHES=(
#	"${FILESDIR}"/${PN}-3.3-add-external-libdir-parameter.patch
#)

src_prepare() {
	default

	# Using MPICHLIB_LDFLAGS doesn't seem to fully work.
	sed -i 's| *@WRAPPER_LDFLAGS@ *||' \
		src/packaging/pkgconfig/mpich.pc.in \
		src/env/*.in \
		|| die

	# Fix m4 files to satisfy lib dir with multilib.
	#touch -r src/pm/hydra/confdb/aclocal_libs.m4 \
	#	confdb/aclocal_libs.m4 \
	#	|| die
	#cp -fp confdb/aclocal_libs.m4 \
	#	src/pm/hydra/confdb/aclocal_libs.m4 \
	#	|| die
	#cp -fp confdb/aclocal_libs.m4 \
	#	src/pm/hydra/mpl/confdb/aclocal_libs.m4 \
	#	|| die
	#cd src/pm/hydra/mpl; eautoreconf; cd -
	#cd src/pm/hydra; eautoreconf; cd -
	#eautoreconf

	if [ -n "${EBUILD_MPICH_YAKSA_DEPTH:-}" ]; then
		cp "${DISTDIR}/${P}.README.vin" "${S}/README.vin" || die
		sed -re "/early_returns = func.'earlyreturn'.\.split.',.s.'./ s|\('(,.s.)'\)|(r'\1')|" \
		    -i "${S}/maint/local_python/binding_c.py" || die
		${S}/autogen.sh -yaksa-depth=${EBUILD_MPICH_YAKSA_DEPTH} || die
		eautoreconf || die
	fi
}

multilib_src_configure() {
	local -a myconf=()

	# The configure statements can be somewhat confusing, as they
	# don't all show up in the top level configure, however, they
	# are picked up in the children directories.  Hence the separate
	# local vars.

	if use mpi-threads; then
		# MPI-THREAD requries threading.
		myconf+=(
			--with-thread-package=pthreads
			--enable-threads=runtime
		)
	else
		if use threads ; then
			myconf+=( --with-thread-package=pthreads )
		else
			myconf+=(--with-thread-package=none )
		fi
		myconf+=( --enable-threads=single )
	fi

	myconf+=( --sysconfdir=${EPREFIX}/etc/${PN} )

	use debug || myconf+=( --enable-g=none --disable-fast )
	use debug && myconf+=( --enable-fast=all )

	# GCC 10 compatibility workaround
	# bug #725842
	append-fflags $(test-flags-FC -fallow-argument-mismatch)
	append-flags -fno-associative-math

	export MPICHLIB_CFLAGS="${CFLAGS}"
	export MPICHLIB_CPPFLAGS="${CPPFLAGS}"
	export MPICHLIB_CXXFLAGS="${CXXFLAGS}"
	export MPICHLIB_FFLAGS="${FFLAGS}"
	export MPICHLIB_FCFLAGS="${FCFLAGS}"
	export MPICHLIB_LDFLAGS="${LDFLAGS}"

	# Dropped w/ bug #725842 fix
	#unset CFLAGS CPPFLAGS CXXFLAGS FFLAGS FCFLAGS LDFLAGS

	myconf+=(
		--enable-shared
		--with-hwloc-prefix="${EPREFIX}/usr"
		--with-hwloc-libdir="$(get_libdir)"
		--with-common-libdir="$(get_libdir)"
		--with-prefix-libdir="$(get_libdir)"
		--with-pm=hydra
		--without-ze
		--enable-versioning
		$(use_enable romio)
		$(use_enable cxx)
		$(use_enable fortran)
		$(use_with valgrind)
	)
	# Forcing Bash as there's quite a few bashisms in the build system
	#
	CONFIG_SHELL="${BROOT}/bin/bash" ECONF_SOURCE=${S} econf "${myconf[@]}"
}

multilib_src_test() {
	export USE_VALGRIND=0 #884809
	emake -j1 check
}

multilib_src_install() {
	default

	# fortran header cannot be wrapped (bug #540508), workaround part 1
	if use fortran; then
		if multilib_is_native_abi; then
			mkdir "${T}"/fortran || die
			mv "${ED}"/usr/include/mpif* "${T}"/fortran || die
			mv "${ED}"/usr/include/*.mod "${T}"/fortran || die
		else
			rm "${ED}"/usr/include/mpif* "${ED}"/usr/include/*.mod || die
		fi
	fi
}

multilib_src_install_all() {
	# Fortran header cannot be wrapped (bug #540508), workaround part 2
	if use fortran; then
		mv "${T}"/fortran/* "${ED}"/usr/include || die
	fi

	einstalldocs
	newdoc src/pm/hydra/README README.hydra
	if use romio; then
		newdoc src/mpi/romio/README README.romio
	fi

	if ! use doc; then
		rm -rf "${ED}"/usr/share/doc/${PF}/www* || die
	fi
}
