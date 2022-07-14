# Copyright 2019-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DIST_AUTHOR=ETHER
inherit perl-module

DESCRIPTION="Look up the vendor for a MAC"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
RESTRICT="nomirror"
#IUSE=""

RDEPEND="
	dev-perl/IO-Socket-SSL
	dev-perl/Mojolicious
	dev-perl/Net-SSLeay
"
DEPEND="${RDEPEND}"

src_prepare() {
	perl_rm_files Changes README.pod

	default
}
