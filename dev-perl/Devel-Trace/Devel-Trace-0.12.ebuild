# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

MODULE_AUTHOR=MJD
MODULE_VERSION=0.12
inherit perl-module

DESCRIPTION="Devel::Trace - Print out each line before it is executed (like sh -x)"

SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE="test"

RDEPEND="
	virtual/perl-ExtUtils-MakeMaker
"
DEPEND="${RDEPEND}"

SRC_TEST="do"
