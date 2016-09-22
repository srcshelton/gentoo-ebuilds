# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

MODULE_AUTHOR=TOBYINK
MODULE_VERSION=0.009
inherit perl-module

DESCRIPTION="match::smart - clone of smartmatch operator"

SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86"
IUSE=""

RDEPEND="
	virtual/perl-Scalar-List-Utils
	dev-perl/Exporter-Tiny
	dev-perl/Sub-Infix
"
DEPEND="${RDEPEND}"

SRC_TEST="do"
