# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

FORTRAN_NEEDED=fortran
inherit cuda flag-o-matic fortran-2 libtool multilib-minimal

MY_P=${P/-mpi}

IUSE_OPENMPI_FABRICS="
	openmpi_fabrics_ofed
	openmpi_fabrics_knem"

IUSE_OPENMPI_RM="
	openmpi_rm_pbs
	openmpi_rm_slurm"

IUSE_OPENMPI_OFED_FEATURES="
	openmpi_ofed_features_control-hdr-padding
	openmpi_ofed_features_udcm
	openmpi_ofed_features_rdmacm
	openmpi_ofed_features_dynamic-sl"

DESCRIPTION="A high-performance message passing library (MPI)"
HOMEPAGE="https://www.open-mpi.org"
SRC_URI="https://download.open-mpi.org/release/open-mpi/v$(ver_cut 1-2)/${P}.tar.bz2"
S="${WORKDIR}/${MY_P}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~loong ~ppc ppc64 ~riscv sparc x86 ~amd64-linux"
IUSE="cma cuda cxx fortran ipv6 libompitrace peruse romio valgrind
	${IUSE_OPENMPI_FABRICS} ${IUSE_OPENMPI_RM} ${IUSE_OPENMPI_OFED_FEATURES}"

REQUIRED_USE="
	openmpi_rm_slurm? ( !openmpi_rm_pbs )
	openmpi_rm_pbs? ( !openmpi_rm_slurm )
	openmpi_ofed_features_control-hdr-padding? ( openmpi_fabrics_ofed )
	openmpi_ofed_features_udcm? ( openmpi_fabrics_ofed )
	openmpi_ofed_features_rdmacm? ( openmpi_fabrics_ofed )
	openmpi_ofed_features_dynamic-sl? ( openmpi_fabrics_ofed )"

RDEPEND="
	!sys-cluster/mpich
	!sys-cluster/mpich2
	!sys-cluster/nullmpi
	!sys-cluster/pmix
	>=dev-libs/libevent-2.0.22:=[${MULTILIB_USEDEP},threads(+)]
	dev-libs/libltdl:0[${MULTILIB_USEDEP}]
	>=sys-apps/hwloc-2.0.2:=[${MULTILIB_USEDEP}]
	>=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
	cuda? ( >=dev-util/nvidia-cuda-toolkit-6.5.19-r1:= )
	openmpi_fabrics_ofed? ( sys-cluster/rdma-core )
	openmpi_fabrics_knem? ( sys-cluster/knem )
	openmpi_rm_pbs? ( sys-cluster/torque )
	openmpi_rm_slurm? ( sys-cluster/slurm )
	openmpi_ofed_features_rdmacm? ( sys-cluster/rdma-core )"
BDEPEND="sys-devel/flex"
DEPEND="${RDEPEND}
	valgrind? ( dev-debug/valgrind )"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/mpi.h
	/usr/include/openmpi/mpiext/mpiext_cuda_c.h
)

PATCHES=(
	"${FILESDIR}/${PN}-4.1.6-incompatible-pointers.patch"
)

pkg_setup() {
	fortran-2_pkg_setup

	elog
	elog "OpenMPI has an overwhelming count of configuration options."
	elog "Don't forget the EXTRA_ECONF environment variable can let you"
	elog "specify configure options if you find them necessary."
	elog
}

src_prepare() {
	default
	elibtoolize

	# Avoid test which ends up looking at system mounts
	echo "int main() { return 0; }" > test/util/opal_path_nfs.c || die

	# Necessary for scalibility, see
	# http://www.open-mpi.org/community/lists/users/2008/09/6514.php
	echo 'oob_tcp_listen_mode = listen_thread' \
		>> opal/etc/openmpi-mca-params.conf || die
}

multilib_src_configure() {
	# -Werror=lto-type-mismatch, -Werror=strict-aliasing
	# The former even prevents successfully running ./configure, but both appear
	# at `make` time as well.
	# https://bugs.gentoo.org/913040
	# https://github.com/open-mpi/ompi/issues/12674
	# https://github.com/open-mpi/ompi/issues/12675
	append-flags -fno-strict-aliasing
	filter-lto

	local myconf=(
		--disable-mpi-java
		# configure takes a looooong time, but upstream currently force
		# constriants on caching:
		# https://github.com/open-mpi/ompi/blob/9eec56222a5c98d13790c9ee74877f1562ac27e8/config/opal_config_subdir.m4#L118
		# so no --cache-dir for now.
		--enable-mpi-fortran=$(usex fortran all no)
		--enable-orterun-prefix-by-default
		--enable-pretty-print-stacktrace

		--sysconfdir="${EPREFIX}/etc/${PN}"

		--with-hwloc="${EPREFIX}/usr"
		--with-hwloc-libdir="${EPREFIX}/usr/$(get_libdir)"
		--with-libltdl="${EPREFIX}/usr"
		--with-libevent="${EPREFIX}/usr"
		--with-libevent-libdir="${EPREFIX}/usr/$(get_libdir)"
		# unkeyworded, lacks multilib. Do not automagically build against it.
		--with-pmix=internal

		# Re-enable for 5.0!
		# See https://github.com/open-mpi/ompi/issues/9697#issuecomment-1003746357
		# and https://bugs.gentoo.org/828123#c14
		--disable-heterogeneous

		$(use_enable cxx mpi-cxx)
		$(use_enable ipv6)
		$(use_enable libompitrace)
		$(use_enable peruse)
		$(use_enable romio io-romio)

		$(use_with cma)

		$(multilib_native_use_enable openmpi_ofed_features_control-hdr-padding openib-control-hdr-padding)
		$(multilib_native_use_enable openmpi_ofed_features_rdmacm openib-rdmacm)
		$(multilib_native_use_enable openmpi_ofed_features_udcm openib-udcm)
		$(multilib_native_use_enable openmpi_ofed_features_dynamic-sl openib-dynamic-sl)

		$(multilib_native_use_with cuda cuda "${EPREFIX}"/opt/cuda)
		$(multilib_native_use_with valgrind)
		$(multilib_native_use_with openmpi_fabrics_ofed verbs "${EPREFIX}"/usr)
		$(multilib_native_use_with openmpi_fabrics_knem knem "${EPREFIX}"/usr)
		$(multilib_native_use_with openmpi_rm_pbs tm)
		$(multilib_native_use_with openmpi_rm_slurm slurm)
	)

	CONFIG_SHELL="${BROOT}"/bin/bash ECONF_SOURCE="${S}" econf "${myconf[@]}"
}

multilib_src_compile() {
	emake V=1
}

multilib_src_test() {
	emake -C test check
}

multilib_src_install() {
	default

	# fortran header cannot be wrapped (bug #540508), workaround part 1
	if multilib_is_native_abi && use fortran; then
		mkdir "${T}"/fortran || die
		mv "${ED}"/usr/include/mpif* "${T}"/fortran || die
	else
		# some fortran files get installed unconditionally
		rm \
			"${ED}"/usr/include/mpif* \
			"${ED}"/usr/bin/mpif* \
			|| die
	fi
}

multilib_src_install_all() {
	# fortran header cannot be wrapped (bug #540508), workaround part 2
	if use fortran; then
		mv "${T}"/fortran/mpif* "${ED}"/usr/include || die
	fi

	# Remove la files, no static libs are installed and we have pkg-config
	find "${ED}" -name '*.la' -delete || die

	einstalldocs
}
