# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils webapp

LANGUAGES="l10n_de l10n_en l10n_es l10n_fr l10n_it l10n_ja l10n_us"

COMMIT="bed1196b9d387ddbaaabf64170e734fbb6815b91"

DESCRIPTION="Nabaztag/tag NabaztagLives! Server"
HOMEPAGE="http://nabaztaglives.com"
SRC_URI="http://sourceforge.net/code-snapshots/git/n/na/nabaztaglives/code.git/nabaztaglives-code-${COMMIT}.zip"
RESTRICT="nomirror"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"
IUSE="doc ${LANGUAGES}"

RDEPEND="
	virtual/httpd-php
	dev-lang/php
	media-sound/lame
	media-sound/mp3wrap
"

need_httpd_cgi

S="${WORKDIR}/nabaztaglives-code-${COMMIT}"

pkg_nofetch() {
	einfo "If the source for this ebuild fails to download, please access the following URL:"
	einfo
	einfo "  https://sourceforge.net/p/nabaztaglives/code/ci/${COMMIT}/tree/"
	einfo
	einfo "... and select 'Download Snapshot' in order to regenerate the cached archive."
	einfo
	einfo "This is (one of the many reasons) why everyone is using github instead..."
}

src_prepare() {
	cd "${S}"

	if use l10n_ja; then
		epatch "${FILESDIR}"/"${PN}"-2.1-lang-ja.patch
	fi

	sed -si \
		-e 's|<? |<?php |g' \
		www/*.php \
	|| die "PHP patching failed: ${?}"

	sed -si \
		-e "s|'../etc/nabaztag_error.log'|'logs/error.log'|" \
		www/*.php www/subroutines/logError.php \
	|| die "Log-location patching failed: ${?}"
	sed -si \
		-e 's|../etc/nabaztag_error.log|logs/error.log|' \
		www/vl/p4.php www/vl/FR/p3.jsp \
	|| die "Log-location patching failed: ${?}"

	sed -si \
		-e "s|../etc/api_calls.log|logs/apicalls.log|" \
		www/*.php \
	|| die "API log-location patching failed: ${?}"

	sed -si \
		-e 's|../etc/nabaztag_db.php|config/db.php|' \
		www/*.php www/subroutines/*.php www/vl/p4.php www/vl/FR/p3.jsp \
	|| die "Configuration patching failed: ${?}"

	sed -rsi \
		-e 's|<img src="?([^"> ]+).jpg"?|<img src="images/\1.jpg"|g' \
		www/*.php www/*.htm \
	|| die "Image patching failed: ${?}"
	sed -rsi \
		-e 's|<a href="?([^"> ]+).jpg"?|<a href="images/\1.jpg"|g' \
		www/*.php \
	|| die "Image patching failed: ${?}"

	sed -rsi \
		-e 's|url\(([^)]+).jpg\)|url(images/\1.jpg)|g' \
		www/main.css \
	|| die "CSS Image patching failed: ${?}"

	sed -si \
		-e "/'pi'/d" \
		db/rabbit_pi.sql \
	|| die "MySQL script patching failed: ${?}"

	#use l10n_en || { einfo "Removing audio files for EN/US language" ; rm -r www/vl/broad_us ; }
	for LNG in it es de us; do
		eval "use l10n_${LNG} || { einfo 'Removing audio files for ${LNG} language' ; rm -r www/vl/broad_${LNG} ; }"
	done

	mkdir www/images

	rm db/*.sh
	rm docs/installation.htm

	mv www/*.jpg www/images/
	mv db/rabbit_pi.sql db/initial.sql

	epatch "${FILESDIR}/${PN}-2.1.2-api.patch" || die "Patch failed"
	epatch "${FILESDIR}/${PN}-2.00.patch" || die "Patch failed"
}

src_install() {
	webapp_src_preinst

	use doc && dohtml -r docs/*

	ewarn "Installation of large numbers of files can be slow - please wait ..."
	insinto "${MY_HTDOCSDIR}"
	doins -r www/*
	dodir "${MY_HTDOCSDIR}"/db
	dodir "${MY_HTDOCSDIR}"/config
	dodir "${MY_HTDOCSDIR}"/logs
	insinto "${MY_HTDOCSDIR}"/db
	doins -r db/*
	insinto "${MY_HTDOCSDIR}"/config
	newins etc/nabaztag_db.php db.php
	insinto "${MY_HTDOCSDIR}"/logs
	newins etc/nabaztag_error.log error.log

	webapp_serverowned "${MY_HTDOCSDIR}"/vl/hutch
	webapp_serverowned "${MY_HTDOCSDIR}"/logs/error.log
	webapp_configfile  "${MY_HTDOCSDIR}"/config/db.php
	webapp_configfile  "${MY_HTDOCSDIR}"/locate.jsp

	webapp_postinst_txt en "${FILESDIR}"/postinstall-en-2.00.txt

	webapp_src_install
}

pkg_postinst() {
	elog "As of 12th December 2016:"
	elog
	elog "It seems that Acapella has caught on to us and they've told us that they"
	elog "don't like rabbits,  especially ones that speak, so I'm currently testing"
	elog "out a new TTS engine. In the meantime, you may want to disable your TTS feed on"
	elog "your rabbit setup page."
}
