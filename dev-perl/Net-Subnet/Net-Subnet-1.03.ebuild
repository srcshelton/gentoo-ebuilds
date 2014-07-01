# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Net-Subnet/Net-Subnet-1.02.ebuild,v 1.0 2013/05/15 12:38:42 srcs Exp $

EAPI=5

MY_PN=Net-Subnet
MODULE_AUTHOR=JUERD
MODULE_VERSION=1.03

inherit perl-module eutils

DESCRIPTION="Fast IP-in-subnet matcher for IPv4 and IPv6, CIDR or mask"

SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
RESTRICT="nomirror"

RDEPEND=">=dev-perl/Socket6-0.230.0"
DEPEND="${RDEPEND}"

SRC_TEST="do"
