# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic pam tmpfiles

DESCRIPTION="screen manager with VT100/ANSI terminal emulation"
HOMEPAGE="https://www.gnu.org/software/screen/"

if [[ ${PV} != 9999 ]] ; then
	SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
else
	inherit git-r3
	EGIT_REPO_URI="https://git.savannah.gnu.org/git/screen.git"
	EGIT_CHECKOUT_DIR="${WORKDIR}/${P}" # needed for setting S later on
	S="${WORKDIR}"/${P}/src
fi

LICENSE="GPL-3+"
SLOT="0"
IUSE="debug multiuser nethack pam selinux +tmpfiles"

DEPEND=">=sys-libs/ncurses-5.2:=
	virtual/libcrypt:=
	pam? ( sys-libs/pam )"
RDEPEND="${DEPEND}
	acct-group/utmp
	selinux? ( sec-policy/selinux-screen )"
BDEPEND="sys-apps/texinfo"

PATCHES=(
	# Don't use utempter even if it is found on the system.
	"${FILESDIR}"/${PN}-4.3.0-no-utempter.patch
	"${FILESDIR}"/${PN}-4.9.1-utmp-exit.patch
)

src_prepare() {
	default

	# sched.h is a system header and causes problems with some C libraries
	mv sched.h _sched.h || die
	sed -i '/include/ s:sched.h:_sched.h:' screen.h || die

	# Fix manpage
	sed -i \
		-e "s:/usr/local/etc/screenrc:${EPREFIX}/etc/screenrc:g" \
		-e "s:/usr/local/screens:${EPREFIX}/var/run/screen:g" \
		-e "s:/local/etc/screenrc:${EPREFIX}/etc/screenrc:g" \
		-e "s:/etc/utmp:${EPREFIX}/var/run/utmp:g" \
		-e "s:/local/screens/S\\\-:${EPREFIX}/var/run/screen/S\\\-:g" \
		doc/screen.1 || die

	if [[ ${CHOST} == *-darwin* ]] || use elibc_musl; then
		sed -i -e '/^#define UTMPOK/s/define/undef/' acconfig.h || die
	fi

	# disable musl dummy headers for utmp[x]
	use elibc_musl && append-cppflags "-D_UTMP_H -D_UTMPX_H"

	# reconfigure
	eautoreconf
}

src_configure() {
	append-lfs-flags
	append-cppflags "-DMAXWIN=${MAX_SCREEN_WINDOWS:-100}"

	if [[ ${CHOST} == *-solaris* ]]; then
		# enable msg_header by upping the feature standard compatible
		# with c99 mode
		append-cppflags -D_XOPEN_SOURCE=600
	fi

	use nethack || append-cppflags "-DNONETHACK"
	use debug && append-cppflags "-DDEBUG"

	local myeconfargs=(
		--with-socket-dir="${EPREFIX}/var/run/${PN}"
		--with-sys-screenrc="${EPREFIX}/etc/screenrc"
		--with-pty-mode=0620
		--with-pty-group=5
		--enable-rxvt_osc
		--enable-telnet
		--enable-colors256
		$(use_enable pam)
	)
	econf "${myeconfargs[@]}"
}

src_compile() {
	LC_ALL=POSIX emake comm.h term.h
	emake osdef.h

	emake -C doc screen.info
	default
}

src_install() {
	local DOCS=(
		README ChangeLog INSTALL TODO NEWS* patchlevel.h
		doc/{FAQ,README.DOTSCREEN,fdpat.ps,window_to_display.ps}
	)

	emake DESTDIR="${D}" SCREEN="${P}" install

	local tmpfiles_perms="0775" tmpfiles_group="utmp"

	#
	# In screen.c, the required directory mode, n, is defined as:
	# n = (eff_uid == 0 && (real_uid || (st.st_mode & 0775) != 0775)) ? 0755 : (eff_gid == (int)st.st_gid && eff_gid != real_gid) ? 0775 : 0777;
	# ... where st is the result of stat(SockDir, &st).
	#
	# ( eff_gid == (int)st.st_gid ) -> /var/run/screen does not have group:utmp, or /usr/bin/screen is not setgid;
	# ( eff_gid != real_gid ) -> /usr/bin/screen is not setgid, or user has utmp as their primary group.
	#
	# ... so it appears that /usr/bin/screen is being installed with incorrect permissions.
	#
	if use multiuser; then
		use prefix || fperms 4755 /usr/bin/${P}
		tmpfiles_perms="0755"
		tmpfiles_group="root"
	else
		use prefix || fowners root:utmp /usr/bin/${P}
		fperms 2755 /usr/bin/${P}
	fi

	if use tmpfiles; then
		newtmpfiles - screen.conf <<<"d /tmp/screen ${tmpfiles_perms} root ${tmpfiles_group}"
	fi

	insinto /usr/share/${PN}
	doins terminfo/{screencap,screeninfo.src}

	insinto /etc
	doins "${FILESDIR}"/screenrc

	if use pam; then
		pamd_mimic_system screen auth
	fi

	dodoc "${DOCS[@]}"
}

pkg_postinst() {
	local rundir="${EROOT%/}/var/run/screen"
	local tmpfiles_perms="0775" tmpfiles_group="utmp"

	if use multiuser; then
		tmpfiles_perms="0755"
		if ! use prefix; then
			tmpfiles_group="root"
		fi

		# Pre-merge permissions are being lost?!
		if (( 4751 != $( stat -Lc '%a' "${EPREFIX}/usr/bin/screen" ) )); then
			ewarn "Having to reset permissions of '${EPREFIX}/usr/bin/screen' from $(
				stat -Lc '%a' "${EPREFIX}/usr/bin/screen"
			) to 4751 (-rwsr-x--x)"
			chmod 4751 "${EPREFIX}/usr/bin/screen"
		fi
	else
		if (( 2751 != $( stat -Lc '%a' "${EPREFIX}/usr/bin/screen" ) )); then
			ewarn "Having to reset permissions of '${EPREFIX}/usr/bin/screen' from $(
				stat -Lc '%a' "${EPREFIX}/usr/bin/screen"
			) to 2751 (-rwx-r-s--x)"
			chmod 2751 "${EPREFIX}/usr/bin/screen"
		fi
	fi

	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "Some dangerous key bindings have been removed or changed to more safe values."
		elog "We enable some xterm hacks in our default screenrc, which might break some"
		elog "applications. Please check /etc/screenrc for information on these changes."
	fi

	if use prefix; then
		ewarn "In order to allow screen to work correctly, please execute:"
		ewarn "    chown root:utmp ${EPREFIX}/usr/bin/screen"
		if use multiuser; then
			ewarn "    chmod 4755 ${EPREFIX}/usr/bin/screen"
		else
			ewarn "    chmod 2755 ${EPREFIX}/usr/bin/screen"
		fi
		ewarn "    chown root:utmp ${rundir}"
		ewarn "... as a privileged user"
	fi

	if use tmpfiles; then
		tmpfiles_process screen.conf
	fi
}

# vi: set diffopt=iwhite,filler:
