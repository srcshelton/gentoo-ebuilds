# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

MODULE_AUTHOR=RJBS
MODULE_VERSION=1.20
inherit perl-module

DESCRIPTION="B::Lint - Perl lint"

SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE="test"

RDEPEND="dev-perl/Module-Pluggable"
DEPEND="${RDEPEND}"

SRC_TEST="do"
