# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit webapp

DESCRIPTION="An intelligent Siri Proxy with multiple key storage and key throttling"
HOMEPAGE="https://github.com/interstateone/The-Three-Little-Pigs-Siri-Proxy/"
SRC_URI="https://github.com/interstateone/The-Three-Little-Pigs-Siri-Proxy/archive/v${PV}.zip"
RESTRICT="nomirror"

LICENSE="CCPL-Attribution-ShareAlike-NonCommercial-3.0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="virtual/httpd-php
	app-admin/webapp-config
	virtual/mysql
	|| ( dev-lang/php[mysql] dev-lang/php[mysqli] )"

need_httpd_cgi

S="${WORKDIR}/The-Three-Little-Pigs-Siri-Proxy-${PV}/WebInterface"

src_install() {
	webapp_src_preinst

	dodoc README.md

	dodir "${MY_HTDOCSDIR}"/certificates
	insinto "${MY_HTDOCSDIR}"
	doins -r design files img inc js pages *.php

	webapp_configfile "${MY_HTDOCSDIR}"/inc/{captcha,connection,functions,mydbclass}.inc.php
	webapp_configfile "${MY_HTDOCSDIR}"/pages/pages.xml
	webapp_serverowned "${MY_HTDOCSDIR}"/inc

	webapp_src_install
}

pkg_postinst() {
	einfo "Please check the hard-coded values in inc/*.inc.php"
	einfo "and copy 'ca.pem' from app-misc/siriproxy to certificates"
}
