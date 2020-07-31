# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DIST_AUTHOR="NWETTERS"
inherit perl-module

DESCRIPTION="Fast lookup of country codes by IP address"

SLOT="0"
KEYWORDS="amd64 x86"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="dev-perl/Geography-Countries"
DEPEND="${RDEPEND}"

SRC_TEST=do
