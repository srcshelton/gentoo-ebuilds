# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DIST_AUTHOR=SRI
inherit perl-module

DESCRIPTION="Duct tape for the HTML5 web"

SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris"
IUSE="fastcgi"

PDEPEND="
	fastcgi? ( dev-perl/Mojo-Server-FastCGI )
"
DEPEND="
	virtual/perl-ExtUtils-MakeMaker
	virtual/perl-IO-Socket-IP
	virtual/perl-JSON-PP
	virtual/perl-Pod-Simple
	virtual/perl-Scalar-List-Utils
	virtual/perl-Time-Local
"

RESTRICT="nomirror"

SRC_TEST="do"
