# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit subversion webapp

DESCRIPTION="Perl scripts and web interface for Heatmiser Wi-Fi Thermostats"
HOMEPAGE="http://code.google.com/p/heatmiser-wifi/"
SRC_URI="http://code.jquery.com/ui/1.7.2/jquery-ui.min.js \
http://www.highcharts.com/downloads/zips/Highstock-1.1.5.zip"
ESVN_REPO_URI="http://heatmiser-wifi.googlecode.com/svn/trunk/"
RESTRICT="nomirror"

LICENSE="GPL-2"
SLOT="0"
WEBAPP_MANUAL_SLOT="yes"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND} \
	virtual/perl-Time-HiRes \
	dev-perl/JSON \
	dev-perl/File-HomeDir \
	dev-perl/Proc-Daemon \
	dev-perl/Proc-PID-File"

need_httpd_cgi

src_unpack() {
	subversion_src_unpack

	for FILE in $A; do
		case "$( basename "$FILE" | sed 's/^.*\.//' )" in
			js)
				if [[ "$FILE" == "jquery-ui.min.js" ]]; then
					cp "$DISTDIR"/"$FILE" "${WORKDIR}"/jquery-1.7.2.min.js || die "File copy failed for file '$FILE'"
				else
					die "File copy failed for unkown file '$FILE'"
				fi
				;;
			zip)
				unpack "$FILE" || die "Unpack failed for file '$FILE'"
				;;
			*)
				die "Unknown file format detected for file '$FILE'"
				;;
		esac
	done
}

src_install() {
	webapp_src_preinst

	dodoc COPYING

	insinto "${MY_HTDOCSDIR}"/
	doins -r "${WORKDIR}"/jquery-1.7.2.min.js "${WORKDIR}"/js/highstock.js html/index.html

	insinto "${MY_CGIBINDIR}"/"${PN}"/
	doins bin/heatmiser_config.pm bin/heatmiser_db.pm
	exeinto "${MY_CGIBINDIR}"/"${PN}"/
	newexe bin/heatmiser_cgi.pl ajax.pl

	rm bin/heatmiser_cgi.pl 2>/dev/null

	insinto /usr/libexec/"${PN}"/
	doins bin/*.pm
	exeinto /usr/libexec/"${PN}"/
	doexe bin/*.pl

	newinitd "${FILESDIR}/${PN}.initd" "${PN}"
	#newconfd "${FILESDIR}/${PN}.confd" "${PN}"

	insinto /etc/
	doins "${FILESDIR}/${PN}.conf"

	keepdir /etc/cron.daily
	dosym /usr/libexec/"${PN}"/heatmiser_time.pl /etc/cron.daily/heatmiser

	# Without this it'll crash at startup. When merging in ROOT= this
	# won't be created by default, so we want to make sure we got it!
	keepdir /var/run
	fowners root:root /var/run
	fperms 0755 /var/run

	webapp_src_install
}

#pkg_postinst() {
	#elog "The cgi-bin directory for ${PN} is /usr/libexec/${PN}/cgi-bin."
	#elog "Set up your ScriptAlias or symbolic links accordingly."
#}
