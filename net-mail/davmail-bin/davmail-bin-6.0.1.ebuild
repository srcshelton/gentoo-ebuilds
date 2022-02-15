# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eapi7-ver user

DESCRIPTION="DavMail POP/IMAP/SMTP/Caldav/Carddav/LDAP Exchange Gateway"
HOMEPAGE="http://davmail.sourceforge.net/"
REV=3390
MY_PN="${PN/-bin}"
MY_P="${MY_PN}-${PV}"
SRC_URI="mirror://sourceforge/${MY_PN}/${MY_P}-${REV}.zip
	doc? ( mirror://sourceforge/${MY_PN}/${MY_PN}-srconly-${PV}-${REV}.tgz )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE="doc"

DEPEND=""
RDEPEND=">=virtual/jre-1.6"

S="${WORKDIR}"

pkg_setup() {
	enewgroup davmail || die "DavMail Group creation failed"
	enewuser davmail -1 -1 "/opt/${MY_P}" davmail || die "DavMail User creation failed"
}

src_install () {
	echo "CONFIG_PROTECT=\"${EPREFIX}/opt/${MY_P}/conf\"" > "${T}/90${MY_PN}"

	newinitd "${FILESDIR}/davmail-3.9.8-initd" davmail || \
		die "Could not create init script"
	newconfd "${FILESDIR}/davmail.confd" davmail || \
		die "Could not create conf file"
	sed -i "s|%INST_DIR%|/opt/${MY_P}|g" "${ED}"/etc/{init,conf}.d/davmail || \
		die "Could not customise init script"

	exeinto /opt/"${MY_P}"/bin
	doexe davmail.jar || die "Could not install Jar"
	fperms 644 /opt/"${MY_P}"/bin/davmail.jar

	insinto /opt/"${MY_P}"
	doins -r lib || die "Could not copy libraries"
	insinto /opt/"${MY_P}"/conf
	newins "${FILESDIR}/davmail.properties-$(ver_cut 1-2)" davmail.properties || die "Could not copy properties"

	dodir /var/log/davmail || die "Could not create log directory"
	fowners davmail:davmail /var/log/davmail || die "Could not change ownership of log directory"

	fowners davmail:davmail /opt/"${MY_P}" || die "Could not change ownership of DavMail directory"

	doenvd "${T}/90${MY_PN}" || die "Could not configure environment"

	use doc && dodoc "davmail-${PV}-${REV}/releasenotes.txt"
}

pkg_postinst() {
	einfo "davmail.properties has been installed to '/opt/${MY_P}/conf'"
	einfo "Please see http://davmail.sourceforge.net/gettingstarted.html for details"
	einfo "of how to configure DavMail"
}
