# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

inherit webapp

MY_PN=${PN}mail
MY_P=${MY_PN}-${PV/_/-}

PHAR="1.4.2"

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="https://roundcube.net"
SRC_URI="https://github.com/${PN}/${MY_PN}/releases/download/${PV/_/-}/${MY_P}.tar.gz
	plugins? ( https://getcomposer.org/download/${PHAR}/composer.phar -> composer.phar_${PHAR} )"
RESTRICT="mirror"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86"

IUSE="enigma exif ldap managesieve +mysql php_targets_php7-0 plugins postgres sqlite ssl spell"
REQUIRED_USE="|| ( mysql postgres sqlite )"

# The function below sets only DEPEND, so we need to include the latter in RDEPEND ...
need_httpd_cgi

# :TODO: Support "endriod/qrcode: ~1.6.5" dep (ebuild needed)
RDEPEND="
	${DEPEND}
	>=dev-lang/php-5.4.0[crypt,exif?,fileinfo,filter,gd,iconv,intl,json,ldap?,mysql?,pdo,postgres?,session,sockets,sqlite?,ssl?,unicode,xml,zip]
	>=dev-php/PEAR-Auth_SASL-1.1.0
	>=dev-php/PEAR-Mail_Mime-1.10.0
	>=dev-php/PEAR-Mail_mimeDecode-1.5.5
	>=dev-php/PEAR-Net_IDNA2-0.2.0
	>=dev-php/PEAR-Net_SMTP-1.7.1
	>=dev-php/PEAR-Net_Socket-1.2.1
	virtual/httpd-php
	enigma? ( >=dev-php/PEAR-Crypt_GPG-1.6.0 app-crypt/gnupg )
	ldap? ( || ( >=dev-php/PEAR-Net_LDAP2-2.2.0 dev-php/PEAR-Net_LDAP3 ) )
	managesieve? ( >=dev-php/PEAR-Net_Sieve-1.4.0 )
	mysql? ( || ( dev-lang/php[mysql] dev-lang/php[mysqli] ) )
	php_targets_php7-0? ( >=dev-php/PEAR-PEAR-1.10.1 )
	plugins? ( dev-lang/php[ctype,filter,hash,json,phar,ssl] )
	spell? ( dev-lang/php[curl,spell] )
"

S=${WORKDIR}/${MY_P}

src_prepare() {
	cp config/config.inc.php{.sample,} || die
	cp composer.json{-dist,} || die

	rm robots.txt

	default
}

src_install() {
	webapp_src_preinst

	dodoc CHANGELOG INSTALL README.md UPGRADING

	insinto "${MY_HTDOCSDIR}"
	doins -r [[:lower:]]* SQL
	doins .htaccess
	exeinto "${MY_HTDOCSDIR}"
	use plugins && newexe "${DISTDIR}"/composer.phar_${PHAR} composer.phar

	webapp_serverowned "${MY_HTDOCSDIR}"/logs
	webapp_serverowned "${MY_HTDOCSDIR}"/temp

	webapp_configfile "${MY_HTDOCSDIR}"/config/config.inc.php
	webapp_configfile "${MY_HTDOCSDIR}"/config/defaults.inc.php
	webapp_configfile "${MY_HTDOCSDIR}"/composer.json

	#webapp_postupgrade_txt en "${FILESDIR}/POST-UPGRADE.txt"
	webapp_postupgrade_txt en "${FILESDIR}"/postupgrade-en-0.6.txt

	webapp_src_install

	if pushd "${ED}/${MY_HTDOCSDIR}/" >/dev/null 2>&1; then
	    set -o xtrace
		# This is bad... the required sources should be included in the ebuild
		# SRC_URI variable...
		chmod 0755 bin/install-jsdeps.sh || die "Setting permissions on 'install-jsdeps.sh' failed: ${?}"
		./bin/install-jsdeps.sh || die "JavaScript additional sources download failed: ${?}"
	    set +o xtrace
		popd >/dev/null 2>&1
	fi

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

	if has_version "<mail-client/roundcube-1.0.0"; then
		ewarn
		ewarn "When upgrading from <= 0.9, note that the old configuration files"
		ewarn "named main.inc.php and db.inc.php are deprecated and should be"
		ewarn "replaced with one single config.inc.php file."
		ewarn
		ewarn "Run the ./bin/update.sh script to convert those"
		ewarn "or manually merge the files."
		ewarn
		ewarn "The new config.inc.php should only contain options that"
		ewarn "differ from those listed in defaults.inc.php."
	fi
	# Action now performed by ebuild itself...
	#if has_version "<=mail-client/roundcube-1.2.5"; then
	#	ewarn
	#	ewarn "When installing for the first time or upgrading from <= 1.2.5,"
	#	ewarn "run the ./bin/install-jsdeps.sh script to download required"
	#	ewarn "javascript files into the ./temp/js_cache/ folder."
	#	ewarn
	#fi
}
# vi: set diffopt=iwhite,filler:
