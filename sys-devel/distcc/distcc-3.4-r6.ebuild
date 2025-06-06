# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )

inherit autotools flag-o-matic prefix python-single-r1 systemd

DESCRIPTION="Distribute compilation of C code across several machines on a network"
HOMEPAGE="https://github.com/distcc/distcc"
SRC_URI="https://github.com/distcc/distcc/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="gssapi gtk hardened ipv6 selinux systemd xinetd zeroconf"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	dev-libs/popt
	gssapi? ( net-libs/libgssglue )
	gtk? ( x11-libs/gtk+:3 )
	zeroconf? ( >=net-dns/avahi-0.6[dbus] )
"
DEPEND="
	${RDEPEND}
	sys-libs/binutils-libs
"
BDEPEND="
	${PYTHON_DEPS}
	dev-build/autoconf-archive
	virtual/pkgconfig
"
RDEPEND+="
	acct-user/distcc
	>=dev-util/shadowman-4
	>=sys-devel/gcc-config-1.4.1
	selinux? ( sec-policy/selinux-distcc )
	xinetd? ( sys-apps/xinetd )
"

PATCHES=(
	"${FILESDIR}/${PN}-3.0-xinetd.patch"
	# SOCKSv5 support needed for Portage, bug #537616
	"${FILESDIR}/${PN}-3.2_rc1-socks5.patch"
	"${FILESDIR}/${P}-fix-dcc_gcc_rewrite_fqn-corruption.patch"
	"${FILESDIR}/${P}-rewrite-chost.patch"
)

src_prepare() {
	default

	# Bugs #120001, #167844 and probably more. See patch for description.
	use hardened && eapply "${FILESDIR}/distcc-hardened.patch"

	sed \
		-e "s:@EPREFIX@:${EPREFIX:-/}:" \
		"${FILESDIR}/distcc-config-r1" > "${T}/distcc-config" || die

	# TODO: gdb tests fail due to gdb failing to find .c file
	sed -i -e '/Gdb.*Case,/d' test/testdistcc.py || die

	hprefixify update-distcc-symlinks.py src/{serve,daemon}.c
	python_fix_shebang update-distcc-symlinks.py "${T}/distcc-config"
	eautoreconf
}

src_configure() {
	# https://github.com/distcc/distcc/issues/454
	append-cppflags -DPY_SSIZE_T_CLEAN

	local myconf=(
		--disable-Werror
		--libdir="${EPREFIX}"/usr/lib
		$(use_enable ipv6 rfc2553)
		$(use_with gtk)
		--without-gnome
		$(use_with gssapi auth)
		$(use_with zeroconf avahi)

		# NB: we can't pass --disable-pump-mode as it disables Python
		# detection; we instead hack it out below
	)

	econf "${myconf[@]}"
}

src_compile() {
	# override PYTHON= to prevent setup.py from running
	emake PYTHON=''
}

src_test() {
	# sandbox breaks some tests, and hangs some too
	# retest once #590084 is fixed
	local -x SANDBOX_ON=0
	# run the main test suite directly to skip pump tests
	emake -j1 distcc-maintainer-check
}

src_install() {
	# override GZIP_BIN to stop it from compressing manpages
	emake -j1 DESTDIR="${D}" GZIP_BIN=false PYTHON='' install
	python_optimize

	newinitd "${FILESDIR}/distccd.initd" distccd
	if use systemd; then
		systemd_newunit "${FILESDIR}/distccd.service-1" distccd.service
		systemd_install_serviced "${FILESDIR}/distccd.service.conf"
	fi

	cp "${FILESDIR}/distccd.confd" "${T}/distccd" || die
	if use zeroconf; then
		cat >> "${T}/distccd" <<-EOF || die

		# Enable zeroconf support in distccd
		DISTCCD_OPTS="\${DISTCCD_OPTS} --zeroconf"
		EOF

		if use systemd; then
			sed -i '/ExecStart/ s|$| --zeroconf|' "${D}$(systemd_get_systemunitdir)"/distccd.service || die
		fi
	fi
	doconfd "${T}/distccd"

	newenvd - 02distcc <<-EOF || die
		# This file is managed by distcc-config; use it to change these settings.
		# DISTCC_LOG and DISTCC_DIR should not be set.
		DISTCC_VERBOSE="${DISTCC_VERBOSE:-0}"
		DISTCC_FALLBACK="${DISTCC_FALLBACK:-1}"
		DISTCC_SAVE_TEMPS="${DISTCC_SAVE_TEMPS:-0}"
		DISTCC_TCP_CORK="${DISTCC_TCP_CORK}"
		DISTCC_SSH="${DISTCC_SSH}"
		UNCACHED_ERR_FD="${UNCACHED_ERR_FD}"
		DISTCC_ENABLE_DISCREPANCY_EMAIL="${DISTCC_ENABLE_DISCREPANCY_EMAIL}"
		DCC_EMAILLOG_WHOM_TO_BLAME="${DCC_EMAILLOG_WHOM_TO_BLAME}"
	EOF

	keepdir /usr/lib/distcc

	dobin "${T}/distcc-config"

	if use gtk; then
		einfo "Renaming /usr/bin/distccmon-gnome to /usr/bin/distccmon-gui"
		einfo "This is to have a little sensability in naming schemes between distccmon programs"
		mv "${ED}/usr/bin/distccmon-gnome" "${ED}/usr/bin/distccmon-gui" || die
		dosym distccmon-gui /usr/bin/distccmon-gnome
	fi

	if use xinetd; then
		insinto /etc/xinetd.d
		newins "doc/example/xinetd" distcc
	fi

	insinto /usr/share/shadowman/tools
	newins - distcc <<<"${EPREFIX}/usr/lib/distcc"

	rm -r "${ED}/etc/default" || die
	rm "${ED}/etc/distcc/clients.allow" || die
	rm "${ED}/etc/distcc/commands.allow.sh" || die
}

pkg_preinst() {
	# Compatibility symlink for Portage
	dosym . /usr/lib/distcc/bin
	if [[ -e ${EROOT}/usr/lib/distcc/bin && ! -L ${EROOT}/usr/lib/distcc/bin ]]; then
		rm -rf "${EROOT}"/usr/lib/distcc/bin || die
	fi
}

pkg_postinst() {
	# remove the old paths when switching from libXX to lib
	if [[ $(get_libdir) != lib && ${SYMLINK_LIB} != yes && \
			-d ${EROOT}/usr/$(get_libdir)/distcc ]]; then
		rm -r -f "${EROOT}/usr/$(get_libdir)/distcc" || die
	fi

	if [[ -z "${ROOT}" || "${ROOT}" == '/' ]]; then
		eselect compiler-shadow update distcc
	fi

	elog
	elog "Tips on using distcc with Gentoo can be found at"
	elog "https://wiki.gentoo.org/wiki/Distcc"
	elog
	ewarn "distcc-pump is broken and no longer installed."
	elog
	elog "To use the distccmon programs with Gentoo you should use this command:"
	elog "# DISTCC_DIR=\"${DISTCC_DIR:-${BUILD_PREFIX}/.distcc}\" distccmon-text 5"

	if use gtk; then
		elog "Or:"
		elog "# DISTCC_DIR=\"${DISTCC_DIR:-${BUILD_PREFIX}/.distcc}\" distccmon-gnome"
	fi
}

pkg_prerm() {
	if [[ -z ${REPLACED_BY_VERSION} ]] && [[ -z "${ROOT}" || "${ROOT}" == '/' ]]; then
		eselect compiler-shadow remove distcc
	fi
}

# vi: set diffopt=filler,iwhite:
