# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit webapp

MY_PN=${PN}mail
MY_P=${MY_PN}-${PV}

PHAR="1.8.4"

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="https://roundcube.net"
SRC_URI="https://github.com/${PN}/${MY_PN}/releases/download/${PV}/${MY_P}-complete.tar.gz
	plugins? ( https://getcomposer.org/download/${PHAR}/composer.phar -> composer.phar_${PHAR} )"
RESTRICT="mirror"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"
KEYWORDS="amd64 arm ~hppa ppc ppc64 sparc x86"

IUSE="change-password enigma exif ldap managesieve +mysql plugins postgres sqlite ssl spell php_targets_php7-1 php_targets_php7-2"
REQUIRED_USE="|| ( mysql postgres sqlite )"

# The function below sets only DEPEND, so we need to include the latter in RDEPEND ...
need_httpd_cgi

# :TODO: Support "endriod/qrcode: ~1.6.5" dep (ebuild needed)
RDEPEND="
	${DEPEND}
	>=dev-lang/php-5.4.0[exif?,fileinfo,filter,gd,iconv,intl,json,ldap?,mysql?,pdo,postgres?,session,sockets,sqlite?,ssl?,unicode,xml,zip]
	>=dev-php/PEAR-Auth_SASL-1.1.0
	>=dev-php/PEAR-Mail_Mime-1.10.0
	>=dev-php/PEAR-Mail_mimeDecode-1.5.5
	>=dev-php/PEAR-Net_IDNA2-0.2.0
	>=dev-php/PEAR-Net_SMTP-1.7.1
	virtual/httpd-php
	change-password? (
		>=dev-php/PEAR-Net_Socket-1.2.1
		dev-lang/php[sockets]
	)
	enigma? (
		>=dev-php/PEAR-Crypt_GPG-1.6.0
		app-crypt/gnupg
	)
	ldap? (
		|| (
			>=dev-php/PEAR-Net_LDAP2-2.2.0
			dev-php/PEAR-Net_LDAP3
		)
	)
	managesieve? ( >=dev-php/PEAR-Net_Sieve-1.4.0 )
	mysql? (
		|| (
			dev-lang/php[mysql]
			dev-lang/php[mysqli]
		)
	)
	php_targets_php7-1? ( >=dev-php/PEAR-PEAR-1.10.1 )
	php_targets_php7-2? ( >=dev-php/PEAR-PEAR-1.10.1 )
	plugins? ( dev-lang/php[ctype,filter,hash,json,phar,ssl] )
	spell? ( dev-lang/php[curl,spell] )
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	cp config/config.inc.php{.sample,} || die
	cp composer.json{-dist,} || die

	default

	# Redundant. (Bug #644896)
	rm -r vendor/pear || die

	rm vendor/bin/crypt-gpg-pinentry || die

	# Remove references to PEAR. (Bug #650910)
	cp "${FILESDIR}"/roundcube-1.3.7-pear-removed-installed.json \
		vendor/composer/installed.json \
		|| die
}

src_unpack() {
	local file

	for file in ${A}; do
		if [[ "${file}" == *.tar* ]]; then
			unpack "${file}"
		fi
	done
}

src_install() {
	webapp_src_preinst

	dodoc CHANGELOG INSTALL README.md UPGRADING

	insinto "${MY_HTDOCSDIR}"
	doins -r [[:lower:]]* SQL
	doins .htaccess
	exeinto "${MY_HTDOCSDIR}"/bin
	use plugins && newexe "${DISTDIR}"/composer.phar_${PHAR} composer.phar

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

	if [[ -n "${REPLACING_VERSIONS}" ]]; then
		elog "You can review the post-upgrade instructions at:"
		elog "${EROOT%/}/usr/share/webapps/${PN}/${PV}/postupgrade-en.txt"
	fi

	if use plugins; then
		elog "If you have installed PHP components with 'composer', then"
		elog "please run the command:"
		elog
		elog "    php composer.phar update --no-dev"
		elog
		elog "... to update these modules."
	fi
}
# vi: set diffopt=iwhite,filler:
