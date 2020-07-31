# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit systemd

DESCRIPTION="spampd is a program to scan messages for Unsolicited Commercial E-mail content"
HOMEPAGE="http://www.worlddesign.com/index.cfm/rd/mta/spampd.htm"
SRC_URI="https://github.com/mpaperno/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="html systemd"

RDEPEND="dev-lang/perl
	dev-perl/NetAddr-IP
	dev-perl/Net-Server
	virtual/perl-Time-HiRes
	mail-filter/spamassassin"
DEPEND="${RDEPEND}"

src_install() {
	dosbin spampd.pl

	dodoc changelog.txt
	use html && dodoc spampd.html

	newinitd "${FILESDIR}"/init-r1 spampd
	newconfd "${FILESDIR}"/conf spampd

	use systemd && systemd_dounit misc/spampd.service
}
