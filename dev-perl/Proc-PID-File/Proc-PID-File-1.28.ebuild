# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

MODULE_AUTHOR=DMITRI
MODULE_VERSION=1.28
inherit perl-module

DESCRIPTION="Proc::PID::File - a module to manage process id files"

SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE=""

RDEPEND="virtual/perl-ExtUtils-MakeMaker"
DEPEND="${RDEPEND}"

SRC_TEST="do"
