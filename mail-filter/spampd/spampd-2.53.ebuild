# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="A program to scan messages for Unsolicited Commercial E-mail content"
HOMEPAGE="http://www.worlddesign.com/index.cfm/rd/mta/spampd.htm
	https://github.com/mpaperno/spampd"
SRC_URI="https://github.com/mpaperno/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="html systemd"

RDEPEND="acct-group/mail
	acct-user/mail
	dev-lang/perl
	dev-perl/NetAddr-IP
	dev-perl/Net-Server
	mail-filter/spamassassin
	virtual/perl-Time-HiRes"
DEPEND="${RDEPEND}"
BDEPEND="dev-lang/perl"

src_install() {
	dosbin spampd.pl

	dodoc changelog.txt
	use html && dodoc spampd.html

	newinitd "${FILESDIR}"/init-r1 spampd
	newconfd "${FILESDIR}"/conf spampd

	use systemd && systemd_dounit misc/spampd.service
}
