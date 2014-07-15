# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/mail-client/roundcube/roundcube-0.9.5.ebuild,v 1.5 2013/10/26 06:46:04 ago Exp $

EAPI=5

inherit webapp

MY_PN=${PN}mail
MY_P=${MY_PN}-${PV/_/-}

PHAR="1.0.0-alpha8"

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="http://roundcube.net"
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.tar.gz
	https://getcomposer.org/download/${PHAR}/composer.phar"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"
KEYWORDS="amd64 arm ~hppa ppc ~ppc64 ~sparc x86"
IUSE="ldap +mysql plugins postgres sqlite ssl spell"

RDEPEND="virtual/httpd-php
	>=dev-lang/php-5.3[crypt,gd,iconv,json,ldap?,pdo,postgres?,session,sockets,ssl?,xml,unicode]
	>=dev-php/PEAR-Crypt_GPG-1.4.0_beta1
	mysql? ( || ( dev-lang/php[mysql] dev-lang/php[mysqli] ) )
	plugins? ( >=dev-lang/php-5.3.4[ctype,filter,hash,json,phar,ssl] )
	spell? ( dev-lang/php[curl,spell] )
	sqlite? ( || ( dev-lang/php[sqlite] dev-lang/php[sqlite3] ) )"

need_httpd_cgi

S=${WORKDIR}/${MY_P}

src_prepare() {
	cp config/config.inc.php{.sample,} || die
	cp composer.json{-dist,} || die

	# Remove bundled PEAR packages
	rm -r program/lib/Crypt || die
}

src_install() {
	webapp_src_preinst

	dodoc CHANGELOG INSTALL README.md UPGRADING

	insinto "${MY_HTDOCSDIR}"
	doins -r [[:lower:]]* SQL
	doins .htaccess
	use plugins && doins "${DISTDIR}"/composer.phar

	webapp_serverowned "${MY_HTDOCSDIR}"/logs
	webapp_serverowned "${MY_HTDOCSDIR}"/temp

	webapp_configfile "${MY_HTDOCSDIR}"/config/config.inc.php
	webapp_configfile "${MY_HTDOCSDIR}"/composer.json

	webapp_postinst_txt en "${FILESDIR}"/postinstall-en-0.6.txt
	webapp_postupgrade_txt en "${FILESDIR}"/postupgrade-en-0.6.txt
	webapp_postupgrade_txt en UPGRADING

	webapp_src_install

	# fperms must occur after webapp_src_install is called...

	# The second command here fails, for non-obvious reasons... earlier
	# versions, which do not differ, continue to execute correctly.  Odd.
	#[[ -d "${ED}"/"${MY_HTDOCSDIR}"/bin ]] || die "Cannot locate roundcube 'bin' directory in '${ED}/${MY_HTDOCSDIR}'"
	#fperms 0755 "${MY_HTDOCSDIR}"/bin/*.sh || die "Cannot set file permissions in '${ED}/${MY_HTDOCSDIR}'"
	find "${ED}"/"${MY_HTDOCSDIR}"/bin/ -type f -name \*.sh -exec fperms 0755 {} \; || die "Cannot set file permissions in '${ED}/${MY_HTDOCSDIR}'"
}

pkg_postinst() {
	ewarn "When upgrading from <= 0.9 the old configuration files named"
	ewarn "main.inc.php and db.inc.php are now deprecated and should be"
	ewarn "replaced with one single config.inc.php file."
	ewarn "Run the ./bin/update.sh script to get this conversion done"
	ewarn "or manually merge the files."
	ewarn "NOTE: the new config.inc.php should only contain options that"
	ewarn "differ from the ones listed in defaults.inc.php."
}
