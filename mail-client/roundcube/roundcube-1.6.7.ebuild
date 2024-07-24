# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit webapp

MY_PN=${PN}mail
MY_PV=${PV/_/-}
MY_P=${MY_PN}-${MY_PV}

DESCRIPTION="A browser-based multilingual IMAP client with an application-like user interface"
HOMEPAGE="https://roundcube.net"

# roundcube is GPL-licensed, the rest of the licenses here are
# for bundled PEAR components, googiespell and utf8.class.php
LICENSE="GPL-3 BSD PHP-2.02 PHP-3 MIT public-domain"

IUSE="change-password enigma exif fileinfo ldap managesieve +mysql postgres spell sqlite ssl zip zxcvbn"
REQUIRED_USE="|| ( mysql postgres sqlite )"

# This function only sets DEPEND so we need to include that in RDEPEND
need_httpd_cgi

RDEPEND="
	${DEPEND}
	>=dev-lang/php-7.4.0[exif?,fileinfo?,filter,gd,iconv,intl,json(+),ldap?,mysql?,pdo,postgres?,session,sockets,sqlite?,ssl?,unicode,xml,zip?]
	virtual/httpd-php
	change-password? (
		dev-lang/php[sockets]
	)
	enigma? (
		app-crypt/gnupg
	)
	mysql? (
		|| (
			dev-lang/php[mysql]
			dev-lang/php[mysqli]
		)
	)
	spell? ( dev-lang/php[curl,spell] )
	zxcvbn? ( dev-php/ZxcvbnPhp )
"

if [[ ${PV} == *9999 ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/roundcube/roundcubemail"
	EGIT_BRANCH="master"
	BDEPEND="${BDEPEND}
		app-arch/unzip
		dev-php/composer
		net-misc/curl"
else
	SRC_URI="https://github.com/${PN}/${MY_PN}/releases/download/${MY_PV}/${MY_P}-complete.tar.gz"
	S="${WORKDIR}/${MY_P}"
	KEYWORDS="amd64 arm ~hppa ppc ppc64 sparc x86"
	RESTRICT="mirror"
fi

src_unpack() {
	if [[ "${PV}" == *9999* ]]; then
		git-r3_src_unpack
		pushd "${S}" > /dev/null || die
		rm Makefile || die
		mv composer.json-dist composer.json || die
		composer install --no-dev || die
		./bin/install-jsdeps.sh || die
		popd > /dev/null || die
	else
		default
	fi
}

src_prepare() {
	default

	cp config/config.inc.php{.sample,} || die
	rm vendor/bin/crypt-gpg-pinentry || die
}

src_install() {
	webapp_src_preinst

	dodoc CHANGELOG.md INSTALL README.md UPGRADING SECURITY.md

	insinto "${MY_HTDOCSDIR}"
	doins -r [[:lower:]]* SQL
	doins .htaccess

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
		elog "${EROOT}/usr/share/webapps/${PN}/${PV}/postupgrade-en.txt"
	fi
}

# vi: set diffopt=iwhite,filler:
