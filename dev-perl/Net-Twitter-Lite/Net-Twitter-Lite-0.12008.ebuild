# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DIST_AUTHOR=MMIMS
DIST_VERSION="${PV}"
inherit perl-module

DESCRIPTION="A perl interface to the Twitter API"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
RESTRICT="mirror"

RDEPEND="
	dev-perl/Crypt-SSLeay
	dev-perl/JSON
	dev-perl/Test-Fatal
	>=dev-perl/URI-1.40
"
BDEPEND="${RDEPEND}
	dev-perl/Module-Build
	dev-perl/Module-Build-Tiny
"

# online test
SRC_TEST=skip
