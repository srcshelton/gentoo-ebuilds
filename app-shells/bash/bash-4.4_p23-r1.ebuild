# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils flag-o-matic multilib prefix toolchain-funcs

# Official patchlevel
# See ftp://ftp.cwru.edu/pub/bash/bash-4.4-patches/
PLEVEL=${PV##*_p}
MY_PV=${PV/_p*}
MY_PV=${MY_PV/_/-}
MY_P=${PN}-${MY_PV}
is_release() {
	case ${PV} in
	*_alpha*|*_beta*|*_rc*) return 1 ;;
	*) return 0 ;;
	esac
}
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
READLINE_VER="7.0"

DESCRIPTION="The standard GNU Bourne again shell"
HOMEPAGE="http://tiswww.case.edu/php/chet/bash/bashtop.html"
if is_release ; then
	SRC_URI="mirror://gnu/bash/${MY_P}.tar.gz $(patches)"
else
	SRC_URI="ftp://ftp.cwru.edu/pub/bash/${MY_P}.tar.gz"
fi

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv s390 sparc x86 ~ppc-aix ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="afs bashlogger examples mem-scramble +net nls plugins +readline"

DEPEND="
	>=sys-libs/ncurses-5.2-r2:0=
	readline? ( >=sys-libs/readline-${READLINE_VER}:0= )
	nls? ( virtual/libintl )
"
RDEPEND="
	${DEPEND}
"
# we only need yacc when the .y files get patched (bash42-005)
#DEPEND+=" virtual/yacc"

PREFIX_PATCHES=(
	# Prefix patches:
	#  Use prefix root
	"${FILESDIR}"/${PN}-4.0-configs-prefix.patch
	#  Include appropriate headers, to satisfy clang and avoid -Wimplicit-function-declaration
	"${FILESDIR}"/${PN}-4.0-bashintl-in-siglist.patch
	"${FILESDIR}"/${PN}-4.2-signal.h.patch
	"${FILESDIR}"/${PN}-4.3-signal.h.patch
)

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	if is-flag -malign-double ; then #7332
		eerror "Detected bad CFLAGS '-malign-double'.  Do not use this"
		eerror "as it breaks LFS (struct stat64) on x86."
		die "remove -malign-double from your CFLAGS mr ricer"
	fi
	if use bashlogger ; then
		ewarn "The logging patch should ONLY be used in restricted (i.e. honeypot) envs."
		ewarn "This will log ALL output you enter into the shell, you have been warned."
	fi
}

src_unpack() {
	unpack ${MY_P}.tar.gz
}

src_prepare() {
	# Include official patches
	[[ ${PLEVEL} -gt 0 ]] && eapply -p0 $(patches -s)

	eapply "${FILESDIR}/${PN}-4.4-jobs_overflow.patch" #644720
	eapply "${FILESDIR}/${PN}-4.4-set-SHOBJ_STATUS.patch" #644720

	# Clean out local libs so we know we use system ones w/releases.
	if is_release ; then
		rm -rf lib/{readline,termcap}/*
		touch lib/{readline,termcap}/Makefile.in # for config.status
		sed -ri -e 's:\$[(](RL|HIST)_LIBSRC[)]/[[:alpha:]]*.h::g' Makefile.in || die
	fi

	# modify the bashrc file for prefix
	pushd "${T}" > /dev/null || die
	cp "${FILESDIR}"/bashrc .
	eapply "${FILESDIR}"/bashrc-prefix.patch
	eprefixify bashrc
	popd > /dev/null

	use prefix && epatch "${PREFIX_PATCHES[@]}"

	# Prefixify hardcoded path names. No-op for non-prefix.
	hprefixify pathnames.h.in

	# Avoid regenerating docs after patches #407985
	sed -i -r '/^(HS|RL)USER/s:=.*:=:' doc/Makefile.in || die
	touch -r . doc/*

	eapply_user
}

src_configure() {
	local myconf=(
		--disable-profiling
		--with-curses
		$(use_enable mem-scramble)
		$(use_enable net net-redirections)
		$(use_enable readline)
		$(use_enable readline bang-history)
		$(use_enable readline history)
		$(use_with afs)
		$(use_with mem-scramble bash-malloc)
	)

	# For descriptions of these, see config-top.h
	# bashrc/#26952 bash_logout/#90488 ssh/#24762 mktemp/#574426
	if use prefix ; then
		extrapaths='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
		extrautils='/bin:/usr/bin:/sbin:/usr/sbin'
	fi
	append-cppflags \
		-DDEFAULT_PATH_VALUE=\'\"${EPREFIX}/usr/local/sbin:${EPREFIX}/usr/local/bin:${EPREFIX}/usr/sbin:${EPREFIX}/usr/bin:${EPREFIX}/sbin:${EPREFIX}/bin${extrapaths:+:${extrapaths}}\"\' \
		-DSTANDARD_UTILS_PATH=\'\"${EPREFIX}/bin:${EPREFIX}/usr/bin:${EPREFIX}/sbin:${EPREFIX}/usr/sbin${extrautils:+:${extrautls}}\"\' \
		-DSYS_BASHRC=\'\"${EPREFIX}/etc/bash/bashrc\"\' \
		-DSYS_BASH_LOGOUT=\'\"${EPREFIX}/etc/bash/bash_logout\"\' \
		-DNON_INTERACTIVE_LOGIN_SHELLS \
		-DSSH_SOURCE_BASHRC \
		$(use bashlogger && echo -DSYSLOG_HISTORY)

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
	#use static && export LDFLAGS="${LDFLAGS} -static"
	use nls || myconf+=( --disable-nls )

	# Historically, we always used the builtin readline, but since
	# our handling of SONAME upgrades has gotten much more stable
	# in the PM (and the readline ebuild itself preserves the old
	# libs during upgrades), linking against the system copy should
	# be safe.
	# Exact cached version here doesn't really matter as long as it
	# is at least what's in the DEPEND up above.
	export ac_cv_rl_version=${READLINE_VER%%_*}

	# Force linking with system curses ... the bundled termcap lib
	# sucks bad compared to ncurses.  For the most part, ncurses
	# is here because readline needs it.  But bash itself calls
	# ncurses in one or two small places :(.

	if is_release ; then
		# Use system readline only with released versions.
		myconf+=( --with-installed-readline=. )
	fi

	if use plugins; then
		case "${CHOST}" in
			# Darwin doesn't need an rpath here (in fact doesn't grok the argument)
			*-linux-gnu* | *-solaris* | *-freebsd* )
				append-ldflags -Wl,-rpath,"${EPREFIX%/}"/usr/$(get_libdir)/bash
				;;
		esac
	else
		# Disable the plugins logic by hand since bash doesn't
		# provide a way of doing it.
		export ac_cv_func_dl{close,open,sym}=no \
			ac_cv_lib_dl_dlopen=no ac_cv_header_dlfcn_h=no
		sed -i \
			-e '/LOCAL_LDFLAGS=/s:-rdynamic::' \
			configure || die
	fi
	tc-export AR #444070
	econf "${myconf[@]}"
}

src_compile() {
	emake

	if use plugins ; then
		emake -C examples/loadables all others
	fi
}

src_install() {
	local d f

	default

	dodir /bin
	mv "${ED%/}"/usr/bin/bash "${ED%/}"/bin/ || die
	dosym bash /bin/rbash

	insinto /etc/bash
	doins "${FILESDIR}"/bash_logout
	if [[ -s "${T}"/bashrc ]]; then
		doins "${T}"/bashrc
	else
		eerror "Prefixified bashrc at '${T}/bashrc' cannot be read"
		ewarn "Installing default bashrc"
		doins "$(prefixify_ro "${FILESDIR}"/bashrc)"
	fi
	keepdir /etc/bash/bashrc.d
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
		"${ED%/}"/etc/skel/.bashrc \
		"${ED%/}"/etc/bash/bashrc || die

	if use plugins ; then
		exeinto /usr/$(get_libdir)/bash
		doexe $(echo examples/loadables/*.o | sed 's:\.o::g')
		insinto /usr/include/bash-plugins
		doins *.h builtins/*.h include/*.h lib/{glob/glob.h,tilde/tilde.h}
	fi

	if use examples ; then
		for d in examples/{functions,misc,scripts,startup-files} ; do
			exeinto /usr/share/doc/${PF}/${d}
			docinto ${d}
			for f in ${d}/* ; do
				if [[ ${f##*/} != PERMISSION ]] && [[ ${f##*/} != *README ]] ; then
					doexe ${f}
				else
					dodoc ${f}
				fi
			done
		done
	fi

	doman doc/*.1
	newdoc CWRU/changelog ChangeLog
	dosym bash.info /usr/share/info/bashref.info
}

pkg_preinst() {
	if [[ -e "${EROOT%/}"/etc/bashrc ]] && [[ ! -d "${EROOT%/}"/etc/bash ]] ; then
		mkdir -p "${EROOT%/}"/etc/bash
		mv -f "${EROOT%/}"/etc/bashrc "${EROOT%/}"/etc/bash/
	fi

	if [[ -L "${EROOT%/}"/bin/sh ]] ; then
		# rewrite the symlink to ensure that its mtime changes. having /bin/sh
		# missing even temporarily causes a fatal error with paludis.
		local target="$( readlink "${EROOT%/}"/bin/sh )"
		local tmp="$( emktemp "${EROOT%/}"/bin )"
		ln -sf "${target}" "${tmp}"
		mv -f "${tmp}" "${EROOT%/}"/bin/sh
	fi
}

pkg_postinst() {
	# If /bin/sh does not exist, provide it
	if [[ ! -e "${EROOT%/}"/bin/sh ]] ; then
		ln -sf bash "${EROOT%/}"/bin/sh
	fi
}

# vi: set diffopt=iwhite,filler:
