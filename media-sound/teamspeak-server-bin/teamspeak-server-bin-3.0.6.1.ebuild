# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/teamspeak-server-bin/teamspeak-server-bin-3.0.6.1.ebuild,v 1.1 2012/10/12 21:23:01 trapni Exp $

EAPI=4

inherit eutils systemd user

DESCRIPTION="TeamSpeak Server - Voice Communication Software"
HOMEPAGE="http://teamspeak.com/"
LICENSE="teamspeak3"
SLOT="0"
IUSE="doc pdf systemd tsdns"
KEYWORDS="~amd64 ~x86"
RESTRICT="installsources strip"

SRC_URI="
	amd64? ( http://ftp.4players.de/pub/hosted/ts3/releases/${PV}/teamspeak3-server_linux-amd64-${PV}.tar.gz )
	x86? ( http://ftp.4players.de/pub/hosted/ts3/releases/${PV}/teamspeak3-server_linux-x86-${PV}.tar.gz )
"

S="${WORKDIR}/teamspeak3-server_linux-${ARCH}"

DEPEND=""
RDEPEND="${DEPEND}"

pkg_setup() {
	enewuser teamspeak3
}

src_install() {
	into /opt/teamspeak3

	dodoc -r CHANGELOG doc/*.txt
	use doc && dodoc -r serverquerydocs
	use pdf && dodoc doc/*.pdf
	newsbin ts3server_linux_${ARCH} ts3server-bin
	dobin "${FILESDIR}/ts3server"
	dobin *.sh
	# 'dolib' may install to libx32 or lib64 - we just want standard lib
	#dolib.so *.so
	insinto /opt/teamspeak3/lib
	doins *.so
	# 'libmysqlclient.so.15' is hard-coded into the ts3-server binary :(
	dosym ../../../usr/$(get_libdir)/libmysqlclient.so /opt/teamspeak3/lib/libmysqlclient.so.15

	if use tsdns; then
		newdoc tsdns/README README.tsdns
		newdoc tsdns/USAGE USAGE.tsdns
		newsbin tsdns/tsdnsserver_linux_${ARCH} tsdnsserver
		insinto /opt/teamspeak3/sbin
		doins tsdns/tsdns_settings.ini.sample
	fi

	insinto /opt/teamspeak3/lib
	doins -r sql

	# Runtime FS layout ...
	insinto /etc/teamspeak3
	doins "${FILESDIR}/server.conf"
	doins "${FILESDIR}/ts3db_mysql.ini"
	newinitd "${FILESDIR}/teamspeak3-server.rc" teamspeak3

	keepdir /{etc,var/{lib,log,run}}/teamspeak3
	fowners teamspeak3 /{etc,var/{lib,log,run}}/teamspeak3
	fperms 700 /{etc,var/{lib,log,run}}/teamspeak3

	fowners teamspeak3 /opt/teamspeak3
	fperms 755 /opt/teamspeak3

	if use systemd; then
		systemd_dounit "${FILESDIR}/systemd/teamspeak3.service"
		systemd_dotmpfilesd "${FILESDIR}/systemd/teamspeak3.conf"
	fi
}
