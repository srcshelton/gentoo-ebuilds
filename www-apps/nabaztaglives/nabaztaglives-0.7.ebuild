# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils webapp

LANGUAGES="linguas_de linguas_en linguas_es linguas_fr linguas_it linguas_us"

COMMIT="74cd772d67aaad1accbb58382e16cfaaa5ac6d87"

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

src_prepare() {
	cd "${S}"

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

	#use linguas_en || { einfo "Removing audio files for EN/US language" ; rm -r www/vl/broad_us ; }
	for LNG in it es de us; do
		eval "use linguas_${LNG} || { einfo 'Removing audio files for ${LNG} language' ; rm -r www/vl/broad_${LNG} ; }"
	done

	mkdir www/images

	rm db/*.sh
	rm docs/installation.htm

	mv www/*.jpg www/images/
	mv db/rabbit_pi.sql db/initial.sql
}

src_install() {
	webapp_src_preinst

	use doc && dohtml -r docs/*

	einfo "Installation of large numbers of files can be slow - please wait ..."
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

	webapp_postinst_txt en "${FILESDIR}"/postinstall-en-0.6.txt

	webapp_src_install
}
