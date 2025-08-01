# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#GAWK_IS_BETA=yes

DESCRIPTION="GNU awk pattern-matching language"
HOMEPAGE="https://www.gnu.org/software/gawk/gawk.html"

if [[ ${GAWK_IS_BETA} == yes || ${PV} == *_beta* ]] ; then
	if [[ ${PV} == *_beta* ]] ; then
		# Beta versioning is sometimes for the release prior, e.g.
		# 5.2.1_beta is labelled upstream as 5.2.0b.
		MY_PV=${PV/_beta/b}
		MY_PV=$(ver_cut 1-2 ${MY_PV}).$(($(ver_cut 3 ${MY_PV}) - 1))$(ver_cut 4- ${MY_PV})
		MY_P=${PN}-${MY_PV}

		S="${WORKDIR}"/${MY_P}
	else
		MY_P=${P}
	fi

	SRC_URI="https://www.skeeve.com/gawk/${MY_P}.tar.gz"
else
	VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/gawk.asc
	inherit flag-o-matic verify-sig

	SRC_URI="mirror://gnu/gawk/${P}.tar.xz
		verify-sig? ( mirror://gnu/gawk/${P}.tar.xz.sig )"

	KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"
fi

LICENSE="GPL-3+"
SLOT="0"
# While tempting to enable mpfr by default as e.g. Fedora do, as of 5.2.x,
# MPFR support is "on parole" and may be removed:
# https://www.gnu.org/software/gawk/manual/html_node/MPFR-On-Parole.html.
IUSE="-compat mpfr nls pma readline split-usr"
REQUIRED_USE="compat? ( split-usr )"

RDEPEND="
	mpfr? (
		dev-libs/gmp:=
		dev-libs/mpfr:=
	)
	readline? ( sys-libs/readline:= )
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=sys-apps/texinfo-7.1
	>=sys-devel/bison-3.5.4
	nls? ( sys-devel/gettext )
"

if [[ ${GAWK_IS_BETA} != yes ]] ; then
	BDEPEND+=" verify-sig? ( sec-keys/openpgp-keys-gawk )"
fi

src_prepare() {
	default

	use elibc_musl && append-cppflags -D__GNU_LIBRARY__

	# Use symlinks rather than hardlinks, and disable version links
	sed -i \
		-e '/^LN =/s:=.*:= $(LN_S):' \
		-e '/install-exec-hook:/s|$|\nfoo:|' \
		Makefile.in doc/Makefile.in || die

	# bug #413327
	sed -i '/^pty1:$/s|$|\n_pty1:|' test/Makefile.in || die

	# Fix standards conflict on Solaris
	if [[ ${CHOST} == *-solaris* ]] ; then
		sed -i \
			-e '/\<_XOPEN_SOURCE\>/s/1$/600/' \
			-e '/\<_XOPEN_SOURCE_EXTENDED\>/s/1//' \
			extension/inplace.c || die
	fi
}

src_configure() {
	# README says gawk may not work properly if built with non-Bison.
	# We already BDEPEND on Bison, so just unset YACC rather than
	# guessing if we need to do yacc.bison or bison -y.
	unset YACC

	if use amd64 || use x86 || use amd64-linux || use x86-linux; then
		# With -z,max-page-size=0x200000 set (for x86_64), tiny binaries bloat
		# to 6.1MB each :o
		#
		filter-ldflags *-z,max-page-size=*
	fi

	local myeconfargs=(
		--cache-file="${S}"/config.cache
		$(use_with mpfr)
		$(use_enable nls)
		$(use_enable pma)
		$(use_with readline)
	)
	use split-usr && myeconfargs+=(
		--bindir=/bin
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	# Automatic dodocs barfs
	rm -r README_d || die

	default

	# Install headers
	insinto /usr/include/awk
	doins *.h
	rm "${ED}"/usr/include/awk/config.h || die

	if use compat; then
		dodir /usr/bin
		ln -s ../../bin/gawk "${ED}"/usr/bin/gawk || die
	fi
}

pkg_postinst() {
	local l
	for l in \
			"${EROOT}"/usr/share/man/man1/gawk.1* \
			"${EROOT}"$( usex split-usr '' '/usr' )/bin/gawk
	do
		if [[ -e "${l}" ]] && ! [[ -e "${l/gawk/awk}" ]] ; then
			ln -s "${l##*/}" "${l/gawk/awk}" ||
				ewarn "Not creating '${l/gawk/awk}' symlink: file" \
					"already exists"
		fi
	done

	if ! [[ -e "${EROOT}"/bin/awk ]] ; then
		# /bin might not exist yet (stage1)
		[[ -d "${EROOT}"/bin ]] || mkdir "${EROOT}"/bin || die

		if use split-usr; then
			ln -s gawk "${EROOT}"/bin/awk || ewarn "Not creating" \
				"'${EROOT%/}/bin/awk' symlink: file already exists"
		else
			ln -s ../usr/bin/gawk "${EROOT}"/bin/awk || ewarn "Not" \
				"creating '${EROOT%/}/bin/awk' symlink: file already" \
				"exists"
		fi
	fi
}
