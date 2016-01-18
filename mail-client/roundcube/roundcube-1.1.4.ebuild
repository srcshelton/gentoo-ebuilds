# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: a314e23de0eb0d1ec8e75f043b4c861e3f4fdfbe $

EAPI=5

inherit webapp

MY_PN=${PN}mail
MY_P=${MY_PN}-${PV/_/-}

PHAR="1.0.0-alpha11"

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="http://roundcube.net"
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}.tar.gz
	plugins? ( https://getcomposer.org/download/${PHAR}/composer.phar -> composer.phar_${PHAR} )"
RESTRICT="mirror"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"
KEYWORDS="~amd64 arm ~hppa ppc ~ppc64 ~sparc ~x86"

IUSE="enigma ldap managesieve +mysql plugins postgres sqlite ssl spell"
REQUIRED_USE="|| ( mysql postgres sqlite )"

# The function below sets only DEPEND, so we need to include the latter in RDEPEND ...
need_httpd_cgi

RDEPEND="
	${DEPEND}
	>=dev-lang/php-5.3.7[crypt,filter,gd,iconv,json,ldap?,pdo,postgres?,session,sockets,sqlite?,ssl?,unicode,xml]
	>=dev-php/PEAR-Auth_SASL-1.0.6
	>=dev-php/PEAR-Mail_Mime-1.8.9
	>=dev-php/PEAR-Mail_mimeDecode-1.5.5
	>=dev-php/PEAR-Net_IDNA2-0.1.1
	>=dev-php/PEAR-Net_SMTP-1.6.2
	>=dev-php/PEAR-Net_Socket-1.0.14
	virtual/httpd-php
	enigma? ( >=dev-php/PEAR-Crypt_GPG-1.3.2 app-crypt/gnupg )
	ldap? ( >=dev-php/PEAR-Net_LDAP2-2.0.12 )
	managesieve? ( >=dev-php/PEAR-Net_Sieve-1.3.2 )
	mysql? ( || ( dev-lang/php[mysql] dev-lang/php[mysqli] ) )
	plugins? ( dev-lang/php[ctype,filter,hash,json,phar,ssl] )
	spell? ( dev-lang/php[curl,spell] )
"

S=${WORKDIR}/${MY_P}

src_prepare() {
	cp config/config.inc.php{.sample,} || die
	cp composer.json{-dist,} || die

	rm robots.txt
}

src_install() {
	webapp_src_preinst

	dodoc CHANGELOG INSTALL README.md UPGRADING

	insinto "${MY_HTDOCSDIR}"
	doins -r [[:lower:]]* SQL
	doins .htaccess
	use plugins && newins "${DISTDIR}"/composer.phar_${PHAR} composer.phar

	webapp_serverowned "${MY_HTDOCSDIR}"/logs
	webapp_serverowned "${MY_HTDOCSDIR}"/temp

	webapp_configfile "${MY_HTDOCSDIR}"/config/config.inc.php
	webapp_configfile "${MY_HTDOCSDIR}"/config/defaults.inc.php
	webapp_configfile "${MY_HTDOCSDIR}"/composer.json

	#webapp_postupgrade_txt en "${FILESDIR}/POST-UPGRADE.txt"
	webapp_postupgrade_txt en "${FILESDIR}"/postupgrade-en-0.6.txt

	webapp_src_install

	# fperms must occur after webapp_src_install is called...
	#fperms 0755 "${MY_HTDOCSDIR}"/bin/*.sh || die "Cannot set file permissions in '${ED}/${MY_HTDOCSDIR}'"
	local FILE filename
	find "${ED}"/"${MY_HTDOCSDIR}"/bin/ -type f -name \*.sh | while read -r FILE; do
		filename="$( basename "${FILE}" )"
		fperms 0755 "${MY_HTDOCSDIR}"/bin/"${filename}" || die "Cannot set file permissions in '${ED}/${MY_HTDOCSDIR}/bin/'"
	done
}

pkg_postinst() {
	webapp_pkg_postinst

	ewarn
	ewarn "When upgrading from <= 0.9, note that the old configuration files"
	ewarn "named main.inc.php and db.inc.php are deprecated and should be"
	ewarn "replaced with one single config.inc.php file."
	ewarn
	ewarn "Run the ./bin/update.sh script to convert those"
	ewarn "or manually merge the files."
	ewarn
	ewarn "The new config.inc.php should only contain options that"
	ewarn "differ from the ones listed in defaults.inc.php."
	ewarn
}
