# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-analyzer/nessus-bin/nessus-bin-5.0.1.ebuild,v 1.1 2012/10/06 17:35:27 pinkbyte Exp $

EAPI="5"

inherit multilib rpm

MY_P="Nessus-${PV}-es6"
# We are using the Red Hat/CentOS binary

DESCRIPTION="A remote security scanner for Linux"
HOMEPAGE="http://www.nessus.org/"
SRC_URI="
	x86? ( ${MY_P}.i386.rpm )
	amd64? ( ${MY_P}.x86_64.rpm )"

RESTRICT="mirror fetch strip"

LICENSE="GPL-2 Nessus-EULA"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"

S="${WORKDIR}"/opt

pkg_nofetch() {
		einfo "Please download ${A} from ${HOMEPAGE%/}/download"
		einfo "The archive should then be placed into ${DISTDIR}."
}

src_install() {
	dodir /opt
	cp -pPR "${WORKDIR}"/opt/nessus "${ED}"/opt/

	# make sure these directories do not vanish
	# nessus will not run properly without them
	keepdir /opt/nessus/etc/nessus
	keepdir /opt/nessus/var/nessus/logs
	keepdir /opt/nessus/var/nessus/tmp
	keepdir /opt/nessus/var/nessus/users

	# add PATH and MANPATH for convenience
	doenvd "${FILESDIR}"/90nessus-bin

	# init script
	newinitd "${FILESDIR}"/nessusd-initd-r1 nessusd-bin
}

pkg_postinst() {
	elog "You can get started by starting the 'nessud-bin' service and then running the"
	elog "following commands:"
	elog
	elog "/opt/nessus/sbin/nessuscli adduser <username>"
	elog "/opt/nessus/sbin/nessuscli mkcert"
	elog "/opt/nessus/sbin/nessuscli fetch --register <your registration code>"
	elog
	elog "If you had a previous version of Nessus installed, use"
	elog "the following command to update the plugin database:"
	elog "/opt/nessus/sbin/nessusd -R"
	elog
	elog "For more information about nessus, please visit"
	elog "${HOMEPAGE}/documentation/"
}
