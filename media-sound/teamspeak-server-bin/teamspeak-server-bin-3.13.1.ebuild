# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit systemd user

DESCRIPTION="Voice chat software designed with security in mind"
HOMEPAGE="https://www.teamspeak.com/"
SRC_URI="amd64? ( https://files.teamspeak-services.com/releases/server/${PV}/teamspeak3-server_linux_amd64-${PV}.tar.bz2 )
	x86? ( https://files.teamspeak-services.com/releases/server/${PV}/teamspeak3-server_linux_x86-${PV}.tar.bz2 )"

LICENSE="LGPL-2.1 teamspeak3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+doc html systemd tsdns" # mysql

# RDEPEND="mysql? ( dev-db/mariadb-connector-c:0=
#		<dev-libs/openssl-1.1:0=
#		sys-libs/zlib )"

RESTRICT="installsources mirror strip"

S="${WORKDIR}/teamspeak3-server_linux_${ARCH}"

QA_PREBUILT="
		opt/teamspeak3/libmariadb.so.2
		opt/teamspeak3/libts3_mariadb.so
		opt/teamspeak3/libts3_sqlite3.so
		opt/teamspeak3/libts3_ssh.so
		opt/teamspeak3/sbin/ts3server-bin"

pkg_setup() {
	enewgroup teamspeak
	enewuser teamspeak -1 -1 /opt/teamspeak3 teamspeak
}

src_install() {
	local opt_dir="/opt/teamspeak3"

	# Install TeamSpeak 3 server into /opt/teamspeak3.
	into "${opt_dir}"
	insinto "${opt_dir}"

	# Accept license
	touch "${T%/}"/.ts3server_license_accepted || die
	doins "${T}"/.ts3server_license_accepted

	newsbin ts3server ts3server-bin
	# Standard package installs ts3server to /usr/sbin directory
	dobin "${FILESDIR}"/ts3server

	# 'dolib' may install to libx32 or lib64 - we just want 'lib' alone
	insinto "${opt_dir}"/lib
	doins *.so redist/libmariadb.so.2
	#doins libts3db_sqlite3.so

	# Standard package installs sql directory to /opt/teamspeak3-server directory
	insinto "${opt_dir}"/lib
	doins -r sql

	insinto /etc/teamspeak3
	doins "${FILESDIR}"/server.conf "${FILESDIR}"/ts3db_mariadb.ini

	newinitd "${FILESDIR}"/${PN/-server-bin}.initd teamspeak3
	newconfd "${FILESDIR}"/${PN}-conf-r1 teamspeak3
	if use systemd; then
		systemd_newunit "${FILESDIR}"/${PN/-server-bin}.service teamspeak3.service
		systemd_newtmpfilesd "${FILESDIR}"/${PN/-server-bin}.tmpfiles teamspeak3.conf
	fi

	# Install optional mysql
	#if use mysql; then
	#	insinto "/etc/teamspeak3"
	#	doins "${FILESDIR}/ts3server_mariadb.ini.sample"
	#	doins "${FILESDIR}/ts3db_mariadb.ini.sample"
	#
	#	insinto "${opt_dir}"
	#	doins "libts3db_mariadb.so"
	#
	#	insinto "${opt_dir}/lib/sql"
	#	doins -r "sql/create_mariadb"
	#	doins -r "sql/updates_and_fixes"
	#fi

	dodoc -r CHANGELOG doc/*.txt
	if use doc; then
		dodoc -r serverquerydocs
		docompress -x /usr/share/doc/${PF}/serverquerydocs
		dosym ../../usr/share/doc/${PF}/serverquerydocs ${opt_dir}/serverquerydocs
	fi
	if use html; then
		local HTML_DOCS=( "doc/serverquery/." )

		dodoc -r doc/serverquery
		docompress -x /usr/share/doc/${PF}/serverquery
		dosym ../../../usr/share/doc/${PF}/serverquery ${opt_dir}/doc/serverquery
	fi

	if use tsdns; then
		newdoc tsdns/README README.tsdns
		newdoc tsdns/USAGE USAGE.tsdns
		dosbin tsdns/tsdnsserver
		insinto "/etc/teamspeak3"
		doins tsdns/tsdns_settings.ini.sample
	fi

	einstalldocs

	keepdir "/etc/teamspeak3"
	keepdir "/var/log/teamspeak3"

	# Protect config
	#if use mysql; then
	#	echo "CONFIG_PROTECT=\"/etc/teamspeak3/ts3server.ini /etc/teamspeak3/ts3server_mariadb.ini\"" > "${T}"/99teamspeak3-server || die
	#else
	#	echo "CONFIG_PROTECT=\"/etc/teamspeak3/ts3server.ini\"" > "${T}"/99teamspeak3-server || die
	#fi
	#doenvd "${T}"/99teamspeak3-server

	fowners teamspeak:teamspeak "${opt_dir}" /var/log/teamspeak3
	fperms 755 /etc/teamspeak3
	fperms 755 /var/log/teamspeak3
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
	elog "If you have a Non-Profit License (NPL), place it in"
	elog "/etc/teamspeak3 as licensekey.dat."
}
