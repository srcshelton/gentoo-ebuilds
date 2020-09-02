# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit webapp

MY_PN=${PN}mail
MY_PV=${PV/_/-}
MY_P=${MY_PN}-${MY_PV}

PHAR="1.10.10"

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="https://roundcube.net"
SRC_URI="https://github.com/${PN}/${MY_PN}/releases/download/${MY_PV}/${MY_P}-complete.tar.gz
	plugins? ( https://getcomposer.org/download/${PHAR}/composer.phar -> composer.phar_${PHAR} )"
RESTRICT="mirror"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"
KEYWORDS="amd64 arm ~hppa ppc ppc64 sparc x86"

IUSE="change-password enigma exif ldap managesieve +mysql plugins postgres sqlite ssl spell zxcvbn"
REQUIRED_USE="|| ( mysql postgres sqlite )"

RDEPEND="
	|| ( virtual/httpd-cgi virtual/httpd-fastcgi )
	>=dev-lang/php-5.4.0[exif?,fileinfo,filter,gd,iconv,intl,json,ldap?,mysql?,pdo,postgres?,session,sockets,sqlite?,ssl?,unicode,xml,zip]
	>=dev-php/Endroid-QrCode-1.6.5
	>=dev-php/Masterminds-HTML5-2.5.0
	>=dev-php/PEAR-Auth_SASL-1.1.0
	>=dev-php/PEAR-Mail_Mime-1.10.0
	>=dev-php/PEAR-Mail_mimeDecode-1.5.5
	>=dev-php/PEAR-Net_IDNA2-0.2.0
	>=dev-php/PEAR-Net_SMTP-1.8.1
	>=dev-php/PEAR-PEAR-1.10.1
	virtual/httpd-php
	change-password? (
		>=dev-php/PEAR-Net_Socket-1.2.1
		dev-lang/php[sockets]
	)
	enigma? (
		>=dev-php/PEAR-Crypt_GPG-1.6.3
		app-crypt/gnupg
	)
	ldap? (
		|| (
			>=dev-php/PEAR-Net_LDAP2-2.2.0
			>=dev-php/PEAR-Net_LDAP3-1.1.1
		)
	)
	managesieve? ( >=dev-php/PEAR-Net_Sieve-1.4.3 )
	mysql? (
		|| (
			dev-lang/php[mysql]
			dev-lang/php[mysqli]
		)
	)
	plugins? ( dev-lang/php[ctype,filter,hash,json,phar,ssl] )
	spell? ( dev-lang/php[curl,spell] )
	zxcvbn? ( >=dev-php/ZxcvbnPhp-4.4.2 )
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	cp config/config.inc.php{.sample,} || die
	cp composer.json{-dist,} || die

	default

	rm -r vendor/pear || die

	rm vendor/bin/crypt-gpg-pinentry || die
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

	webapp_postupgrade_txt en "${FILESDIR}/POST-UPGRADE_complete.txt"

	webapp_src_install

	# fperms must occur after webapp_src_install is called...
	#fperms 0755 "${MY_HTDOCSDIR}"/bin/*.sh || die "Cannot set file permissions in '${ED}/${MY_HTDOCSDIR}'"
	local file name
	find "${ED}/${MY_HTDOCSDIR}/bin/" -type f -name \*.sh | while read -r file; do
		name="$( basename "${file}" )"
		fperms 0755 "${MY_HTDOCSDIR%/}/bin/${name}" || die "Cannot set file permissions on '${name}' in '${ED%/}/${MY_HTDOCSDIR%/}/bin/'"
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
