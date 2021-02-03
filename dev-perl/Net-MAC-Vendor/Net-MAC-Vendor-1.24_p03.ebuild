# Copyright 2015-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

#MODULE_AUTHOR=BDFOY
MODULE_VERSION=1.24_03
inherit perl-module git-r3

DESCRIPTION="Look up the vendor for a MAC"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
EGIT_REPO_URI="https://github.com/briandfoy/net-mac-vendor.git"
EGIT_COMMIT="ed606094bf891ac0213454f3a91ab1f39efbb841"
RESTRICT="nomirror"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	virtual/perl-ExtUtils-MakeMaker
"

S="${WORKDIR}"/"${P}"

src_prepare() {
	perl_rm_files .releaserc lib/.releaserc
	perl_rm_files Changes README.pod
}
