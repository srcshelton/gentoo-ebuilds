# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DIST_AUTHOR="NWELLNHOF"
inherit perl-module

DESCRIPTION="IPv4 and IPv6 to country translation using DB_File"

SLOT="0"
KEYWORDS="amd64 arm64 arm x86"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="virtual/perl-DB_File
	dev-perl/IP-Country"
DEPEND="${RDEPEND}"

SRC_TEST=do
