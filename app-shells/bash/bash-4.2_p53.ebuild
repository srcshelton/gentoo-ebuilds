# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-shells/bash/bash-4.2_p53.ebuild,v 1.4 2014/10/08 06:21:18 armin76 Exp $

EAPI="4"

inherit eutils flag-o-matic toolchain-funcs multilib prefix

# Official patchlevel
# See ftp://ftp.cwru.edu/pub/bash/bash-4.2-patches/
PLEVEL=${PV##*_p}
MY_PV=${PV/_p*}
MY_PV=${MY_PV/_/-}
MY_P=${PN}-${MY_PV}
[[ ${PV} != *_p* ]] && PLEVEL=0
patches() {
	local opt=$1 plevel=${2:-${PLEVEL}} pn=${3:-${PN}} pv=${4:-${MY_PV}}
	[[ ${plevel} -eq 0 ]] && return 1
	eval set -- {1..${plevel}}
	set -- $(printf "${pn}${pv/\.}-%03d " "$@")
	if [[ ${opt} == -s ]] ; then
		echo "${@/#/${DISTDIR}/}"
	else
		local u
		for u in ftp://ftp.cwru.edu/pub/bash mirror://gnu/${pn} ; do
			printf "${u}/${pn}-${pv}-patches/%s " "$@"
		done
	fi
}

# The version of readline this bash normally ships with.
READLINE_VER="6.2"

DESCRIPTION="The standard GNU Bourne again shell"
HOMEPAGE="http://tiswww.case.edu/php/chet/bash/bashtop.html"
SRC_URI="mirror://gnu/bash/${MY_P}.tar.gz $(patches)"

LICENSE="GPL-3"
SLOT="${MY_PV}"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
KEYWORDS+="~ppc-aix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="afs bashlogger examples mem-scramble +net nls plugins +readline static -system-shell"

LIB_DEPEND=">=sys-libs/ncurses-5.2-r2[static-libs(+)]
	nls? ( virtual/libintl )
	readline? ( >=sys-libs/readline-6.2[static-libs(+)] )"
RDEPEND="!static? ( ${LIB_DEPEND//\[static-libs(+)]} )"
# we only need yacc when the .y files get patched (bash42-005)
DEPEND="${RDEPEND}
	virtual/yacc
	static? ( ${LIB_DEPEND} )"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	if is-flag -malign-double ; then #7332
		eerror "Detected bad CFLAGS '-malign-double'.  Do not use this"
		eerror "as it breaks LFS (struct stat64) on x86."
		die "remove -malign-double from your CFLAGS mr ricer"
	fi
	if use bashlogger ; then
		ewarn "bash logging should ONLY be used in restricted (i.e. honeypot) environments."
		ewarn "Enabling this will log EVERYTHING you enter into the shell - you have been warned."
	fi
}

src_unpack() {
	unpack ${MY_P}.tar.gz
}

src_prepare() {
	# Include official patches
	[[ ${PLEVEL} -gt 0 ]] && epatch $(patches -s)

	# Clean out local libs so we know we use system ones
	rm -rf lib/{readline,termcap}/*
	touch lib/{readline,termcap}/Makefile.in # for config.status
	sed -ri -e 's:\$[(](RL|HIST)_LIBSRC[)]/[[:alpha:]]*.h::g' Makefile.in || die

	# Avoid regenerating docs after patches #407985
	sed -i -r '/^(HS|RL)USER/s:=.*:=:' doc/Makefile.in || die
	touch -r . doc/*

	epatch "${FILESDIR}"/${PN}-4.2-execute-job-control.patch #383237
	epatch "${FILESDIR}"/${PN}-4.2-parallel-build.patch
	epatch "${FILESDIR}"/${PN}-4.2-no-readline.patch
	epatch "${FILESDIR}"/${PN}-4.2-read-retry.patch #447810
	epatch "${FILESDIR}"/${PN}-4.2-speed-up-read-N.patch

	# this adds additional prefixes
	epatch "${FILESDIR}"/${PN}-4.0-configs-prefix.patch
	eprefixify pathnames.h.in

	epatch "${FILESDIR}"/${PN}-4.0-bashintl-in-siglist.patch
	epatch "${FILESDIR}"/${PN}-4.0-cflags_for_build.patch

	epatch "${FILESDIR}"/${PN}-4.2-darwin13.patch # patch from 4.3
	epatch "${FILESDIR}"/${PN}-4.1-blocking-namedpipe.patch # aix lacks /dev/fd/
	epatch "${FILESDIR}"/${PN}-4.0-childmax-pids.patch # AIX, Interix
	if [[ ${CHOST} == *-interix* ]]; then
		epatch "${FILESDIR}"/${PN}-4.0-interix-x64.patch
	fi

	# Include appropriate headers, to satisfy clang and avoid -Wimplicit-function-declaration
	epatch "${FILESDIR}"/${PN}-4.2-signal.h.patch

	# Fix not to reference a disabled symbol if USE=-readline, breaks
	# Darwin, bug #500932
	if ! use readline ; then
		sed -i -e 's/enable_hostname_completion//' builtins/shopt.def || die
	fi

	# Nasty trick to set bashbug's shebang to bash instead of sh. We don't have
	# sh while bootstrapping for the first time, This works around bug 309825
	sed -i -e '1s:sh:bash:' support/bashbug.sh || die

	# modify the bashrc file for prefix
	pushd "${T}" > /dev/null || die
	cp "${FILESDIR}"/bashrc .
	epatch "${FILESDIR}"/bashrc-prefix.patch
	eprefixify bashrc
	popd > /dev/null

	# DON'T YOU EVER PUT eautoreconf OR SIMILAR HERE!  THIS IS A CRITICAL
	# PACKAGE THAT MUST NOT RELY ON AUTOTOOLS, USE A SELF-SUFFICIENT PATCH
	# INSTEAD!!!

	epatch_user
}

src_configure() {
	local myconf=()

	# For descriptions of these, see config-top.h
	# bashrc/#26952 bash_logout/#90488 ssh/#24762 mktemp/#574426
	if use prefix ; then
		append-cppflags \
			-DDEFAULT_PATH_VALUE=\'\"${EPREFIX}/usr/sbin:${EPREFIX}/usr/bin:${EPREFIX}/sbin:${EPREFIX}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\' \
			-DSTANDARD_UTILS_PATH=\'\"${EPREFIX}/bin:${EPREFIX}/usr/bin:${EPREFIX}/sbin:${EPREFIX}/usr/sbin:/bin:/usr/bin:/sbin:/usr/sbin\"\' \
			-DSYS_BASHRC=\'\"${EPREFIX}/etc/bash/bashrc\"\' \
			-DSYS_BASH_LOGOUT=\'\"${EPREFIX}/etc/bash/bash_logout\"\' \
			-DNON_INTERACTIVE_LOGIN_SHELLS \
			-DSSH_SOURCE_BASHRC \
			-DUSE_MKTEMP -DUSE_MKSTEMP \
			$(use bashlogger && echo -DSYSLOG_HISTORY)
	else
		append-cppflags \
			-DDEFAULT_PATH_VALUE=\'\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\' \
			-DSTANDARD_UTILS_PATH=\'\"/bin:/usr/bin:/sbin:/usr/sbin\"\' \
			-DSYS_BASHRC=\'\"/etc/bash/bashrc\"\' \
			-DSYS_BASH_LOGOUT=\'\"/etc/bash/bash_logout\"\' \
			-DNON_INTERACTIVE_LOGIN_SHELLS \
			-DSSH_SOURCE_BASHRC \
			-DUSE_MKTEMP -DUSE_MKSTEMP \
			$(use bashlogger && echo -DSYSLOG_HISTORY)
	fi

	# IRIX's MIPSpro produces garbage with >= -O2, bug #209137
	[[ ${CHOST} == mips-sgi-irix* ]] && replace-flags -O? -O1

	if [[ ${CHOST} == *-aix* ]] || [[ ${CHOST} == *-hpux* ]] ; then
		# Avoid finding tgetent() in anything else but ncurses library,
		# as <termcap.h> is provided by ncurses, even during bootstrap
		# on AIX and HP-UX, and we would get undefined symbols like
		# BC, PC, UP if linking against something else.
		# The bash-bug is that it doesn't check for <termcap.h> provider,
		# and unfortunately {,n}curses is checked last.
		# Even if ncurses provides libcurses.so->libncurses.so symlink,
		# it feels more clean to link against libncurses.so directly.
		# (all configure-variables for tgetent() are shown here)
		export ac_cv_func_tgetent=no
		export ac_cv_lib_termcap_tgetent=no # found on HP-UX
		export ac_cv_lib_tinfo_tgetent=no
		export ac_cv_lib_curses_tgetent=no # found on AIX
		#export ac_cv_lib_ncurses_tgetent=no
	fi

	# Don't even think about building this statically without
	# reading Bug 7714 first.  If you still build it statically,
	# don't come crying to us with bugs ;).
	use static && append-ldflags -static
	use nls || myconf+=( --disable-nls )

	# Historically, we always used the builtin readline, but since
	# our handling of SONAME upgrades has gotten much more stable
	# in the PM (and the readline ebuild itself preserves the old
	# libs during upgrades), linking against the system copy should
	# be safe.
	# Exact cached version here doesn't really matter as long as it
	# is at least what's in the DEPEND up above.
	export ac_cv_rl_version=${READLINE_VER}

	# Force linking with system curses ... the bundled termcap lib
	# sucks bad compared to ncurses.  For the most part, ncurses
	# is here because readline needs it.  But bash itself calls
	# ncurses in one or two small places :(.

	if use plugins; then
		case "${CHOST}" in
			*-linux-gnu* | *-solaris* | *-freebsd* )
				if use system-shell; then
					append-ldflags -Wl,-rpath,"${EPREFIX}"/usr/$(get_libdir)/bash
				else
					append-ldflags -Wl,-rpath,"${EPREFIX}"/usr/$(get_libdir)/bash-"${SLOT}"
				fi
				;;
				# Darwin doesn't need an rpath here (in fact doesn't grok the argument)
		esac
	fi
	tc-export AR #444070
	econf \
		--with-installed-readline=. \
		--with-curses \
		$(use_with afs) \
		$(use_enable net net-redirections) \
		--disable-profiling \
		$(use_enable mem-scramble) \
		$(use_with mem-scramble bash-malloc) \
		$(use_enable readline) \
		$(use_enable readline history) \
		$(use_enable readline bang-history) \
		"${myconf[@]}"
}

src_compile() {
	default

	if use plugins ; then
		emake -C examples/loadables all others
	fi
}

src_install() {
	if ! use system-shell; then
		exeinto /bin
		newexe bash bash-"${SLOT}"

		if use plugins ; then
			exeinto /usr/$(get_libdir)/bash-"${SLOT}"
			doexe $( echo examples/loadables/*.o | sed 's:\.o::g' )
		fi

		newman doc/bash.1 bash-${SLOT}.1
		newman doc/builtins.1 builtins-${SLOT}.1

		insinto /usr/share/info
		newins doc/bashref.info bash-${SLOT}.info
		dosym bash-${SLOT}.info /usr/share/info/bashref-${SLOT}.info
	else
		default

		dodir /bin
		mv "${ED}"/usr/bin/bash "${ED}"/bin/bash || die
		dosym bash /bin/rbash

		insinto /etc/bash
		doins "${T}"/bashrc
		doins "${FILESDIR}"/bash_logout
		insinto /etc/skel
		for f in bash{_logout,_profile,rc} ; do
			newins "${FILESDIR}"/dot-${f} .${f}
		done

		local sed_args=(
			-e "s:#${USERLAND}#@::"
			-e '/#@/d'
		)
		if ! use readline ; then
			sed_args+=( #432338
				-e '/^shopt -s histappend/s:^:#:'
				-e 's:use_color=true:use_color=false:'
			)
		fi
		sed -i \
			"${sed_args[@]}" \
			"${ED}"/etc/skel/.bashrc \
			"${ED}"/etc/bash/bashrc || die

		if use plugins ; then
			exeinto /usr/$(get_libdir)/bash
			doexe $( echo examples/loadables/*.o | sed 's:\.o::g' )
			insinto /usr/include/bash-plugins
			doins *.h builtins/*.h examples/loadables/*.h include/*.h \
				lib/{glob/glob.h,tilde/tilde.h}
		fi

		doman doc/*.1

		insinto /usr/share/info
		newins doc/bashref.info bash.info
		dosym bash.info /usr/share/info/bashref.info
	fi

	if use examples ; then
		for d in examples/{functions,misc,scripts,scripts.noah,scripts.v2} ; do
			exeinto /usr/share/doc/${PF}/${d}
			insinto /usr/share/doc/${PF}/${d}
			for f in ${d}/* ; do
				if [[ ${f##*/} != PERMISSION ]] && [[ ${f##*/} != *README ]] ; then
					doexe ${f}
				else
					doins ${f}
				fi
			done
		done
	fi

	dodoc CHANGES COMPAT doc/FAQ doc/INTRO
	newdoc CWRU/changelog ChangeLog
}

pkg_preinst() {
	if use system-shell; then
		if [[ -e "${EROOT}"/etc/bashrc ]] && [[ ! -d "${EROOT}"/etc/bash ]] ; then
			mkdir -p "${EROOT}"/etc/bash
			mv -f "${EROOT}"/etc/bashrc "${EROOT}"/etc/bash/
		fi

		if [[ -L "${EROOT}"/bin/sh ]] ; then
			# rewrite the symlink to ensure that its mtime changes. having /bin/sh
			# missing even temporarily causes a fatal error with paludis.
			local target="$( readlink "${EROOT}"/bin/sh )"
			local tmp="$( emktemp "${EROOT}"/bin )"
			ln -sf "${target}" "${tmp}"
			mv -f "${tmp}" "${EROOT}"/bin/sh
		fi
	fi
}

pkg_postinst() {
	if use system-shell; then
		# If /bin/sh does not exist, provide it
		if [[ ! -e "${EROOT}"/bin/sh ]]; then
			ln -sf bash "${EROOT}"/bin/sh
		fi
	fi
}

# vi: set diffopt=iwhite,filler:
