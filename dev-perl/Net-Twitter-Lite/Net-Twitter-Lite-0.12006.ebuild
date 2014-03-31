# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Net-Twitter/Net-Twitter-3.180.20.ebuild,v 1.1 2012/04/25 16:11:29 tove Exp $

EAPI=4

MODULE_AUTHOR=MMIMS
MODULE_VERSION="${PV}"
inherit perl-module

DESCRIPTION="A perl interface to the Twitter API"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
RESTRICT="nomirror"
IUSE=""

RDEPEND="
	  dev-perl/Crypt-SSLeay
	  dev-perl/JSON
	  dev-perl/Test-Fatal
	>=dev-perl/URI-1.40
	  virtual/perl-Module-Build
	"
DEPEND="${RDEPEND}"

# online test
SRC_TEST=skip
