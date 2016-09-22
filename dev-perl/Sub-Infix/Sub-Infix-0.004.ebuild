# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Proc-Daemon/Proc-Daemon-0.140.0.ebuild,v 1.5 2012/03/02 21:38:44 ranger Exp $

EAPI=5

MODULE_AUTHOR=TOBYINK
MODULE_VERSION=0.004
inherit perl-module

DESCRIPTION="Sub::Infix - create a fake infix operator"

SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE="test"

RDEPEND="
	virtual/perl-ExtUtils-MakeMaker
	test? ( dev-perl/Test-Fatal )
"
DEPEND="${RDEPEND}"

SRC_TEST="do"
