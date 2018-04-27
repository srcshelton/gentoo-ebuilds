# Copyright 2013-2018 Stuart Shelton
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3 webapp

VER_HC='6.0.7' # Unversioned - this is latest
VER_JQ='2.0.2' # Hard-coded
SUB_JQ='' # Previously 'ui'

DESCRIPTION="Perl scripts and web interface for Heatmiser Wi-Fi Thermostats"
HOMEPAGE="https://github.com/thoukydides/heatmiser-wifi"
SRC_URI="
	${SUB_JQ:+https://code.jquery.com/${SUB_JQ:+${SUB_JQ}/}/${VER_JQ}/jquery${SUB_JQ:+-${SUB_JQ}}.min.js -> jquery${SUB_JQ:+-${SUB_JQ}}-${VER_JQ}.min.js}
	${SUB_JQ:-https://code.jquery.com/jquery-${VER_JQ}.min.js}
	https://code.highcharts.com/zips/Highstock-${VER_HC}.zip
"
EGIT_REPO_URI="https://github.com/thoukydides/heatmiser-wifi.git"
RESTRICT="nomirror"

LICENSE="GPL-2"
SLOT="0"
WEBAPP_MANUAL_SLOT="yes"
IUSE=""

RDEPEND="
	virtual/perl-Time-HiRes
	dev-perl/File-HomeDir
	dev-perl/JSON
	dev-perl/Proc-Daemon
	dev-perl/Proc-PID-File
"

need_httpd_cgi

PATCHES=( "${FILESDIR}/${PN}-highcharts-version.patch" )

src_unpack() {
	git-r3_src_unpack

	for FILE in ${A}; do
		case "$( basename "${FILE}" | sed 's/^.*\.//' )" in
			js)
				if [[ "${FILE}" == "jquery${SUB_JQ:+-${SUB_JQ}}-${VER_JQ}.min.js" ]]; then
					cp "${DISTDIR}/${FILE}" "${WORKDIR}/jquery-${VER_JQ}.min.js" || die "File copy failed for file '${FILE}'"
				else
					die "File copy failed for unkown file '${FILE}'"
				fi
				;;
			zip)
				unpack "${FILE}" || die "Unpack failed for file '${FILE}'"
				;;
			*)
				die "Unknown file extension detected for file '${FILE}'"
				;;
		esac
	done
}

src_install() {
	webapp_src_preinst

	dodoc COPYING

	insinto "${MY_HTDOCSDIR}"
	if [[ -r "${WORKDIR}"/js/highstock.js ]]; then
		doins -r "${WORKDIR}/jquery-${VER_JQ}.min.js" "${WORKDIR}"/js/highstock.js html/index.html
	else
		doins -r "${WORKDIR}/jquery-${VER_JQ}.min.js" "${WORKDIR}"/code/js/highstock.js html/index.html
	fi

	insinto "${MY_CGIBINDIR}/${PN}"
	doins bin/heatmiser_config.pm bin/heatmiser_db.pm
	exeinto "${MY_CGIBINDIR}/${PN}"
	newexe bin/heatmiser_cgi.pl ajax.pl

	rm bin/heatmiser_cgi.pl 2>/dev/null

	insinto /usr/libexec/"${PN}"
	doins bin/*.pm
	exeinto /usr/libexec/"${PN}"
	doexe bin/*.pl

	newinitd "${FILESDIR}/${PN}.initd" "${PN}"
	newconfd "${FILESDIR}/${PN}.confd" "${PN}"

	insinto /etc
	doins "${FILESDIR}/${PN}.conf"

	keepdir /etc/cron.daily
	dosym /usr/libexec/"${PN}"/heatmiser_time.pl /etc/cron.daily/heatmiser

	# Without this it'll crash at startup. When merging in ROOT= this
	# won't be created by default, so we want to make sure we have it!
	#keepdir /var/run
	#fowners root:root /var/run
	#fperms 0755 /var/run

	webapp_src_install
}

#pkg_postinst() {
	#elog "The cgi-bin directory for ${PN} is /usr/libexec/${PN}/cgi-bin."
	#elog "Set up your ScriptAlias or symbolic links accordingly."
#}
