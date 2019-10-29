# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: b3f6bafbe9f17cc31045ec6c9a0cfc2ccc569e05 $

EAPI=6

inherit multilib systemd user

DESCRIPTION="Crystal Clear Cross-Platform Voice Communication Server"
HOMEPAGE="https://www.teamspeak.com/"
SRC_URI="
	amd64? ( http://teamspeak.gameserver.gamed.de/ts3/releases/${PV}/teamspeak3-server_linux_amd64-${PV}.tar.bz2 )
	x86? ( http://teamspeak.gameserver.gamed.de/ts3/releases/${PV}/teamspeak3-server_linux_x86-${PV}.tar.bz2 )"

SLOT="0"
LICENSE="teamspeak3 GPL-2"
IUSE="+doc html systemd tsdns"
KEYWORDS="~amd64 ~x86"

RESTRICT="installsources mirror strip"

S="${WORKDIR}/teamspeak3-server_linux_${ARCH}"

QA_PREBUILT="opt/teamspeak3"

pkg_setup() {
	enewuser teamspeak
}

src_install() {
	local opt_dir="/opt/teamspeak3"

	# Install TeamSpeak 3 server into /opt/teamspeak3.
	into "${opt_dir}"

	# Install documentation.
	dodoc -r CHANGELOG doc/*.txt
	use doc && dodoc -r serverquerydocs && \
		docompress -x /usr/share/doc/${PF}/serverquerydocs && \
		dosym ../../usr/share/doc/${PF}/serverquerydocs ${opt_dir}/serverquerydocs
	use html && dodoc -r doc/serverquery && \
		docompress -x /usr/share/doc/${PF}/serverquery && \
		dosym ../../../usr/share/doc/${PF}/serverquery ${opt_dir}/doc/serverquery

	# Install binary, wrapper, shell files and libraries.
	newsbin ts3server ts3server-bin
	# Standard package installs ts3server to /usr/sbin directory
	dobin "${FILESDIR}"/ts3server

	# 'dolib' may install to libx32 or lib64 - we just want 'lib' alone
	insinto "${opt_dir}"/lib
	doins *.so redist/libmariadb.so.2

	if use tsdns; then
		newdoc tsdns/README README.tsdns
		newdoc tsdns/USAGE USAGE.tsdns
		dosbin tsdns/tsdnsserver
		# Standard package installs sample files as documentation
		insinto "${opt_dir}"/sbin
		doins tsdns/tsdns_settings.ini.sample
	fi

	# Standard package installs sql directory to /opt/teamspeak3-server directory
	insinto "${opt_dir}"/lib
	doins -r sql

	# Install the runtime FS layout.
	insinto /etc/teamspeak3
	doins "${FILESDIR}"/server.conf "${FILESDIR}"/ts3db_mariadb.ini

	# Install the init script and systemd unit.
	newinitd "${FILESDIR}"/${PN}-init-r1 teamspeak3
	newconfd "${FILESDIR}"/${PN}-conf-r1 teamspeak3
	if use systemd; then
		systemd_newunit "${FILESDIR}"/systemd/teamspeak3-r1.service teamspeak3.service
		systemd_newtmpfilesd "${FILESDIR}"/systemd/teamspeak3.conf teamspeak3.conf
	fi

	dodir "${opt_dir}"/license
	keepdir /{etc,var/{lib,log}}/teamspeak3

	# Fix up permissions.
	fowners teamspeak /{etc,var/{lib,log}}/teamspeak3
	fperms 700 /{etc,var/{lib,log}}/teamspeak3

	fowners teamspeak "${opt_dir}"
	fperms 755 "${opt_dir}"
}

pkg_postinst() {
	einfo "On the first server start (or after clearing the database) *ONLY*, a new"
	einfo "single-use 'ServerAdmin' key will be logged to"
	einfo
	einfo "    /var/log/teamspeak3/ts3server_1.log"
	einfo
	einfo "... the log file for the first TeamSpeak Virtual Server instance."
	einfo
	einfo "You will need to use this key in order to gain instance admin rights."
	einfo
	einfo "Starting with version 3.0.13, there are two important changes:"
	einfo " - IPv6 is now supported."
	einfo " - Binding to any address (0.0.0.0 / 0::0),"
	einfo "   instead of just the default ip of the network interface."
}
