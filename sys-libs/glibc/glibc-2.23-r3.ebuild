# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: fad971ad773fbfa403f6aa15a53cca4c137ac079 $

EAPI="4"

inherit eutils versionator toolchain-funcs flag-o-matic gnuconfig multilib systemd unpacker multiprocessing prefix

DESCRIPTION="GNU libc6 (also called glibc2) C library"
HOMEPAGE="https://www.gnu.org/software/libc/libc.html"

LICENSE="LGPL-2.1+ BSD HPND ISC inner-net rc PCRE"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh ~sparc ~x86"
RESTRICT="strip" # strip ourself #46186
EMULTILIB_PKG="true"

# Configuration variables
RELEASE_VER=""
case ${PV} in
9999*)
	EGIT_REPO_URIS="git://sourceware.org/git/glibc.git"
	EGIT_SOURCEDIRS="${S}"
	inherit git-2
	;;
*)
	RELEASE_VER=${PV}
	;;
esac
GCC_BOOTSTRAP_VER="4.7.3-r1"
PATCH_VER="7"                                  # Gentoo patchset
: ${NPTL_KERN_VER:="2.6.32"}                   # min kernel version nptl requires

IUSE="audit caps debug gd hardened multilib nscd +rpc selinux systemtap profile suid vanilla crosscompile_opts_headers-only"

# Here's how the cross-compile logic breaks down ...
#  CTARGET - machine that will target the binaries
#  CHOST   - machine that will host the binaries
#  CBUILD  - machine that will build the binaries
# If CTARGET != CHOST, it means you want a libc for cross-compiling.
# If CHOST != CBUILD, it means you want to cross-compile the libc.
#  CBUILD = CHOST = CTARGET    - native build/install
#  CBUILD != (CHOST = CTARGET) - cross-compile a native build
#  (CBUILD = CHOST) != CTARGET - libc for cross-compiler
#  CBUILD != CHOST != CTARGET  - cross-compile a libc for a cross-compiler
# For install paths:
#  CHOST = CTARGET  - install into /
#  CHOST != CTARGET - install into /usr/CTARGET/

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}

# Why SLOT 2.2 you ask yourself while sippin your tea ?
# Everyone knows 2.2 > 0, duh.
SLOT="2.2"

# General: We need a new-enough binutils/gcc to match upstream baseline.
# arch: we need to make sure our binutils/gcc supports TLS.
COMMON_DEPEND="
	nscd? ( selinux? (
		audit? ( sys-process/audit )
		caps? ( sys-libs/libcap )
	) )
	suid? ( caps? ( sys-libs/libcap ) )
	selinux? ( sys-libs/libselinux )
"
DEPEND="${COMMON_DEPEND}
	>=app-misc/pax-utils-0.1.10
	!<sys-apps/sandbox-1.6
	!<sys-apps/portage-2.1.2"
RDEPEND="${COMMON_DEPEND}
	!sys-kernel/ps3-sources
	sys-apps/gentoo-functions
	!sys-libs/nss-db"

if [[ ${CATEGORY} == cross-* ]] ; then
	DEPEND+=" !crosscompile_opts_headers-only? (
		>=${CATEGORY}/binutils-2.24
		>=${CATEGORY}/gcc-4.7
	)"
	[[ ${CATEGORY} == *-linux* ]] && DEPEND+=" ${CATEGORY}/linux-headers"
else
	DEPEND+="
		>=sys-devel/binutils-2.24
		>=sys-devel/gcc-4.7
		virtual/os-headers"
	RDEPEND+=" vanilla? ( !sys-libs/timezone-data )"
	PDEPEND+=" !vanilla? ( sys-libs/timezone-data )"
fi

upstream_uris() {
	echo mirror://gnu/glibc/$1 ftp://sourceware.org/pub/glibc/{releases,snapshots}/$1 mirror://gentoo/$1
}
gentoo_uris() {
	local devspace="HTTP~vapier/dist/URI HTTP~azarah/glibc/URI"
	devspace=${devspace//HTTP/https://dev.gentoo.org/}
	echo mirror://gentoo/$1 ${devspace//URI/$1}
}
SRC_URI=$(
	[[ -z ${EGIT_REPO_URIS} ]] && upstream_uris ${P}.tar.xz
	[[ -n ${PATCH_VER}      ]] && gentoo_uris ${P}-patches-${PATCH_VER}.tar.bz2
)
SRC_URI+=" ${GCC_BOOTSTRAP_VER:+multilib? ( $(gentoo_uris gcc-${GCC_BOOTSTRAP_VER}-multilib-bootstrap.tar.bz2) )}"

# eblit-include [--skip] <function> [version]
eblit-include() {
	local skipable=false
	[[ $1 == "--skip" ]] && skipable=true && shift
	[[ $1 == pkg_* ]] && skipable=true

	local e v func=$1 ver=$2
	[[ -z ${func} ]] && die "Usage: eblit-include <function> [version]"
	for v in ${ver:+-}${ver} -${PVR} -${PV} "" ; do
		e="${FILESDIR}/eblits/${func}${v}.eblit"
		if [[ -e ${e} ]] ; then
			source "${e}"
			return 0
		fi
	done
	${skipable} && return 0
	die "Could not locate requested eblit '${func}' in ${FILESDIR}/eblits/"
}

# eblit-run-maybe <function>
# run the specified function if it is defined
eblit-run-maybe() {
	[[ $(type -t "$@") == "function" ]] && "$@"
}

# eblit-run <function> [version]
# aka: src_unpack() { eblit-run src_unpack ; }
eblit-run() {
	eblit-include --skip common "${*:2}"
	eblit-include "$@"
	eblit-run-maybe eblit-$1-pre
	eblit-${PN}-$1
	eblit-run-maybe eblit-$1-post
}

src_unpack()    { eblit-run src_unpack    ; }
src_prepare()   { eblit-run src_prepare   ; }
src_configure() { eblit-run src_configure ; }
src_compile()   { eblit-run src_compile   ; }
src_test()      { eblit-run src_test      ; }
src_install()   { eblit-run src_install   ; }

# FILESDIR might not be available during binpkg install
for x in pretend setup {pre,post}inst ; do
	e="${FILESDIR}/eblits/pkg_${x}.eblit"
	if [[ -e ${e} ]] ; then
		. "${e}"
		eval "pkg_${x}() { eblit-run pkg_${x} ; }"
	fi
done

eblit-src_unpack-pre() {
	case $(gcc-fullversion) in
	4.8.[0-3]|4.9.0)
		eerror "You need to switch to a newer compiler; gcc-4.8.[0-3] and gcc-4.9.0 miscompile"
		eerror "glibc.  See https://bugs.gentoo.org/547420 for details."
		die "need to switch compilers #547420"
		;;
	esac

	[[ -n ${GCC_BOOTSTRAP_VER} ]] && use multilib && unpack gcc-${GCC_BOOTSTRAP_VER}-multilib-bootstrap.tar.bz2
}

eblit-src_prepare-post() {
	cd "${S}"

	epatch "${FILESDIR}"/2.19/${PN}-2.19-ia64-gcc-4.8-reloc-hack.patch #503838

	if use hardened ; then
		# We don't enable these for non-hardened as the output is very terse --
		# it only states that a crash happened.  The default upstream behavior
		# includes backtraces and symbols.
		einfo "Installing Hardened Gentoo SSP and FORTIFY_SOURCE handler"
		cp "${FILESDIR}"/2.20/glibc-2.20-gentoo-stack_chk_fail.c debug/stack_chk_fail.c || die
		cp "${FILESDIR}"/2.20/glibc-2.20-gentoo-chk_fail.c debug/chk_fail.c || die

		if use debug ; then
			# Allow SIGABRT to dump core on non-hardened systems, or when debug is requested.
			sed -i \
				-e '/^CFLAGS-backtrace.c/ iCPPFLAGS-stack_chk_fail.c = -DSSP_SMASH_DUMPS_CORE' \
				-e '/^CFLAGS-backtrace.c/ iCPPFLAGS-chk_fail.c = -DSSP_SMASH_DUMPS_CORE' \
				debug/Makefile || die
		fi

		# Build various bits with ssp-all
		sed -i \
			-e 's:-fstack-protector$:-fstack-protector-all:' \
			*/Makefile || die
	fi

	if [[ "${ARCH}" == "amd64" ]]; then
		local LD32="$( get_abi_LIBDIR x86 )"
		local LDx32="$( get_abi_LIBDIR x32 )"
		local LD64="$( get_abi_LIBDIR amd64 )"
		local -i LD32l LDx32l LD64l
		(( LD32l = ${#LD32} + 1 ))
		(( LDx32l = ${#LDx32} + 1 ))
		(( LD64l = ${#LD64} + 1 ))

		# In order for this to work, LD64 and LDx32 must share a common root of
		# LD32.  If this is not the case, then sysdeps/unix/sysv/linux/x86_64/dl-cache.h
		# will need to be re-implemented.

		local LDx32s="${LDx32#${LD32}}"
		local LD64s="${LD64#${LD32}}"

		einfo "Using the following libdir paths:"
		einfo "  32-bit libraries in '${LD32}'"
		einfo "  Long-mode 32-bit libraries in '${LDx32}'"
		einfo "  64-bit libraries in '${LD64}'"

		cd "${S}"

		sed -i \
			-e "s:/libx32:/${LDx32:-libx32}:g" \
				sysdeps/unix/sysv/linux/x86_64/x32/configure \
			|| die 'configure patch failed'

		sed -i \
			-e "/FLAG_ELF_LIBC6/{s:/lib/:/${LD32:-lib}/:}" \
			-e "/FLAG_ELF_LIBC6/{s:/libx32/:/${LDx32:-libx32}/:}" \
			-e "/FLAG_ELF_LIBC6/{s:/lib64/:/${LD64:-lib64}/:}" \
				sysdeps/unix/sysv/linux/x86_64/ldconfig.h \
			|| die 'known_interpreter_names replacement failed'

		#      if (len >= 6 && ! memcmp (path + len - 6, "/lib64", 6))   \
		#        {                                                       \
		#          len -= 2;                                             \
		#
		#      else if (len >= 7                                         \
		#               && ! memcmp (path + len - 7, "/libx32", 7))      \
		#        {                                                       \
		#          len -= 3;                                             \
		#
		#      if (len >= 4 && ! memcmp (path + len - 4, "/lib", 4))     \
		#        {                                                       \
		#          memcpy (path + len, "64", 3);                         \
		#          add_dir (path);                                       \
		#          memcpy (path + len, "x32", 4);                                \
		sed -i \
			-e "/ memcmp /{s:len >= 6 :len >= ${LD64l} : ; s: 6, \"/lib64\", 6): ${LD64l}, \"/${LD64:-lib64}\", ${LD64l}):}" \
			-e "/len -= 2;/{s:len -= 2;:len -= ${#LD64s};:}" \
			-e "/else if (len >= 7/{s:len >= 7:len >= ${LDx32l}:}" \
			-e "/ memcmp /{s: 7, \"/libx32\", 7): ${LDx32l}, \"/${LDx32:-libx32}\", ${LDx32l}):}" \
			-e "/len -= 3;/{s:len -= 3;:len -= ${#LDx32s};:}" \
			-e "/ memcmp /{s:len >= 4 :len >= ${LD32l} : ; s: 4, \"/lib\", 4): ${LD32l}, \"/${LD32:-lib}\", ${LD32l}):}" \
			-e "/memcpy /{s:len, \"64\", 3):len, \"${LD64s}\", $(( ${#LD64s} + 1 ))):}" \
			-e "/memcpy /{s:len, \"x32\", 4):len, \"${LDx32s}\", $(( ${#LDx32s} + 1 ))):}" \
				sysdeps/unix/sysv/linux/x86_64/dl-cache.h \
			|| die 'dl-cache.h modification failed'

		einfo "dl-cache.h now contains:"
		cat sysdeps/unix/sysv/linux/x86_64/dl-cache.h
	fi
}
