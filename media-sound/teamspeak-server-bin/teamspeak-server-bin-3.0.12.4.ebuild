# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: a382c49b1c0a4ddda8031d59e9fc8152bb72e329 $

EAPI=5

inherit eutils multilib systemd user

DESCRIPTION="TeamSpeak Voice Communication Server"
HOMEPAGE="http://www.teamspeak.com/"
SRC_URI="
	amd64? ( http://teamspeak.gameserver.gamed.de/ts3/releases/${PV}/teamspeak3-server_linux_amd64-${PV}.tar.bz2 )
	x86? ( http://teamspeak.gameserver.gamed.de/ts3/releases/${PV}/teamspeak3-server_linux_x86-${PV}.tar.bz2 )"

SLOT="0"
LICENSE="teamspeak3 GPL-2"
IUSE="+doc html systemd tsdns"
KEYWORDS="~amd64 ~x86"

RESTRICT="installsources mirror strip"

S="${WORKDIR}/teamspeak3-server_linux_${ARCH}"

QA_PREBUILT="/opt/teamspeak3"

pkg_setup() {
	enewuser teamspeak3
}

src_install() {
	local dir="/opt/teamspeak3"

	# Install TeamSpeak 3 server into $dir
	into "${dir}"

	# Install documentation.
	dodoc -r CHANGELOG doc/*.txt
	use doc && dodoc -r serverquerydocs && \
		docompress -x /usr/share/doc/${PF}/serverquerydocs && \
		dosym ../../usr/share/doc/${PF}/serverquerydocs ${dir}/serverquerydocs
	use html && dodoc -r doc/serverquery && \
		docompress -x /usr/share/doc/${PF}/serverquery && \
		dosym ../../../usr/share/doc/${PF}/serverquery ${dir}/doc/serverquery

	# Install binary, wrapper, shell files and libraries.
	newsbin ts3server ts3server-bin
	# Standard package installs ts3server to /usr/sbin directory
	dobin "${FILESDIR}"/ts3server

	# 'dolib' may install to libx32 or lib64 - we just want 'lib' alone
	insinto "${dir}"/lib
	doins *.so redist/libmariadb.so.2

	if use tsdns; then
		newdoc tsdns/README README.tsdns
		newdoc tsdns/USAGE USAGE.tsdns
		dosbin tsdns/tsdnsserver
		# Standard package installs sample files as documentation
		insinto "${dir}"/sbin
		doins tsdns/tsdns_settings.ini.sample
	fi

	# Standard package installs sql directory to /opt/teamspeak3-server directory
	insinto "${dir}"/lib
	doins -r sql

	# Install the runtime FS layout.
	insinto /etc/teamspeak3
	doins "${FILESDIR}"/server.conf "${FILESDIR}"/ts3db_mariadb.ini

	# Install the init script and systemd unit.
	newinitd "${FILESDIR}"/${PN}-init-r1 teamspeak3
	newconfd "${FILESDIR}"/${PN}-conf-r1 teamspeak3
	if use systemd; then
		systemd_dounit "${FILESDIR}"/systemd/teamspeak3.service
		systemd_dotmpfilesd "${FILESDIR}"/systemd/teamspeak3.conf
	fi

	dodir "${dir}"/license
	keepdir /{etc,var/{lib,log}}/teamspeak3

	# Fix up permissions.
	fowners teamspeak3 /{etc,var/{lib,log}}/teamspeak3
	fperms 700 /{etc,var/{lib,log}}/teamspeak3

	fowners teamspeak3 "${dir}"
	fperms 755 "${dir}"
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
}
