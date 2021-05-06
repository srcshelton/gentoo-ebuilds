# Copyright (c) 2016 Stuart Shelton <stuart@shelton.me>
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils webapp

DESCRIPTION="RPi-Monitor - always keep an eye on your Raspberry Pi"
HOMEPAGE="http://rpi-experiences.blogspot.fr"
SRC_URI="https://github.com/XavierBerger/RPi-Monitor/archive/v${PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="nomirror"

LICENSE="GPL-3"
WEBAPP_MANUAL_SLOT="yes"
SLOT="0"
KEYWORDS="-* arm arm64"
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
	|| ( ( virtual/perl-JSON-PP dev-perl/JSON-Any ) dev-perl/JSON )
	dev-perl/File-Which
	dev-perl/IPC-ShareLite
	media-libs/raspberrypi-userland"

S="${WORKDIR}/RPi-Monitor-${PV}"

src_prepare() {
	local patch

	cp src/etc/rpimonitor/template/raspbian.conf src/etc/rpimonitor/template/gentoo.conf

	mkdir "${WORKDIR}"/patches
	cp "${FILESDIR}"/"${PV}"/*.patch "${WORKDIR}"/patches/
	if has_version "=media-libs/raspberrypi-userland-9999:0=" || has_version "~media-libs/raspberrypi-userland-9999:0/0="; then
		sed -i \
			-e '/vcgencmd/s|/usr/sbin/|/usr/bin/|' \
			"${WORKDIR}"/patches/*.patch
	fi
	for patch in "${WORKDIR}"/patches/*.patch; do
		epatch "${patch}" || die "epatch failed"
	done

	# Fix version string...
	sed -i \
		-e "s|<b>Version</b>: {DEVELOPMENT} |<b>Version</b>: ${PV} |" \
		   src/usr/share/rpimonitor/web/js/rpimonitor.js || die "Version correction failed"

	chmod 755 "${S}"/tools/conf2man.pl "${S}"/tools/help2man.pl
	[[ -x "${S}"/tools/help2man.pl && -x "${S}"/tools/conf2man.pl ]] \
		|| die "Portage temporary directory must not be mounted 'noexec'"

	cat src/etc/rpimonitor/daemon.conf src/etc/rpimonitor/template/gentoo.conf > rpimonitord.conf

	"${S}"/tools/help2man.pl src/usr/bin/rpimonitord "${PV}" > rpimonitord.1
	"${S}"/tools/conf2man.pl rpimonitord.conf "${PV}" > rpimonitord.conf.5
}

src_compile() {
	# RPi-Monitor now includes a Makefile, but we want to manage things ourselves...
	:
}

src_install() {
	local file

	use httpd && webapp_src_preinst

	doman rpimonitord.1 rpimonitord.conf.5

	dodoc README.md
	newdoc tools/reverseproxy nginx.conf.example

	dodoc src/etc/rpimonitor/template/example.*.conf
	for file in printer storage services wlan dht11 entropy; do
		dodoc src/etc/rpimonitor/template/"${file}".conf
	done
	# We don't want to compress the examples, so that if a user accidentally
	# uncomments an example in their configuration file, it won't break things...
	docompress -x /usr/share/doc
	# Subsequent calls to 'docompress' appear to be ignored :(
	#docompress /usr/share/doc/"${PF}"/README.md
	#docompress /usr/share/doc/"${PF}"/nginx.conf.example
	bzip2 -9 "${ED}"/usr/share/doc/"${PF}"/README.md
	bzip2 -9 "${ED}"/usr/share/doc/"${PF}"/nginx.conf.example

	dosbin src/usr/bin/rpimonitord
	if use tools; then
		exeinto /usr/share/"${PN}"/tools
		doexe tools/{addnginxuser.sh,make_ca.sh,make_cert.sh,netTraffic.sh,openssl.cnf}
	fi

	newconfd "${FILESDIR}"/rpimonitor.confd rpimonitor
	newinitd "${FILESDIR}"/rpimonitor.initd rpimonitor
	dodir /etc/rpimonitord.conf.d
	insinto /etc/rpimonitord.conf.d
	newins src/etc/rpimonitor/template/gentoo.conf data.conf
	for file in version uptime cpu temperature memory swap sdcard network; do
		doins src/etc/rpimonitor/template/"${file}".conf
	done
	doins "${FILESDIR}"/battery.conf

	if use httpd; then
		# Try to determine the real root directory...
		if [[ -n "${vhost_root}" || -r /etc/vhosts/webapp-config ]]; then
			if ! [[ -n "${vhost_root}" && -n "${vhost_htdocs_insecure}" ]]; then
				# Do this twice, so that variables defined in terms of other
				# values are correctly initialised...
				source /etc/vhosts/webapp-config
				source /etc/vhosts/webapp-config
			fi
			INSTROOT="${vhost_root}/${vhost_htdocs_insecure}"
		else
			INSTROOT="${EROOT}/var/www/localhost/htdocs"
		fi
	
		insinto "${MY_HTDOCSDIR}"
		doins -r src/usr/share/rpimonitor/web/*
		dodir "${MY_HTDOCSDIR}"/custom/net_traffic
		dodir "${MY_HTDOCSDIR}"/stat
	
		webapp_serverowned "${MY_HTDOCSDIR}"/custom
		webapp_serverowned "${MY_HTDOCSDIR}"/custom/net_traffic
		webapp_serverowned "${MY_HTDOCSDIR}"/stat
	else
		INSTROOT="${EROOT}/usr/share"
	
		insinto /usr/share/"${PN}"
		doins -r src/usr/share/rpimonitor/web/*
		diropts -m 0775 -o nobody -g nogroup

		dodir /var/lib/"${PN}"/custom/net_traffic
		dodir /var/lib/"${PN}"/stat

		dosym ../../../var/lib/"${PN}"/stat /usr/share/"${PN}"/stat
		dosym ../../../var/lib/"${PN}"/custom /usr/share/"${PN}"/custom
	fi

	sed -i \
		-e "s|^#daemon.webroot=/usr/share/rpimonitor/web$|daemon.webroot=${INSTROOT/\/\///}/${PN}|" \
		-e "s|^#daemon.datastore=/var/lib/rpimonitor$|daemon.datastore=/var/lib/${PN}|" \
		-e "s|^#daemon.user=pi$|daemon.user=nobody|" \
		-e "s|^#daemon.group=pi$|daemon.group=nogroup|" \
		src/etc/rpimonitor/daemon.conf
	insinto /etc/
	newins src/etc/rpimonitor/daemon.conf rpimonitord.conf

	use httpd && webapp_src_install
}

pkg_postinst() {
	einfo "Edit the file /etc/rpimonitord.conf.d/data.conf to configure RPi-Monitor"
	echo
	ewarn "If graphs display incorrect data or values are shown as 'NaN' in the"
	ewarn "web-interface, especially after configuration changes, try stopping"
	ewarn "RPi-Monitor and deleting the affected .rrd files from"
	ewarn "/var/lib/${PN} before restarting RPi-Monitor - which should clear"
	ewarn "any problems caused by changes in format."
	echo
	ewarn "In release 2.10, the single configuration file 'default.conf' has been"
	ewarn "split up into 'data.conf' and multiple sub-configuration files.  Please"
	ewarn "migrate your 'default.conf' to the new file structure, after which it can"
	ewarn "be deleted."
	ewarn "Please note that configuration files are simply concatenated, and so care"
	ewarn "must be taken not to accidentally re-use Object ID numbers, which are now"
	ewarn "split across multiple files."
	echo
	einfo "If network data collected by earlier versions of ${PN} cause anomalous peaks"
	einfo "to appear on network graphs, this can be resolved by adjusting the network"
	einfo "RRD databases:"
	echo
	if use httpd; then
		# Try to determine the real root directory...
		if [[ -n "${vhost_root}" || -r /etc/vhosts/webapp-config ]]; then
			if ! [[ -n "${vhost_root}" && -n "${vhost_htdocs_insecure}" ]]; then
				# Do this twice, so that variables defined in terms of other
				# values are correctly initialised...
				source /etc/vhosts/webapp-config
				source /etc/vhosts/webapp-config
			fi
			INSTROOT="${vhost_root}/${vhost_htdocs_insecure}"
		else
			INSTROOT="${EROOT}/var/www/localhost/htdocs"
		fi
	else
		INSTROOT="${EROOT}/var/lib/${PN}"
	fi
	einfo "rrdtool tune ${INSTROOT//\/\///}/stat/net_received.rrd -a net_received:0"
	einfo "rrdtool tune ${INSTROOT//\/\///}/stat/net_send.rrd -i net_send:0"
}
