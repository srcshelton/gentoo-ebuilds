# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: d2b2ecad4606d64a60e9796dd94a0d5aa0d131b3 $

# Note: if your package uses the texi2dvi utility, it must depend on the
# virtual/texi2dvi package to pull in all the right deps.  The tool is not
# usable out-of-the-box because it requires the large tex packages.

EAPI="5"

inherit flag-o-matic

DESCRIPTION="The GNU info program and utilities"
HOMEPAGE="https://www.gnu.org/software/texinfo/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm ~arm64 hppa ~ia64 ~m68k ~mips ~ppc ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE="nls static"

RDEPEND="
	!=app-text/tetex-2*
	>=sys-libs/ncurses-5.2-r2:0=
	dev-lang/perl:=
	dev-perl/libintl-perl
	dev-perl/Unicode-EastAsianWidth
	dev-perl/Text-Unidecode
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	nls? ( >=sys-devel/gettext-0.19.6 )"

src_prepare() {
	epatch "${FILESDIR}"/"${PN}"-4.13-mint.patch
	epatch "${FILESDIR}"/"${PN}"-5.2-terminal.patch
	# timestamps must be newer than configure.ac touched by prefix patch
	sed -i -e '1c\#!/usr/bin/env sh' util/texi2dvi util/texi2pdf || die
	touch doc/{texi2dvi,texi2pdf,pdftexi2dvi}.1
}

src_configure() {
	use static && append-ldflags -static
	econf \
		--with-external-libintl-perl \
		--with-external-Unicode-EastAsianWidth \
		--with-external-Text-Unidecode \
		$(use_enable nls)
}
