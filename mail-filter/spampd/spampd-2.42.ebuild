# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit systemd

DESCRIPTION="spampd is a program to scan messages for Unsolicited Commercial E-mail content"
HOMEPAGE="http://www.worlddesign.com/index.cfm/rd/mta/spampd.htm"
SRC_URI="https://github.com/mpaperno/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc x86"
IUSE="html systemd"

DEPEND="
	dev-perl/Net-Server
	mail-filter/spamassassin"
RDEPEND="${DEPEND}
	dev-lang/perl"

src_install() {
	dosbin spampd.pl
	dodoc changelog.txt
	use html && dohtml spampd.html
	newinitd "${FILESDIR}"/init-r1 spampd
	newconfd "${FILESDIR}"/conf spampd
	use systemd && systemd_dounit misc/spampd.service
}
