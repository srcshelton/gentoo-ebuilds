# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib toolchain-funcs

DESCRIPTION="GNU awk pattern-matching language"
HOMEPAGE="https://www.gnu.org/software/gawk/gawk.html"
SRC_URI="mirror://gnu/gawk/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="mpfr nls readline split-usr"

RDEPEND="
	dev-libs/gmp:0=
	mpfr? ( dev-libs/mpfr:0= )
	readline? ( sys-libs/readline:0= )
"
DEPEND="${RDEPEND}"
BDEPEND="
	nls? ( sys-devel/gettext )
"

src_prepare() {
	default

	# use symlinks rather than hardlinks, and disable version links
	sed -i \
		-e '/^LN =/s:=.*:= $(LN_S):' \
		-e '/install-exec-hook:/s|$|\nfoo:|' \
		Makefile.in doc/Makefile.in || die
	sed -i '/^pty1:$/s|$|\n_pty1:|' test/Makefile.in || die #413327
	# fix standards conflict on Solaris
	if [[ ${CHOST} == *-solaris* ]] ; then
		sed -i \
			-e '/\<_XOPEN_SOURCE\>/s/1$/600/' \
			-e '/\<_XOPEN_SOURCE_EXTENDED\>/s/1//' \
			extension/inplace.c || die
	fi
}

src_configure() {
	export ac_cv_libsigsegv=no
	local myeconfargs=(
		$(use_with mpfr)
		$(use_enable nls)
		$(use_with readline)
	)
	use split-usr && myeconfargs+=(
		--bindir=/bin
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	rm -r README_d # automatic dodocs barfs
	default

	# Install headers
	insinto /usr/include/awk
	doins *.h
	rm "${ED}"/usr/include/awk/config.h || die
}

pkg_postinst() {
	# symlink creation here as the links do not belong to gawk, but to any awk
	if ! use split-usr \
			&& has_version app-admin/eselect \
			&& has_version app-eselect/eselect-awk ; then
		eselect awk update ifunset
	else
		local l
		for l in "${EROOT}"/usr/share/man/man1/gawk.1* "${EROOT}"/usr/bin/gawk ; do
			if [[ -e ${l} ]]; then
				[[ ! -r ${l/gawk/awk} ]] && rm "${l/gawk/awk}"
				[[ ! -e ${l/gawk/awk} ]] && ln -s "${l##*/}" "${l/gawk/awk}"
			fi
		done
		[[ ! -r ${EROOT}/bin/awk ]] && rm "${EROOT}/bin/awk"
		if use split-usr; then
			[[ ! -e ${EROOT}/bin/awk ]] && ln -s "gawk" "${EROOT}/bin/awk"
		else
			[[ ! -e ${EROOT}/bin/awk ]] && ln -s "../usr/bin/gawk" "${EROOT}/bin/awk"
		fi
	fi
}

pkg_postrm() {
	if ! use split-usr &&
			has_version app-admin/eselect && 
			has_version app-eselect/eselect-awk ; then
		eselect awk update ifunset
	fi
}
