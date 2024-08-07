# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools flag-o-matic linux-info pam systemd usr-ldscript

DESCRIPTION="Tools and libraries to configure and manage kernel control groups"
HOMEPAGE="http://libcg.sourceforge.net/"
SRC_URI="https://downloads.sourceforge.net/project/libcg/${PN}/v${PV}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~ppc ~ppc64 ~riscv x86"
IUSE="+daemon pam static-libs systemd test +tools"
REQUIRED_USE="daemon? ( tools )"

# Use mount cgroup to build directory
# sandbox restricted to trivial build,
RESTRICT="test"

BDEPEND="
	app-alternatives/yacc
	app-alternatives/lex
	elibc_musl? ( sys-libs/fts-standalone )
"
DEPEND="pam? ( sys-libs/pam )"
RDEPEND="${DEPEND}"

# N.B. Upstream ebuild defines PATCHES twice, with different content :(
PATCHES=(
	"${FILESDIR}"/${P}-replace_DECLS.patch
	"${FILESDIR}"/${P}-replace_INLCUDES.patch
	"${FILESDIR}"/${P}-reorder-headers.patch
	"${FILESDIR}"/${P}-remove-umask.patch
	"${FILESDIR}"/${P}-slibtool.patch
	"${FILESDIR}"/${P}-remount.patch
)

pkg_setup() {
	local CONFIG_CHECK="~CGROUPS"
	if use daemon; then
		CONFIG_CHECK="${CONFIG_CHECK} ~CONNECTOR ~PROC_EVENTS"
	fi
	linux-info_pkg_setup
}

src_prepare() {
	default
	# Change rules file location
	sed -e 's:/etc/cgrules.conf:/etc/cgroup/cgrules.conf:' \
		-i src/libcgroup-internal.h || die "sed failed"
	sed -e 's:/etc/cgconfig.conf:/etc/cgroup/cgconfig.conf:' \
		-i src/libcgroup-internal.h || die "sed failed"
	sed -e 's:\(pam_cgroup_la_LDFLAGS.*\):\1\ -avoid-version:' \
		-i src/pam/Makefile.am || die "sed failed"

	# If we're not running tests, don't bother building them.
	if ! use test; then
		sed -i '/^SUBDIRS/s:tests::' Makefile.am || die
	fi

	# Workaround configure.in
	mv configure.in configure.ac || die

	eautoreconf
}

src_configure() {
	local my_conf

	if use pam; then
		my_conf=" --enable-pam-module-dir=$(getpam_mod_dir) "
	fi

	use elibc_musl && append-ldflags "-lfts"
	econf \
		$(use_enable static-libs static) \
		$(use_enable daemon) \
		$(use_enable pam) \
		$(use_enable tools) \
		${my_conf}
}

src_install() {
	default

	dodir /bin /sbin
	mv "${ED}"/usr/bin/* "${ED}"/bin/
	mv "${ED}"/usr/sbin/* "${ED}"/sbin/

	if use split-usr; then
		# need the libs in /
		gen_usr_ldscript -a cgroup
	fi

	find "${D}" -name '*.la' -delete || die

	insinto /etc/cgroup
	doins samples/*.conf

	if use tools; then
		newconfd "${FILESDIR}"/cgconfig.confd-r1 cgconfig
		newinitd "${FILESDIR}"/cgconfig.initd-r1 cgconfig
		if use systemd; then
			systemd_dounit "${FILESDIR}"/cgconfig.service
			systemd_dounit "${FILESDIR}"/cgrules.service
		fi
	fi

	if use daemon; then
		newconfd "${FILESDIR}"/cgred.confd-r2 cgred
		newinitd "${FILESDIR}"/cgred.initd-r1 cgred
	fi
}
