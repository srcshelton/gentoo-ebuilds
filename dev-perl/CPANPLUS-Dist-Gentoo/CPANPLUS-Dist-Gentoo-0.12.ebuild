# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

EAPI=5

MODULE_AUTHOR=VPIT
MODULE_VERSION=0.12
inherit perl-module

DESCRIPTION="CPANPLUS backend [for] generating Gentoo ebuilds"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
RESTRICT="nomirror"
IUSE=""

RDEPEND="dev-perl/CPANPLUS"
DEPEND="${RDEPEND}"
