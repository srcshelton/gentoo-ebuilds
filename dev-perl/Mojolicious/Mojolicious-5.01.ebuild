# Distributed under the terms of the GNU General Public License v2

EAPI=5

MODULE_AUTHOR=SRI
MODULE_VERSION=5.01
inherit perl-module

DESCRIPTION="Real-time web framework"

SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris"
IUSE="fastcgi"

RDEPEND="
	virtual/perl-ExtUtils-MakeMaker
	dev-perl/IO-Socket-SSL
	fastcgi? ( dev-perl/Mojo-Server-FastCGI )
"
DEPEND="${RDEPEND}"

SRC_TEST=do
