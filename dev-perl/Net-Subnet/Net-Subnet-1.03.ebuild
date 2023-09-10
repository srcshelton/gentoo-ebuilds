# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MY_PN=Net-Subnet
DIST_AUTHOR=JUERD

inherit perl-module

DESCRIPTION="Fast IP-in-subnet matcher for IPv4 and IPv6, CIDR or mask"

SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
RESTRICT="nomirror"

RDEPEND=">=dev-perl/Socket6-0.230.0"
DEPEND="${RDEPEND}"

SRC_TEST="do"
