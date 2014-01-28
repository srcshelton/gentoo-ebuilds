# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/teamspeak-server-bin/teamspeak-server-bin-3.0.10.3.ebuild,v 1.1 2014/01/27 16:05:54 tomwij Exp $

EAPI="5"

inherit eutils systemd user

DESCRIPTION="TeamSpeak Server - Voice Communication Software"
HOMEPAGE="http://www.teamspeak.com/"
LICENSE="teamspeak3 GPL-2"

SLOT="0"
IUSE="doc pdf systemd tsdns"
KEYWORDS="~amd64 ~x86"
RESTRICT="installsources mirror strip"

SRC_URI="amd64? ( http://files.teamspeak-services.com/releases/${PV}/teamspeak3-server_linux-amd64-${PV}.tar.gz )
	x86? ( http://files.teamspeak-services.com/releases/${PV}/teamspeak3-server_linux-x86-${PV}.tar.gz )"

S="${WORKDIR}/teamspeak3-server_linux-${ARCH}"

pkg_setup() {
	enewuser teamspeak3
}

src_install() {
	local dir="/opt/teamspeak3"

	# Install TeamSpeak 3 server into $dir
	into "${dir}"

	dodoc -r CHANGELOG doc/*.txt
	use doc && dodoc -r serverquerydocs
	use pdf && dodoc doc/*.pdf

	# Install binary, wrapper, shell files and libraries.
	newsbin ts3server_linux_${ARCH} ts3server-bin
	# Standard package installs ts3server to /usr/sbin directory
	dobin "${FILESDIR}/ts3server"
	# Standard package installs scripts and libraries to /opt/teamspeak3-server directory
	dobin *.sh

	# 'dolib' may install to libx32 or lib64 - we just want 'lib' alone
	#dolib.so *.so
	insinto "${dir}"/lib
	doins *.so
	# 'libmysqlclient.so.15' is hard-coded into the ts3-server binary :(
	dosym "${EROOT}"/usr/$(get_libdir)/libmysqlclient.so "${dir}"/lib/libmysqlclient.so.15

	if use tsdns; then
		newdoc tsdns/README README.tsdns
		newdoc tsdns/USAGE USAGE.tsdns
		newsbin tsdns/tsdnsserver_linux_${ARCH} tsdnsserver
		# Standard package installs sample files as documentation
		insinto "${dir}"/sbin
		doins tsdns/tsdns_settings.ini.sample
	fi

	# Standard package installs sql directory to /opt/teamspeak3-server directory
	insinto "${dir}"/lib
	doins -r sql

	insinto /etc/teamspeak3
	doins "${FILESDIR}/server.conf"
	doins "${FILESDIR}/ts3db_mysql.ini"
	newinitd "${FILESDIR}/${PN}-3.0.7.1.rc" teamspeak3

	if use systemd; then
		systemd_dounit "${FILESDIR}/systemd/teamspeak3.service"
		systemd_dotmpfilesd "${FILESDIR}/systemd/teamspeak3.conf"
	fi

	keepdir /{etc,var/{lib,log,run}}/teamspeak3

	# Fix up permissions
	fowners teamspeak3 /{etc,var/{lib,log,run}}/teamspeak3
	fperms 700 /{etc,var/{lib,log,run}}/teamspeak3

	fowners teamspeak3 "${dir}"
	fperms 755 "${dir}"
}
