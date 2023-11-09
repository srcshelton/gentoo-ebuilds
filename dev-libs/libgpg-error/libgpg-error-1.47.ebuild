# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/gnupg.asc
inherit autotools prefix toolchain-funcs usr-ldscript verify-sig multilib-minimal

DESCRIPTION="Contains error handling functions used by GnuPG software"
HOMEPAGE="https://www.gnupg.org/related_software/libgpg-error"
SRC_URI="mirror://gnupg/${PN}/${P}.tar.bz2
	verify-sig? ( mirror://gnupg/${PN}/${P}.tar.bz2.sig )"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
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

PATCHES=(
	"${FILESDIR}/${PN}-1.44-remove_broken_check.patch"
)

src_prepare() {
	default

	if use prefix ; then
		# don't hardcode /usr/xpg4/bin/sh as shell on Solaris
		sed -i -e 's/solaris\*/disabled/' configure.ac || die
	fi

	# only necessary for as long as we run eautoreconf, configure.ac
	# uses ./autogen.sh to generate PACKAGE_VERSION, but autogen.sh is
	# not a pure /bin/sh script, so it fails on some hosts
	hprefixify -w 1 autogen.sh
	eautoreconf
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
