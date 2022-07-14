# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DIST_AUTHOR=ILYAZ
DIST_SECTION=modules
DIST_VERSION=2.01080900
DIST_A_EXT=zip
inherit perl-module toolchain-funcs

PARI_VER=2.3.5

DESCRIPTION="Perl interface to PARI"
SRC_URI="${SRC_URI}
	http://pari.math.u-bordeaux.fr/pub/pari/unix/pari-${PARI_VER}.tar.gz"
S_PARI="${WORKDIR}"/pari-${PARI_VER}

SLOT="0"
KEYWORDS="~alpha amd64 ~hppa sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-solaris"
IUSE="abi_x86_x32 elibc_glibc"

# Math::Pari requires that a copy of the pari source in a parallel
# directory to where you build it. It does not need to compile it, but
# it does need to be the same version as is installed, hence the hard
# DEPEND below
BDEPEND="app-arch/unzip"

PATCHES=(
	"${FILESDIR}/no-flto.patch"
	"${FILESDIR}/${P}-no-dot-inc.patch"
)

src_prepare() {
	# On 64-bit hardware, these files are needed in both the 64/ and 32/
	# directories for the testsuite to pass.
	cd "${S_PARI}"/src/test/ || die

	local t
	for t in analyz compat ellglobalred elliptic galois graph intnum kernel \
		linear nfields number objets ploth polyser program qfbsolve rfrac \
		round4 stark sumiter trans ; do
		i="in/${t}"
		o32="32/${t}"
		o64="64/${t}"

		if [[ -f "${i}" && ! -f "${o32}" ]] ; then
			cp -al "${i}" "${o32}" || die
		fi

		if [[ -f "$i" && ! -f "$o64" ]] ; then
			cp -al "${i}" "${o64}" || die
		fi
	done

	cd "${S_PARI}" || die
	eapply "${FILESDIR}/pari-${PARI_VER}-no-dot-inc.patch"
	cd "${S}" || die

	perl-module_src_prepare
}

src_configure() {
	# Unfortunately the assembly routines math-pari has for SPARC do not
	# appear to be working at current.  Perl cannot test math-pari or
	# anything that pulls in the math-pari module as DynaLoader cannot load
	# the resulting .so files math-pari generates.  As such, we have to use
	# the generic non-machine specific assembly methods here.
	use sparc && myconf="${myconf} machine=none"

	# This is a horrible, horrible hack - but on systems where the
	# word-length of the kernel differs from that of userland, math-pari
	# goes with the kernel size and then breaks :(
	# This affects x32 systems and systems with a 64-bit kernel running a
	# 32-bit userland.  It likely affects other architectures (primarily
	# MIPS?) also, but this fix deals only with the Intel case.
	# We're limited in what we can do here, because
	# 'perl-module_src_configure' is a shell-function inherited from the
	# 'perl-module' eclass, and we don't want to freeze-and-import a whole
	# chunk of this script just to ensure that the configure stage detects
	# the correct architecture.  Instead, we cunningly define and export a
	# shell-function named 'perl' which is called in place of the perl
	# binary and which itself invokes the perl binary, but in the correct
	# context.  We then remove this ASAP since, let's face it, this is
	# bound to be hugely fragile...
	if use elibc_glibc; then
		if use abi_x86_x32 || [[ "$( uname -m )" == "x86_64" && "$( getconf LONG_BIT )" != "64" ]]; then
			export real_perl_path="$( type -pf perl 2>/dev/null )"
			if [[ -x "${real_perl_path}" ]]; then
				function perl() {
					linux32 "${real_perl_path}" "${@}"
				}
				export -f perl
			fi
		fi
	fi

	perl-module_src_configure

	unset perl real_perl_path
}

src_compile() {
	emake AR="$(tc-getAR)" OTHERLDFLAGS="${LDFLAGS}"
}
