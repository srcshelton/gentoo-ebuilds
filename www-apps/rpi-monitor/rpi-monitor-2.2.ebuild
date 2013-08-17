# Copyright (c) 2013 Stuart Shelton <stuart@shelton.me>
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils

DESCRIPTION="RPi-Monitor - always keep an eye on your Raspberry Pi"
HOMEPAGE="http://rpi-experiences.blogspot.fr"
SRC_URI="https://github.com/XavierBerger/RPi-Monitor/archive/v${PV}.zip -> ${P}.zip
	https://github.com/XavierBerger/RPi-Monitor-deb/archive/v${PV}.zip -> ${PN}-deb-${PV}.zip"
RESTRICT="nomirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* arm"
IUSE="httpd tools"

DEPEND="app-admin/webapp-config"
RDEPEND="
	httpd? (
		virtual/httpd-cgi
	)
	!httpd? (
		dev-perl/HTTP-Daemon
	)
	net-analyzer/rrdtool[perl]
	|| ( ( virtual/perl-JSON-PP dev-perl/JSON-Any ) dev-perl/JSON )"

if use httpd; then
	inherit webapp

	need_httpd_cgi
fi

S="${WORKDIR}/RPi-Monitor-${PV}"

src_prepare() {
	epatch "${FILESDIR}"/default.conf.patch \
		|| die "epatch failed"

	cp "${S}"/../RPi-Monitor-deb-"${PV}"/conf2man.pl .
	cp "${S}"/../RPi-Monitor-deb-"${PV}"/help2man.pl .
	chmod 755 conf2man.pl help2man.pl

	[[ -x ./help2man.pl && -x conf2man.pl ]] \
		|| die "Portage temporary directory must not be mounted 'noexec'"

	cat rpimonitor/rpimonitord.conf rpimonitor/default.conf > rpimonitord.conf

	./help2man.pl rpimonitor/rpimonitord "${PV}" > rpimonitord.1
	./conf2man.pl rpimonitord.conf "${PV}" > rpimonitord.conf.5
}

src_install() {
	use httpd && webapp_src_preinst

	doman rpimonitord.1 rpimonitord.conf.5

	dodoc README.md
	newdoc tools/reverseproxy nginx.conf.example
	newdoc rpimonitor/custo.conf custom.conf
	dodoc rpimonitor/default.conf

	dosbin rpimonitor/rpimonitord
	if use tools; then
		exeinto /usr/share/"${PN}"/tools
		doexe tools/{addnginxuser.sh,make_ca.sh,make_cert.sh,netTraffic.sh,openssl.cnf}
	fi

	newconfd "${FILESDIR}"/rpimonitor.confd rpimonitor
	newinitd "${FILESDIR}"/rpimonitor.initd rpimonitor
	dodir /etc/rpimonitord.conf.d
	insinto /etc/rpimonitord.conf.d
	doins rpimonitor/default.conf

	if use httpd; then
		INSTROOT="${EROOT}/var/www/localhost/htdocs"
	
		insinto "${MY_HTDOCSDIR}"
		doins -r rpimonitor/web/*
		dodir "${MY_HTDOCSDIR}"/custom/net_traffic
		dodir "${MY_HTDOCSDIR}"/stat
	
		webapp_serverowned "${MY_HTDOCSDIR}"/custom
		webapp_serverowned "${MY_HTDOCSDIR}"/custom/net_traffic
		webapp_serverowned "${MY_HTDOCSDIR}"/stat
	else
		INSTROOT="${EROOT}/usr/share"
	
		insinto /usr/share/rpi-monitor
		doins -r rpimonitor/web/*
		diropts -m 0775 -o nobody -g nogroup

		dodir /var/lib/rpi-monitor/custom/net_traffic
		dodir /var/lib/rpi-monitor/stat

		dosym ../../../var/lib/rpi-monitor/stat /usr/share/rpi-monitor/stat
		dosym ../../../var/lib/rpi-monitor/custom /usr/share/rpi-monitor/custom
	fi

	sed -i \
		-e "s|^#daemon.webroot=./web$|daemon.webroot=${INSTROOT/\/\///}/rpi-monitor|" \
		-e "s|^#daemon.user=pi$|daemon.user=nobody|" \
		-e "s|^#daemon.group=pi$|daemon.group=nogroup|" \
		rpimonitor/rpimonitord.conf
	insinto /etc/
	doins rpimonitor/rpimonitord.conf

	use httpd && webapp_src_install
}

pkg_postinst() {
	einfo "Edit the file /etc/rpimonitord.conf to configure RPI Monitor"
}
