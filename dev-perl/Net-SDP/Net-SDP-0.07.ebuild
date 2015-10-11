# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Net-Subnet/Net-Subnet-1.02.ebuild,v 1.0 2013/05/15 12:38:42 srcs Exp $

EAPI=5

MY_PN=Net-SDP
MODULE_AUTHOR=NJH
MODULE_VERSION=${PV}

inherit perl-module eutils

DESCRIPTION="Session Description Protocol (rfc2327)"

SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
RESTRICT="nomirror"

DEPEND="dev-perl/Module-Build"

SRC_TEST="do"
