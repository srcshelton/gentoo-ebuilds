# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic linux-info pam systemd usr-ldscript

DESCRIPTION="Tools and libraries to configure and manage kernel control groups"
HOMEPAGE="https://github.com/libcgroup/libcgroup"
SRC_URI="https://github.com/libcgroup/libcgroup/releases/download/v${PV}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~ppc ~ppc64 ~riscv x86"
IUSE="+daemon pam static-libs systemd test +tools"
REQUIRED_USE="daemon? ( tools )"

# Test failure needs investigation
RESTRICT="!test? ( test ) test"

DEPEND="
	elibc_musl? ( sys-libs/fts-standalone )
	pam? ( sys-libs/pam )
	systemd? ( sys-apps/systemd:= )
"
RDEPEND="${DEPEND}"
BDEPEND="
	sys-devel/bison
	sys-devel/flex
"

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
	find src -name '*.c' -o -name '*.h' -print0 \
		| xargs -0 sed -i '/^#define/s:/etc/cg:/etc/cgroup/cg:'
	sed -i 's:/etc/cg:/etc/cgroup/cg:' \
		doc/man/cg* samples/config/*.conf README* || die "sed failed"

	# Drop native libcgconfig init config
	sed -i '/^man_MANS/s:cgred.conf.5::' \
		doc/man/Makefile.am || die "sed failed"

	# If we're not running tests, don't bother building them.
	if ! use test; then
		sed -i '/^SUBDIRS/s:tests::' Makefile.am || die
	fi

	eautoreconf
}

src_configure() {
	if use elibc_musl; then
		append-ldflags -lfts
	fi

	# Needs flex+bison
	unset LEX YACC

	local myconf=(
		--disable-python
		$(use_enable static-libs static)
		$(use_enable daemon)
		$(use_enable pam)
		$(use_enable systemd)
		$(use_enable tools)
		$(use_enable test tests)
	)

	if use pam; then
		myconf+=( "--enable-pam-module-dir=$(getpam_mod_dir)" )
	fi

	econf "${myconf[@]}"
}

src_test() {
	# Run just the unit tests rather than the full lot as they
	# need fewer permissions, no containers, etc.
	emake -C tests/gunit check
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

	find "${ED}" -name '*.la' -delete || die

	insinto /etc/cgroup
	doins samples/config/cgconfig.conf
	doins samples/config/cgrules.conf
	doins samples/config/cgsnapshot_denylist.conf

	keepdir /etc/cgroup/cgconfig.d
	keepdir /etc/cgroup/cgrules.d

	if use tools; then
		newconfd "${FILESDIR}"/cgconfig.confd-r2 cgconfig
		newinitd "${FILESDIR}"/cgconfig.initd-r2 cgconfig
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
