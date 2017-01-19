# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: d6f3cff7e34659c93bafae4f107f37fa7a1d6b1a $

EAPI=5

inherit autotools eutils flag-o-matic pam toolchain-funcs user

DESCRIPTION="screen manager with VT100/ANSI terminal emulation"
HOMEPAGE="https://www.gnu.org/software/screen/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd ~hppa-hpux ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="debug multiuser nethack pam selinux +tmpfiles"

CDEPEND="
	>=sys-libs/ncurses-5.2:0=
	pam? ( virtual/pam )"
RDEPEND="${CDEPEND}
	selinux? ( sec-policy/selinux-screen )"
DEPEND="${CDEPEND}
	sys-apps/texinfo"

# Patches:
# - Don't use utempter even if it is found on the system.
PATCHES=(
	"${FILESDIR}"/${PN}-4.3.0-no-utempter.patch
)

pkg_setup() {
	# Make sure utmp group exists, as it's used later on.
	enewgroup utmp 406
}

src_prepare() {
	# Apply patches.
	epatch "${PATCHES[@]}"

	# sched.h is a system header and causes problems with some C libraries
	mv sched.h _sched.h || die
	sed -i '/include/ s:sched.h:_sched.h:' screen.h || die

	# Fix manpage.
	sed -i \
		-e "s:/usr/local/etc/screenrc:${EPREFIX}/etc/screenrc:g" \
		-e "s:/usr/local/screens:${EPREFIX}/var/run/screen:g" \
		-e "s:/local/etc/screenrc:${EPREFIX}/etc/screenrc:g" \
		-e "s:/etc/utmp:${EPREFIX}/var/run/utmp:g" \
		-e "s:/local/screens/S\\\-:${EPREFIX}/var/run/screen/S\\\-:g" \
		doc/screen.1 \
		|| die

	if [[ ${CHOST} == *-darwin* ]] ; then
		sed -i -e '/^#define UTMPOK/s/define/undef/' acconfig.h || die
	fi

	# reconfigure
	eautoreconf
}

src_configure() {
	append-cppflags "-DMAXWIN=${MAX_SCREEN_WINDOWS:-100}"

	if [[ ${CHOST} == *-solaris* ]] ; then
		# https://lists.gnu.org/archive/html/screen-devel/2014-04/msg00095.html
		append-cppflags -D_XOPEN_SOURCE \
			-D_XOPEN_SOURCE_EXTENDED=1 \
			-D__EXTENSIONS__
		append-libs -lsocket -lnsl
	fi

	use nethack || append-cppflags "-DNONETHACK"
	use debug && append-cppflags "-DDEBUG"

	econf \
		--with-socket-dir="${EPREFIX}/var/run/screen" \
		--with-sys-screenrc="${EPREFIX}/etc/screenrc" \
		--with-pty-mode=0620 \
		--with-pty-group=5 \
		--enable-rxvt_osc \
		--enable-telnet \
		--enable-colors256 \
		$(use_enable pam)
}

src_compile() {
	LC_ALL=POSIX emake comm.h term.h
	emake osdef.h

	emake -C doc screen.info
	default
}

src_install() {
	local tmpfiles_perms="0775" tmpfiles_group="utmp"

	dobin screen

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
		use prefix || fperms 4755 /usr/bin/screen
		tmpfiles_perms="0755"
		tmpfiles_group="root"
	else
		use prefix || fowners root:utmp /usr/bin/screen
		fperms 2755 /usr/bin/screen
	fi

	if use tmpfiles; then
		dodir /etc/tmpfiles.d
		echo "d /var/run/screen ${tmpfiles_perms} root ${tmpfiles_group}" \
			> "${ED}"/etc/tmpfiles.d/screen.conf
	fi

	insinto /usr/share/screen
	doins terminfo/{screencap,screeninfo.src}
	insinto /usr/share/screen/utf8encodings
	doins utf8encodings/??
	insinto /etc
	doins "${FILESDIR}"/screenrc

	pamd_mimic_system screen auth

	dodoc \
		README ChangeLog INSTALL TODO NEWS* patchlevel.h \
		doc/{FAQ,README.DOTSCREEN,fdpat.ps,window_to_display.ps}

	doman doc/screen.1
	doinfo doc/screen.info
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
			ewarn "Having to re-set permissions of '${EPREFIX}/usr/bin/screen' from $(
				stat -Lc '%a' "${EPREFIX}/usr/bin/screen"
			) to 4751 (-rwsr-x--x)"
			chmod 4751 "${EPREFIX}/usr/bin/screen"
		fi
	else
		if (( 2751 != $( stat -Lc '%a' "${EPREFIX}/usr/bin/screen" ) )); then
			ewarn "Having to re-set permissions of '${EPREFIX}/usr/bin/screen' from $(
				stat -Lc '%a' "${EPREFIX}/usr/bin/screen"
			) to 2751 (-rwx-r-s--x)"
			chmod 2751 "${EPREFIX}/usr/bin/screen"
		fi
	fi

	# Add /var/run/screen in case it doesn't exist yet. This should solve
	# problems like bug #508634 where tmpfiles.d isn't in effect.
	if [[ ! -d "${rundir}" || "$( stat -Lc '%a' "${rundir}" )" != "${tmpfiles_perms}" ]] ; then
		mkdir -p "${rundir}"
		chmod "${tmpfiles_perms}" "${rundir}"
		use prefix || chgrp ${tmpfiles_group} "${rundir}"
	fi

	if [[ -z ${REPLACING_VERSIONS} ]]
	then
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
}

# vi: set diffopt=iwhite,filler:
