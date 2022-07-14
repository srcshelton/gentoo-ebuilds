# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MODULE_AUTHOR=ARPI
MODULE_VERSION=0.50
inherit perl-module

DESCRIPTION="FastCGI Server"

SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris"

RDEPEND="
	dev-perl/File-Slurp
	dev-perl/Mojolicious
"
DEPEND="${RDEPEND}"

SRC_TEST="do"
