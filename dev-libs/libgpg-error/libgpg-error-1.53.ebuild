# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/gnupg.asc
inherit libtool toolchain-funcs usr-ldscript verify-sig multilib-minimal

DESCRIPTION="Contains error handling functions used by GnuPG software"
HOMEPAGE="https://www.gnupg.org/related_software/libgpg-error/"
SRC_URI="mirror://gnupg/${PN}/${P}.tar.bz2
	verify-sig? ( mirror://gnupg/${PN}/${P}.tar.bz2.sig )"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="common-lisp nls static-libs test"
RESTRICT="!test? ( test )"

RDEPEND="nls? ( >=virtual/libintl-0-r1[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}"
BDEPEND="
	nls? ( sys-devel/gettext )
	verify-sig? ( sec-keys/openpgp-keys-gnupg )
"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/gpg-error.h
	/usr/include/gpgrt.h
)

MULTILIB_CHOST_TOOLS=(
	/usr/bin/gpg-error-config
	/usr/bin/gpgrt-config
)

src_prepare() {
	default
	elibtoolize

	if use prefix ; then
		# don't hardcode /usr/xpg4/bin/sh as shell on Solaris
		sed \
			-e 's:INSTALLSHELLPATH=/usr/xpg4/bin/sh:INSTALLSHELLPATH=/bin/sh:g' \
			-i configure.ac configure || die
	fi

	# This check breaks multilib
	cat <<-EOF > src/gpg-error-config-test.sh.in || die
	#!@INSTALLSHELLPATH@
	exit 0
	EOF

	# only necessary for as long as we run eautoreconf, configure.ac
	# uses ./autogen.sh to generate PACKAGE_VERSION, but autogen.sh is
	# not a pure /bin/sh script, so it fails on some hosts
	#sed -i -e "1s:.*:#\!${BASH}:" autogen.sh || die
	#eautoreconf
}

multilib_src_configure() {
	local myeconfargs=(
		$(multilib_is_native_abi || echo --disable-languages)
		$(use_enable common-lisp languages)
		$(use_enable nls)
		# required for sys-power/suspend[crypt], bug 751568
		$(use_enable static-libs static)
		$(use_enable test tests)

		# See bug #699206 and its duplicates wrt gpgme-config
		# Upstream no longer install this by default and we should
		# seek to disable it at some point.
		--enable-install-gpg-error-config

		--enable-threads
		CC_FOR_BUILD="$(tc-getBUILD_CC)"
		$("${S}/configure" --help | grep -o -- '--without-.*-prefix')
	)
	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_install() {
	default

	if use split-usr && multilib_is_native_abi; then
		# need the libs in /
		gen_usr_ldscript -a gpg-error
	fi
}

multilib_src_install_all() {
	einstalldocs
	find "${ED}" -type f -name '*.la' -delete || die
}
