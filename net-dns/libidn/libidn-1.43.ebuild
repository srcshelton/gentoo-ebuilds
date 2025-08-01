# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/libidn.asc
inherit elisp-common libtool usr-ldscript verify-sig multilib-minimal

DESCRIPTION="Internationalized Domain Names (IDN) implementation"
HOMEPAGE="https://www.gnu.org/software/libidn/"
SRC_URI="
	mirror://gnu/libidn/${P}.tar.gz
	verify-sig? ( mirror://gnu/libidn/${P}.tar.gz.sig )
"

LICENSE="GPL-2 GPL-3 LGPL-3"
SLOT="0/12"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="emacs nls"

DEPEND="nls? ( >=virtual/libintl-0-r1[${MULTILIB_USEDEP}] )"
RDEPEND="${DEPEND}"
BDEPEND="
	emacs? ( >=app-editors/emacs-23.1:* )
	nls? ( >=sys-devel/gettext-0.17 )
	verify-sig? ( >=sec-keys/openpgp-keys-libidn-20250414 )
"

DOCS=( AUTHORS ChangeLog FAQ NEWS README THANKS )

QA_CONFIG_IMPL_DECL_SKIP=(
	unreachable
	static_assert
)

src_prepare() {
	default

	# For Solaris shared objects
	elibtoolize
}

multilib_src_configure() {
	# -fanalyzer substantially slows down the build and isn't useful for
	# us. It's useful for upstream as it's static analysis, but it's not
	# useful when just getting something built.
	export gl_cv_warn_c__fanalyzer=no

	local args=(
		$(use_enable nls)
		--disable-gcc-warnings
		--disable-doc
		--disable-gtk-doc
		--disable-gtk-doc-html
		--disable-gtk-doc-pdf
		--disable-csharp
		--disable-java
		--disable-valgrind-tests
		--with-lispdir="${EPREFIX}${SITELISP}/${PN}"
		--with-packager-bug-reports="https://bugs.gentoo.org"
		--with-packager-version="r${PR}"
		--with-packager="Gentoo Linux"
	)

	ECONF_SOURCE="${S}" econf "${args[@]}"
}

multilib_src_compile() {
	default

	if multilib_is_native_abi; then
		use emacs && elisp-compile "${S}"/src/*.el
	fi
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	if multilib_is_native_abi; then
		gen_usr_ldscript -a idn
	fi
}

multilib_src_install_all() {
	if use emacs; then
		# *.el are installed by the build system
		elisp-install ${PN} "${S}"/src/*.elc
		elisp-site-file-install "${FILESDIR}/50${PN}-gentoo.el"
	else
		rm -r "${ED}"/usr/share/emacs || die
	fi

	einstalldocs

	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	use emacs && elisp-site-regen
}

pkg_postrm() {
	use emacs && elisp-site-regen
}

# vi: set diffopt=iwhite,filler:
