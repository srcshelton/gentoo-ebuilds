# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Net-Twitter/Net-Twitter-3.180.20.ebuild,v 1.1 2012/04/25 16:11:29 tove Exp $

EAPI=4

MODULE_AUTHOR=RCAPUTO
MODULE_VERSION=1.171
inherit perl-module

DESCRIPTION="A non-blocking ICMP ping client"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
RESTRICT="nomirror"
IUSE=""

RDEPEND="dev-perl/POE"
DEPEND="${RDEPEND}"
