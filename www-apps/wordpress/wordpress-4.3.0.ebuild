# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: ff967901f237d9cc7562f7ee871287c7f56202d5 $

EAPI=5

inherit webapp

DESCRIPTION="Wordpress PHP and MySQL based content management system (CMS)"
HOMEPAGE="https://wordpress.org/"
MY_PV="${PV%.0}"
SRC_URI="https://wordpress.org/${PN}-${MY_PV/_rc/-RC}.tar.gz"

LICENSE="GPL-2+"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~ppc64 ~sparc ~x86"

RDEPEND="virtual/httpd-php
	|| ( dev-lang/php[mysql] dev-lang/php[mysqli] )"

S=${WORKDIR}/${PN}

need_httpd_cgi

IUSE="+akismet examples +themes vhosts"

# Override default of SLOT="${PVR}"
WEBAPP_MANUAL_SLOT=yes
SLOT="${PV}"

src_install() {
	webapp_src_preinst

	dohtml readme.html
	rm readme.html license.txt || die

	if ! use akismet ; then
		rm -R wp-content/plugins/akismet/ || die
	fi
	if ! use examples ; then
		rm wp-content/plugins/hello.php || die
	fi
	if ! use themes ; then
		rm -R wp-content/themes/*/ || die
	fi

	[[ -f wp-config.php ]] || cp wp-config-sample.php wp-config.php

	insinto "${MY_HTDOCSDIR}"
	doins -r .

	webapp_serverowned "${MY_HTDOCSDIR}"/index.php
	webapp_serverowned "${MY_HTDOCSDIR}"/wp-admin/menu.php
	webapp_serverowned "${MY_HTDOCSDIR}"

	webapp_configfile  "${MY_HTDOCSDIR}"/wp-config.php

	webapp_postinst_txt en "${FILESDIR}"/postinstall-en.txt
	webapp_postupgrade_txt en "${FILESDIR}"/postupgrade-en.txt

	webapp_src_install
}
