# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/IO-Socket-IP/IO-Socket-IP-0.280.0.ebuild,v 1.2 2014/08/25 12:23:35 armin76 Exp $

EAPI=5

MODULE_AUTHOR=BRAMBLE
MODULE_VERSION=1.12
inherit perl-module

DESCRIPTION='Send and receive multicast messages'

SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~ppc64 ~sparc ~x86"
IUSE="test"

RDEPEND="
	dev-perl/IO-Interface
"
DEPEND="${RDEPEND}
	virtual/perl-Module-Build
	test? (
		dev-perl/Test-Pod
	)
"

SRC_TEST="do"

src_prepare() {
	epatch "${FILESDIR}"/IO-Socket-Multicast-1.12-spelling.patch
	epatch "${FILESDIR}"/IO-Socket-Multicast-1.12-zero-byte-payload.patch
	epatch "${FILESDIR}"/IO-Socket-Multicast-1.12-multicast-pureperl.patch
}
