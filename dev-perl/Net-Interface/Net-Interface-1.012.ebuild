# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Net-Interface/Net-Interface-1.012.ebuild,v 1.0 2014/11/12 13:09:10 srcs Exp $

EAPI=5

MY_PN=Net-Interface
MODULE_AUTHOR=MIKER
MODULE_VERSION=1.012

inherit perl-module

DESCRIPTION="Perl extension to access network interfaces"

SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
RESTRICT="nomirror"

SRC_TEST="do"
