# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: 9d944bb3fedb78bc21529dc690641ae6b4e4041a $

EAPI=5

MODULE_AUTHOR=TLOWERY
MODULE_VERSION=11.95
inherit perl-module

DESCRIPTION="Interactive command shell for the DBI"

SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

RDEPEND="dev-perl/IO-Tee
	dev-perl/Text-Reform
	dev-perl/DBI
	dev-perl/Text-CSV_XS"
DEPEND="${RDEPEND}"

SRC_TEST="do"

src_prepare() {
	default

	epatch "${FILESDIR}"/DBI-Shell-11.950.0-local.patch
}
