# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit depend.php subversion webapp

DESCRIPTION="Observium is an autodiscovering SNMP based network monitoring platform"
HOMEPAGE="http://www.observium.org/"
#SRC_URI=""

PREV="3763"
ESVN_REPO_URI="http://www.observium.org/svn/observer/trunk@${PREV}"

LICENSE="QPL-1.0"
KEYWORDS="~x86 ~amd64"
IUSE="+examples ipmi libvirt +mibs tools +web"

HDEPEND="
	sys-apps/coreutils
	sys-apps/findutils
	sys-apps/sed
	"
DEPEND=""
RDEPEND="${DEPEND}
	>=net-analyzer/net-snmp-5.4
	>=net-analyzer/rrdtool-1.3
	>=virtual/httpd-php-5.3
	virtual/cron
	dev-php/PEAR-Net_IPv4
	dev-php/PEAR-Net_IPv6
	net-analyzer/fping
	media-fonts/dejavu
	media-gfx/graphviz
	media-gfx/imagemagick
	net-analyzer/mtr
	net-analyzer/nmap
	net-misc/whois
	ipmi? ( sys-apps/ipmitool )
	libvirt? ( app-emulation/libvirt )
	tools? (
		dev-lang/python
		dev-python/mysql-python
	)
	"

function get_stable_revision() {
	if getent hosts www.observium.org >/dev/null 2>&1; then
		if type -pf curl >/dev/null 2>&1; then
			curl http://www.observium.org/stable.php
			return 0
		fi
	fi
	return 1
}

pkg_pretend() {
	local result

	VERSION="$( get_stable_revision )"
	result=$?

	if [[ -n "$VERSION" ]] && ! (( result )); then
		if ! [[ "$VERSION" == "$PREV" ]]; then
			ewarn "This ebuild is for ${PN} revision ${PREV} - the current" \
				"stable release is revision ${VERSION}."
		else
			einfo "Release ${VERSION} is the current stable release"
		fi
	fi
}

pkg_setup() {
	webapp_pkg_setup
	require_php_with_use cli cgi mysql gd snmp
}

src_prepare() {
	epatch "${FILESDIR}"/"${PF}"-version.patch || \
		die "epatch for version failed"

	use mibs || rm -r "${S}"/mibs
}

src_install() {
	use web && webapp_src_preinst

	# Install non-webapp binaries to /usr/share/observium...
	insinto /usr/share/${PN}

	# Prune an unused directory...
	[[ -d scripts/agent-local/munin-scripts ]] \
		&& rmdir scripts/agent-local/munin-scripts 2>/dev/null

	doins -r attic contrib scripts upgrade-scripts

	find "${ED}"/usr/share/"${PN}"/ -type f -not \( \
		-name README -or -name \*.cnf -or -name \*.conf -or -name \*.inc.php \
	\) -print | while read FILE; do
		fperms 0755 "$( sed "s|${ED}||" <<<"$FILE" )"
	done

	use mibs && [[ -d mibs ]] && doins -r mibs

	# Install configuration examples...
	if use examples; then
		dodoc "${FILESDIR}"/observium.lighttpd
		dodoc "${FILESDIR}"/observium.apache
		dodoc *.example
	fi

	if use web; then
		insinto "${MY_HTDOCSDIR}"/
		doins config.php.default *.php
		use tools && doins poller-wrapper.py
		doins -r html includes sql-schema

		mv "${ED}/${MY_HTDOCSDIR}"/config.php.default "${ED}/${MY_HTDOCSDIR}"/config.php
		webapp_configfile ${MY_HTDOCSDIR}/config.php

		for DIR in graphs logs rrd tmp; do
			mkdir "${ED}/${MY_HTDOCSDIR}"/${DIR}
			webapp_serverowned "${MY_HTDOCSDIR}"/${DIR}
		done
		use mibs \
			&& dosym /usr/share/"${PN}"/mibs "${MY_HTDOCSDIR}"/mibs

		# Create appropriate cron.d entry...
		dodir /etc/cron.d/

		use tools && SCRIPT="poller-wrapper.py 1" || SCRIPT="poller.php -h all"

		[[ -n "${EROOT}" && "${EROOT}" != "/" ]] \
			&& LOC="\"${EROOT}\"/var/www/localhost/htdocs" \
			|| LOC="/var/www/localhost/htdocs"

		# Ideally, this would be performed as the appropriate web-server user
		# (lighttpd, nginx, apache, etc.)...
		cat >"${ED}"/etc/cron.d/${PN} <<EOF
33	*/6	* * *	root	test -x ${LOC}/"${PN}"/discovery.php && ${LOC}/"${PN}"/discovery.php -h all >/dev/null 2>&1
*/5	*	* * *	root	test -x ${LOC}/"${PN}"/discovery.php && ${LOC}/"${PN}"/discovery.php -h new >/dev/null 2>&1
*/5	*	* * *	root	test -x ${LOC}/"${PN}"/${SCRIPT} && ${LOC}/"${PN}"/${SCRIPT} >/dev/null 2>&1
EOF

		webapp_postinst_txt en "${FILESDIR}"/postinstall-en.txt

		webapp_src_install

		for FILE in discovery.php addhost.php adduser.php \
			includes/sql-schema/update.php; do
			fperms 0755 "${MY_HTDOCSDIR}"/"$FILE"
		done
	fi
}

pkg_postinst() {
	use web && ! use mibs && ewarn \
		"You have chosen not to install Observium MIBs - you *must* copy" \
		"(or create a symlink to) a directory containing MIB files" \
		"as '${VHOST_ROOT}/htdocs/${PN}/mibs'."

	[[ -n "${EROOT}" && "${EROOT}" != "/" ]] \
		&& LOC="\"${EROOT}\"/usr/share/doc/${PF}" \
		|| LOC="/usr/share/doc/${PF}"
	einfo "Example configuration files for Apache and lighttpd have been" \
		"installed to '$LOC'."

	ewarn "For security reasons, you may wish to edit /etc/cron.d/${PN}" \
		"and change the discovery and poll processes to run as your webserver" \
		"user (e.g. lighttpd, nginx, or apache) rather than 'root'."
}
